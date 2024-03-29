%% Documentation
% This is the outshell code for calling all functions to process grayscale
% AVI files containing pupil imaging. 
%   Processes AVI file of pupil, fitting circles around pupil ROI,
%   generating artifact corrected frame by frame measurements of pupil area 

%% Setup 
% User inputs information about the current dataset

disp('Select the folder where unprocessed pupil movies are saved...');
rawDataFolder = uigetdir;
disp('Selected!')
disp('Select the folder where tseries are saved...')
tseriesBaseFolder = uigetdir;
disp('Selected!')
disp('Select the folder where you would like to save the output...')
saveBaseFolder = uigetdir;
disp('Selected!')

cd(rawDataFolder)
d=dir('*.avi');

sampling_rate = VideoReader(d(1).name).FrameRate;

    
blocks = 1:size(d,1); %each movie within a imaging session date is considered a separate block 

%% Establish eye ROI and corneal reflections

[eyeMask,cornMask,additional_cornMask,the_example_image]=processing.maskEyeAndCornRef(d);


%% Establish processing parameters 

 [selectedThreshold,selectedBlink,selectedScope,selectedOrient,selectedUnit,...
    selectedConversion,selectedAlign,selectedFace,selectedKmeans,selectedDilCon]...
    =processing.createSettingsGUI(the_example_image,cornMask,eyeMask,additional_cornMask);

 %% Establish Face ROI 
 if selectedFace
     [faceMask] =  processing.drawFaceROI(the_example_image);
     faceMatrix = [];
 end
%% Loop through all blocks
% For each block this will read out each frame, identify pupil ROI, get
% area meaurment for circle made, remove blinks and other artifacts from
% trace, save individual files for each block and a structure containing
% variables pertaining to each block 

for block =blocks
    obj=VideoReader(d(block).name); 
    NumberOfFrames = obj.NumberOfFrames;

    
    %Initailize variables 
    the_areas = [];
    raw_radii = [];
    center_row = [];
    center_column = [];
    

    %Converts each frame to BW matrix based on threshold
    for cnt = 1:NumberOfFrames  
        the_image = read(obj,cnt);
        
        if selectedFace
            faceMatrix = [faceMatrix the_image(faceMask)]; %nPix in faceROI x nFrames
        end


        %compute the pupil 
        x=processing.createBWMatrix(the_image,selectedThreshold,eyeMask,cornMask,additional_cornMask);

        x=processing.getROIcoordinates(selectedOrient,x,center_row,center_column,cnt);    
        try
            [z, r, residual] = processing.fitcircle_mcc(x,'linear');
        catch ME
            z = [];
            r = [];
        end
        %how to handle blank frames
        if isempty(r)
            radius = 0;
            center = zeros(2,1);
        else
            %[val,idx] = min(abs(raw_radii(cnt-1)-r));
            radius = r;
            z([1 2]) = z([2 1]);
            center = z;
        end
        
        figure(1);clf;
        imshow(the_image)
        viscircles(z',r)
        pause(.001)
        
        raw_radii = [raw_radii radius];
        center_row = [center_row center(2,1)];
        center_column = [center_column center(1,1)];
    end
    
    % manipulations on the raw trace of current block - chopping to laser
    [the_radii_cut,center_row_cut,center_column_cut,first_index,last_index]=alignment.chop_to_laser(raw_radii,obj,center_row,center_column);
    
    

       %Adjust conversion factor according to camera and settings: 
    %Camera on 2P investigator:
        %1024 x 1280 pix res --> conversion factor = 0.00469426267
        %512 x 640 pix res --> conversion factor = 0.00949848
    %Camera on 2P+:
        %1024 x 1280 pix res --> conversion factor = 0.01147684
        %512 x 640 pix res --> conversion factor = 0.02324933
    if strcmp('mm^2', selectedUnit) 
        
        the_radii = the_radii_cut.*selectedConversion; 
    else
        the_radii= the_radii_cut;
    end
    the_areas = (the_radii.^2).*pi;
    the_areas_compare = (the_radii.^2).*pi;
    
    
    %eliminating blinks
    [blinks_data_positions,blink_inds,corrected_areas] = processing.noise_blinks_v3(the_areas,sampling_rate,selectedBlink);


    figure(1)
    clf
    plot(corrected_areas)
    hold on
    plot(the_areas_compare)
    pause;


    pupil.center_position.center_column = center_column_cut;
    pupil.center_position.center_row = center_row_cut;
    pupil.area.corrected_areas=corrected_areas;
    pupil.area.uncorrected_areas = the_areas_compare;
    pupil.radii.uncut_uncorrected_radii =  raw_radii;
    pupil.radii.cut_uncorrected_radii = the_radii;
    pupil.blink = blink_inds;
    pupil.galvo_on = first_index; 
    pupil.galvo_off = last_index;

    if block<10
        save(strcat('file_000',num2str(block),'.mat'),'pupil');
    else
        save(strcat('file_00',num2str(block),'.mat'),'pupil');
    end
    
    pupil_struct{block} = pupil;    

end
% 
% motionEnergy = abs(diff(faceMatrix,1,2));
% 
% U=[];
% S=[];
% V=[];
% for bin = 1:500:size(faceMatrix,2)
%    if bin+499<size(faceMatrix,2)
%        %compute the SVD
%         [U_b,S_b,V_b]=svd(double(faceMatrix(:,bin:bin+499)),'econ');
%         U=cat(2,U,U_b); S =cat(2,S,S_b); V = cat(2,V,V_b);
% 
%    else 
%        [U,S,V]=svd(double(faceMatrix(:,bin:size(faceMatrix,2))),'econ');
%        U=cat(2,U,U_b); S =cat(2,S,S_b); V = cat(2,V,V_b);
%    end
% 
% end


save('pupil_struct','pupil_struct');

keep  blocks selectedAlign selectedKmeans selectedDilCon rawDataFolder acqFolder saveBaseFolder pupil_struct tseriesBaseFolder eyeMask cornMask additional_conMask ;

%% Aligning pupil trace concatenated across blocks to imaging data 
if strcmp('tough',selectedAlign)
    [aligned_pupil_unsmoothed,aligned_pupil_smoothed10,aligned_pupil_smoothed30,...
        aligned_y_position,aligned_x_position,blockTransitions,pup_norm_unsmoothed,...
        pup_norm_10,pup_norm_30]=alignment.make_pupil_aligned_tight(acqFolder,blocks,pupil_struct);
else
    [aligned_pupil_unsmoothed,aligned_pupil_smoothed10,aligned_pupil_smoothed30,...
        aligned_pupil_smoothed70,aligned_pupil_smoothed100,...
        aligned_y_position,aligned_x_position,blockTransitions,pup_norm_unsmoothed,...
        pup_norm_10,pup_norm_30,pup_norm_70,pup_norm_100]=alignment.make_pupil_aligned_rough(pupil_struct,tseriesBaseFolder);
end
%cd(saveBaseFolder)
mkdir([saveBaseFolder mouse '\' num2str(date)]);
save(strcat(saveBaseFolder,mouse,'\',num2str(date),'\',num2str(date),'_proc.mat'),...
    'aligned_pupil_unsmoothed','aligned_pupil_smoothed10','aligned_pupil_smoothed30',...
    'aligned_pupil_smoothed70','aligned_pupil_smoothed100','pup_norm_30','pup_norm_10',...
    'pup_norm_unsmoothed','pup_norm_70','pup_norm_100','aligned_x_position',...
    'aligned_y_position','blockTransitions');

%% Optional K-means analysis
% Use whichever pupil variable you prefer for you data, however it should
% be normalized (pup_norm_unsmoothed, pup_norm_10, or pup_norm_30)
if selectedKmeans
    [clusterlow,clusterhigh,transitionSmall,transitionLarge,classificationSmallTrans,...
        classificationLargeTrans,classificationNoTrans,C]=analysis.kmeans_pupil_v3(pup_norm_unsmoothed);
    save(strcat(saveBaseFolder,mouse,'\',num2str(date),'\',num2str(date),'_proc.mat'),'clusterlow','clusterhigh',...
        'transitionSmall','transitionLarge','classificationSmallTrans','classificationLargeTrans','classificationNoTrans','C','-append');
end

%% Optional dilation-contriction analysis 
% Use whatever pupil variable you prefer for your data, can be normalized
% or not
if selectedDilCon
    [Cpts,Dpts,dEvents,dDuration,dMagnitude,cEvents,cDuration,cMagnitude,AVG_cDuration,AVG_dDuration,AVG_dMagnitude,...
        AVG_cMagnitude,new_Cpts,new_Dpts,ff]=analysis.dil_con_events_no_constraints_v2(pup_norm_unsmoothed,blockTransitions); 
    save(strcat(saveBaseFolder,mouse,'\',num2str(date),'\', num2str(date),'_proc.mat'),'Cpts','Dpts','dEvents','dDuration',....
        'dMagnitude','cEvents','cDuration','cMagnitude','AVG_cDuration','AVG_dDuration','AVG_dMagnitude',...
        'AVG_cMagnitude','new_Cpts','new_Dpts','ff','-append');
% Optional dilation - constrcition event detection (Noelle preferred criteria)
    [dilation_starts_final]=analysis.dil_con_events_no_constraints_v3(pup_norm_70,blockTransitions);
     save(strcat(saveBaseFolder,mouse,'\',num2str(date),'\', num2str(date),'_proc.mat'),'dilation_start_final');

end
