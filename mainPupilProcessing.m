%% Documentation
% This is the outshell code for calling all functions to process grayscale
% AVI files containing pupil imaging. 
%   Processes AVI file of pupil, fitting circles around pupil ROI,
%   generting artifact corrected frame by frame measurements of pupil area in
%   mm^2 

%% Setup 
% User inputs information about the current dataset
mouse = input('Whats the mouse ID? Please input as string');
date = input('Date?');
sampling_rate_in_hz=input('What is the frame rate of the camera?');
threshold = input('Threshold?'); 
orientation = input('What is the orientation of the camera? 0(normal)/90(rotated)');
rig = input('What rig did you collect data using? inv/2p+');
unit = input('mm^2 or pix^2? Input m/p as string');
align = input('Rough or tight alignment? Input r/t as string');
km = input('Complete kmeans clustering analysis? Input y/n as string');
dilcon= input('Complete dilation/constriction event identificaton? Input y/n as string');

% Threshold is the level used to generate BW pixel image
%   Pixels with luminence > threshold are set to 1(white)
%   Pixels with luminance<threhsold are set to 0(black)
% Effectively, this translates to:
%   High threshold --> fewer pixels get contained in pupil ROI
%   Low thresold --> more pixels get contained in pupil ROI
%
% NOTE: Threshold value will need to be tested before runnning code in its
% entirely so that only those pixels representative of pupil are labeled appropriately labels all
% pixels of pupil 1 and nothing pixls outside of pupil 0 before running rest
% of code, may need to be changed across datasets if you notice differences
% in lightblocking,camera angle, focus, etc.

rawDataFolder =strcat('\\runyan-fs-01\Runyan3\Noelle\Pupil\Noelle Pupil\',mouse,'\',num2str(date),'\bad_proc\reproc\'); 
%acqFolder=strcat('\\runyan-fs-01\Runyan3\Noelle\wavesurfer\LC\',mouse,'_',num2str(date),'\burst'); %only need if doing tight alingment
tseriesBaseFolder=strcat('\\runyan-fs-01\Runyan3\Noelle\2P\2P LC\',mouse,'_',num2str(date),'\');
saveBaseFolder ='\\runyan-fs-01\Runyan3\Noelle\Pupil\Noelle Pupil\processed\'; %this is where final aligned files will be saved, not processed files for individual blocks, those will be saved in the base folder by default

cd(rawDataFolder);

d=dir('*.avi');
    
blocks = 1:size(d,1); %each movie within a imaging session date is considered a separate block 

%% Establish eye ROI and corneal reflections

exp_obj = VideoReader(d(1).name);
the_example_image = read(exp_obj,round((exp_obj.NumberOfFrames)/2));
rows = size(the_example_image,1);
columns = size(the_example_image,2);

figure()
imshow(the_example_image)
title('Draw Eye ROI')
hold on 
eye = drawellipse;
pause;
eyeMask = poly2mask(eye.Vertices(:,1), eye.Vertices(:,2) , rows, columns);

title('Draw Corneal Reflection')
cornealReflection_0 = drawellipse('Color','r');
pause
cornMask = poly2mask(cornealReflection_0.Vertices(:,1), cornealReflection_0.Vertices(:,2) , rows, columns);
moreCR = input('Would you like to input another corneal reflection? 0/1 \n');
num = 0;
additional_cornMask =[];
while moreCR ==1
    num=num+1;
   additional_cornealReflection = drawellipse('Color','r');
   pause
   additional_cornMask{num} = poly2mask(additional_cornealReflection.Vertices(:,1), additional_cornealReflection.Vertices(:,2) , rows, columns);
   moreCR = input('Would you like to input another corneal reflection? 0/1 \n');
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
        if size(the_image,3)==3
            the_image = rgb2gray(the_image);
        end
        piel = im2bw(the_image,threshold); 
        piel = bwmorph(piel,'open');
        piel = bwareaopen(piel,200);
        piel = imfill(piel,'holes');
        
     % Tagged objects in BW image
        L = bwlabel(piel);
        L(~eyeMask)=0;
        L(cornMask)=0;
        if ~isempty(additional_cornMask)
            for corn=1:length(additional_cornMask)
                L(additional_cornMask{corn})=0;
            end
        end


        BW1 = edge(L,'Canny'); 
        [row,column] = find(BW1);
        x = vertcat(row',column'); %x is the input indices used to fit the circle

    
        x=processing.getROIcoordinates(orientation,x,center_row,center_column,cnt);    
        
      
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
      
      figure(1)
      clf;
      imshow(the_image)
      viscircles(z',r)
      pause(.001)
      
      raw_radii = [raw_radii radius];
      area = (radius^2)*pi;
      the_areas = [the_areas area];
      center_row = [center_row center(2,1)];
      center_column = [center_column center(1,1)];
    end
    
    % manipulations on the raw trace of current block - chopping to laser
    [the_radii_cut,center_row_cut,center_column_cut]=alignment.chop_to_laser(raw_radii);
    
    

       %Adjust conversion factor according to camera and settings: 
    %Camera on 2P investigator:
        %1024 x 1280 pix res --> conversion factor = 0.00469426267
        %512 x 640 pix res --> conversion factor = 0.00949848
    %Camera on 2P+:
        %1024 x 1280 pix res --> conversion factor = 0.01147684
        %512 x 640 pix res --> conversion factor = 0.02324933
    if strcmp('m', unit) 
        if strcmp('inv',rig)
            the_radii = the_radii_cut.*0.00469426267; 
        else
            the_radii= the_radii_cut.*0.01147684;
        end
        the_areas = (the_radii.^2).*pi;
        the_areas_compare = (the_radii.^2).*pi;
        blink_threshold = .1;
    else
        the_radii= the_radii_cut;
        the_areas = (the_radii.^2).*pi;
        the_areas_compare = (the_radii.^2).*pi;
        blink_threshold = 1000;
    end
    
    %eliminating blinks
    blinks_data_positions = processing.noise_blinks_v3(the_areas,sampling_rate_in_hz,blink_threshold);


    figure(1)
    clf
    plot(corrected_areas)
    hold on
    plot(the_areas_compare)
    pause;


    the_areas_compare = (the_radii.^2).*pi;
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
        save(strcat(mouse,'_000',num2str(block),'.mat'),'pupil');
    else
        save(strcat(mouse,'_00',num2str(block),'.mat'),'pupil');
    end
    
    pupil_struct{block} = pupil;    

end
save('pupil_struct','pupil_struct');

keep mouse blocks date align km dilcon rawDataFolder acqFolder saveBaseFolder pupil_struct tseriesBaseFolder eyeMask cornMask additional_conMask ;

%% Aligning pupil trace concatenated across blocks to imaging data 
if strcmp('t',align)
    [aligned_pupil_unsmoothed,aligned_pupil_smoothed10,aligned_pupil_smoothed30,...
        aligned_y_position,aligned_x_position,blockTransitions,pup_norm_unsmoothed,...
        pup_norm_10,pup_norm_30]=alignment.make_pupil_aligned_tight(acqFolder,blocks,pupil_struct);
else
    [aligned_pupil_unsmoothed,aligned_pupil_smoothed10,aligned_pupil_smoothed30,...
        aligned_y_position,aligned_x_position,blockTransitions,pup_norm_unsmoothed,...
        pup_norm_10,pup_norm_30]=alignment.make_pupil_aligned_rough(pupil_struct,tseriesBaseFolder);
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
if strcmp('y',km)
    [clusterlow,clusterhigh,transitionSmall,transitionLarge,classificationSmallTrans,...
        classificationLargeTrans,classificationNoTrans,C]=analysis.kmeans_pupil_v3(pup_norm_unsmoothed);
    save(strcat(saveBaseFolder,mouse,'\',num2str(date),'\',num2str(date),'_proc.mat'),'clusterlow','clusterhigh',...
        'transitionSmall','transitionLarge','classificationSmallTrans','classificationLargeTrans','classificationNoTrans','C','-append');
end

%% Optional dilation-contriction analysis 
% Use whatever pupil variable you prefer for your data, can be normalized
% or not
if strcmp('y',dilcon)
    [Cpts,Dpts,dEvents,dDuration,dMagnitude,cEvents,cDuration,cMagnitude,AVG_cDuration,AVG_dDuration,AVG_dMagnitude,...
        AVG_cMagnitude,new_Cpts,new_Dpts,ff]=analysis.dil_con_events_no_constraints_v2(pup_norm_unsmoothed,blockTransitions); 
    save(strcat(saveBaseFolder,mouse,'\',num2str(date),'\', num2str(date),'_proc.mat'),'Cpts','Dpts','dEvents','dDuration',....
        'dMagnitude','cEvents','cDuration','cMagnitude','AVG_cDuration','AVG_dDuration','AVG_dMagnitude',...
        'AVG_cMagnitude','new_Cpts','new_Dpts','ff','-append');
end

%% Optional dilation - constrcition event detection (Noelle preferred criteria)

[dilation_starts_final]=analysis.dil_con_events_no_constraints_v3(pup_norm_70,blockTransitions);
 save(strcat(saveBaseFolder,mouse,'\',num2str(date),'\', num2str(date),'_proc.mat'),'dilation_start_final');

    