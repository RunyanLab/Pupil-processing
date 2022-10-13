%% Documentation
% This is the outshell code for calling all functions to process grayscale
% AVI files containing pupil imaging. 
%   Processes AVI file of pupil, fitting circles around pupil ROI,
%   generting artifact corrected frame by frame measurements of pupil area in
%   mm^2 
%This is the code for Pupil without laser emilination

%% Setup 
% User inputs information about the current dataset
mouse = input('Whats the mouse ID? Please input as string');
date = input('Date?');
sampling_rate_in_hz=input('What is the frame rate of the camera?');
threshold = input('Threshold?'); 
orientation = input('What is the orientation of the camera? 0(normal)/90(rotated)');
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

rawDataFolder =strcat('\\136.142.49.216\Runyan2\Michael\Pupil Movies\',mouse,'\',num2str(date),'\'); 
%acqFolder=strcat('\\runyan-fs-01\Runyan3\Noelle\wavesurfer\LC\',mouse,'_',num2str(date),'\burst'); %only need if doing tight alingment
%tseriesBaseFolder=strcat('\\runyan-fs-01\Runyan3\Noelle\2P\2P LC\',mouse,'\',mouse,'_',num2str(date),'\');
saveBaseFolder ='\\136.142.49.216\Runyan2\Michael\Pupil Movies\Processed Pupil\'; %this is where final aligned files will be saved, not processed files for individual blocks, those will be saved in the base folder by default

d = dir(strcat(rawDataFolder,'*.avi'));
    cd(rawDataFolder);
    
blocks = 1:size(d,1); %each movie within a imaging session date is considered a separate block 

%% Establish eye ROI and corneal reflections

exp_obj = VideoReader(d(blocks).name);
the_example_image = read(exp_obj,(exp_obj.NumberOfFrames)/2);
rows = size(the_example_image,1);
columns = size(the_example_image,2);
imshow(the_example_image)
hold on 
eye = drawellipse;
pause;
eyeMask = poly2mask(eye.Vertices(:,1), eye.Vertices(:,2) , rows, columns);


cornealReflection = drawellipse;
pause
cornMask = poly2mask(cornealReflection.Vertices(:,1), cornealReflection.Vertices(:,2) , rows, columns);


%% Loop through all blocks
% For each block this will read out each frame, identify pupil ROI, get
% area meaurment for circle made, remove blinks and other artifacts from
% trace, save individual files for each block and a structure containing
% variables pertaining to each block 

for block =blocks
   
    if block<10
        obj = VideoReader(strcat('MATLAB_000',num2str(block),'.avi')); %reads video file properites
    else
        obj = VideoReader(strcat('MATLAB_00',num2str(block),'.avi'));
    end
    
    NumberOfFrames = obj.NumberOfFrames;

    
    %Initailize variables 
    the_areas = [];
    raw_radii = [];
    center_row = [];
    center_column = [];
    all_ridx = zeros(1,NumberOfFrames);
    all_cidx = zeros(1,NumberOfFrames);




    
    %Converts each frame to BW matrix based on threshold
    for cnt = 1:NumberOfFrames  
        the_image = read(obj,cnt);
        if size(the_image,3)==3
            the_image = rgb2gray(the_image);
        end
         inv=imcomplement(the_image);
        piel = im2bw(inv,threshold);
        
        piel = bwmorph(piel,'open');
        piel = bwareaopen(piel,200);
        piel = imfill(piel,'holes');
        
     % Tagged objects in BW image
        L = bwlabel(piel);
        L(~eyeMask)=0;
        L(cornMask)=0;


        BW1 = edge(L,'Canny'); 
        [row,column] = find(BW1);
        x = vertcat(row',column'); %x is the input indices used to fit the circle

    
        x=processing.getROIcoordinates(orientation,x,center_row,center_column,all_ridx,all_cidx,cnt);    
        
      
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
          [val,idx] = min(abs(raw_radii(cnt-1)-r));
          radius = r(idx);
          z([1 2]) = z([2 1]);
          center = z;
      end
      
      figure(1)
      clf;
      imshow(the_image)
      viscircles(z',r)
      pause(.01)
      
      raw_radii = [raw_radii radius];
      area = (radius^2)*pi;
      the_areas = [the_areas area];
      center_row = [center_row center(2,1)];
      center_column = [center_column center(1,1)];
    end
    
            the_radii = raw_radii.*0.00469426267; %need to get conversion factor
   
        the_areas = (the_radii.^2).*pi;
        the_areas_compare = (the_radii.^2).*pi;
        blink_threshold = .1; %test blink threshold once conversion factor found
    
    %eliminating blinks
    blinks_data_positions = processing.noise_blinks_v3(the_areas,sampling_rate_in_hz,blink_threshold);
       % if isempty(blinks_data_positions{2})==1
        %    blinks_data_positions(2) =[];
        %end
        if isempty(blinks_data_positions)
            fprintf('No blinks \n')
        else
            for i = 1:length(blinks_data_positions)
                the_areas(blinks_data_positions{1,i}) = NaN;
            end
            for i = 2:length(blinks_data_positions)
                if blinks_data_positions{1,i}(1)-blinks_data_positions{1,i-1}(end)<=10
                    the_areas(blinks_data_positions{1,i-1}(end):blinks_data_positions{1,i}(1)) = NaN;
                end
            end
            if isnan(the_areas(1,1))==1
                fr_replacement_ind=find(isnan(the_areas)==0,1,'first');
                fr_replacement_val=the_areas(fr_replacement_ind);
                fr_nan_inds = find(isnan(the_areas),fr_replacement_ind-1,'first');
                the_areas(fr_nan_inds)=fr_replacement_val;
            end
            if isnan(the_areas(1,end))==1
                lt_replacement_ind=find(isnan(the_areas)==0,1,'last');
                lt_replacement_val=the_areas(lt_replacement_ind);
                lt_nan_inds = find(isnan(the_areas),length(the_areas)-lt_replacement_ind,'last');
                the_areas(lt_nan_inds)=lt_replacement_val;
            end
        end
        
        %eliminate measurements outside of physiologically possible range
        %the_areas(the_areas >5) = NaN; 
        %the_areas(the_areas<.05) = NaN;
        the_areas(the_areas ==0)=NaN;

    %interpolate across eliminated artifacts
    x = 1:length(the_areas);
    y = the_areas;
    xi = x(find(~isnan(y)));
    yi = y(find(~isnan(y)));

    corrected_areas = interp1(xi,yi,x);

    blink_inds=find(isnan(the_areas)==1); 



    pupil_smoothed10=utils.smooth_median(corrected_areas,10,'gaussian','median');
    pupil_smoothed30=utils.smooth_median(corrected_areas,30,'gaussian','median');


    figure(1)
    clf
    plot(corrected_areas)
    hold on
    plot(the_areas_compare)
    pause;


    the_areas_compare = (the_radii.^2).*pi;
    pupil.center_position.center_column = center_column;
    pupil.center_position.center_row = center_row;
    pupil.area.corrected_areas=corrected_areas;
    pupil.area.uncorrected_areas = the_areas_compare;
    pupil.area.smoothed_30_timeframes = pupil_smoothed30;
    pupil.area.smoothed_10_timeframes = pupil_smoothed10;
    pupil.radii.pixels_uncorrected_radii =  raw_radii;
    pupil.radii.mm_uncorrected_radii = the_radii;
    pupil.blink = blink_inds;

    if block<10
        save(strcat(mouse,'_000',num2str(block),'.mat'),'pupil');
    else
        save(strcat(mouse,'_00',num2str(block),'.mat'),'pupil');
    end
    
    pupil_struct{block} = pupil;    

end

keep mouse blocks date align km dilcon rawDataFolder acqFolder saveBaseFolder pupil_struct tseriesBaseFolder eye cornealReflection;

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
save(strcat(saveBaseFolder,mouse,'\',num2str(date),'\',num2str(date),'_proc.mat'),'aligned_pupil_unsmoothed',...
    'pup_norm_30','pup_norm_10','pup_norm_unsmoothed','aligned_pupil_smoothed30',...
    'aligned_pupil_smoothed10','aligned_x_position','aligned_y_position','blockTransitions');

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



    