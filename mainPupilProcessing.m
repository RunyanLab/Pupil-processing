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
sampling_rate_in_hz=input('What is the frame rate fo the camera?');
threshold = input('Threshold?'); 
orientation = input('What is the orientation of the camera? 0(normal)/90(rotated)');
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

rawDataFolder =strcat('\\runyan-fs-01\Runyan3\Noelle\Pupil\Noelle Pupil\',mouse,'\',num2str(date),'\'); 
acqFolder=strcat('\\runyan-fs-01\Runyan3\Noelle\wavesurfer\LC\',mouse,'_',num2str(date),'\burst'); %only need if doing tight alingment
tseriesBaseFolder=strcat('\\runyan-fs-01\Runyan3\Noelle\2P LC\',mouse,'\',num2str(date),'_burst\');
saveBaseFolder ='\\runyan-fs-01\Runyan3\Noelle\Pupil\Noelle Pupil\processed\'; %this is where final aligned files will be saved, not processed files for individual blocks, those will be saved in the base folder by default

d = dir(strcat(rawDataFolder,'\MATLAB_*.avi'));
    cd(rawDataFolder);
    
blocks = 1:size(d,1); %each movie within a imaging session date is considered a separate block 

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
    the_image = read(obj,100);
    rows = size(the_image,1);
    columns = size(the_image,2);
    all_ridx = zeros(1,NumberOfFrames);
    all_cidx = zeros(1,NumberOfFrames);
    
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
       
        %   You may wish to set some contraints on the location within the
        %   image that pupil ROI can exist in order to minimize cases where
        %   the function identifies an object outside of pupil as pupil.
        %   You can eliminate rows/columns where it is impossible for pupil to occur
        %   (ex along edges of fov). 
        %   Note: this will likely differ across datasets, be sure not to
        %   eliminate locations where pupil has the possibility of appearing. 

        L(1:275,:) = 0; 
        L(:,1:150) =0;
        %L(:,250:end)=0;
        %L(670:end,:) = 0;
        BW1 = edge(L,'Canny'); 
        [row,column] = find(BW1);
        x = vertcat(row',column'); %x is the input indices used to fit the circle
        
  
        
        %looks for gaps in distribution of object locations - if gaps
        %exist, this indicates more than one object was identified. This
        %allows for proper selection of the pupil as object to fit circle.
    
        if orientation == 90
            if isempty(x)
                x = []; 
            elseif ~isempty(x) &&  isempty(center_row)
                bott=find(x(1,:)>=prctile(x(1,:),80)); %only want to input the top and bottom 20% of x into fitcircles to allow a more accurate circle be fit to frames where pupil is partially occurlied by eyelid
                top=find(x(1,:)<=prctile(x(1,:),20));
                ind = union(bott,top);
                x = x(:,ind);          
            else
                groupID = dbscan(x',5,5);
                groupID = groupID';
                if max(groupID)== 1
                    bott=find(x(1,:)>=prctile(x(1,:),80)); 
                    top=find(x(1,:)<=prctile(x(1,:),20));
                    ind = union(bott,top);
                    x = x(:,ind);
                else
                    row_means = [];
                    col_means = [];
                    for group = 1:max(groupID)
                        row_means = [row_means mean(x(1,groupID == group))];
                    end
                    for group = 1:max(groupID)
                        col_means = [col_means mean(x(2,groupID == group))];
                    end
                    [~,ridx] = min(abs(center_row(cnt-1)-row_means));
                    %all_ridx(cnt) = ridx;
                    [~,cidx] = min(abs(center_column(cnt-1)-col_means));
                    %all_ridx(cnt) = ridx;
                    if ridx~=cidx 
                        %x = x(:,groupID == max(ridx));
                        x = x(:,groupID == 1);
                        all_ridx(cnt) = 1;
                        all_cidx(cnt) = 1;
                        bott = find(x(1,:)>=prctile(x(1,:),80));
                        top = find(x(1,:)<=prctile(x(1,:),20));
                        ind = union(bott,top);
                        x = x(:,ind);
                    else
                        x = x(:,groupID == ridx);
                        all_ridx(cnt) = ridx;
                        all_cidx(cnt) = cidx;
                        bott = find(x(1,:)>=prctile(x(1,:),80));
                        top = find(x(1,:)<=prctile(x(1,:),20));
                        ind = union(bott,top);
                        x = x(:,ind);
                    end
                end
            end
        else
            if isempty(x)
                x = []; 
            elseif ~isempty(x) &&  isempty(center_row)
                bott=find(x(2,:)>=prctile(x(2,:),80)); %only want to input the top and bottom 20% of x into fitcircles to allow a more accurate circle be fit to frames where pupil is partially occurlied by eyelid
                top=find(x(2,:)<=prctile(x(2,:),20));
                ind = union(bott,top);
                x = x(:,ind);          

            else
                groupID = dbscan(x',5,5);
                groupID = groupID';
                if max(groupID)== 1
                    bott=find(x(2,:)>=prctile(x(2,:),80)); 
                    top=find(x(2,:)<=prctile(x(2,:),20));
                    ind = union(bott,top);
                    x = x(:,ind);
                else
                    row_means = [];
                    col_means = [];
                    for group = 1:max(groupID)
                        row_means = [row_means mean(x(1,groupID == group))];
                    end
                    for group = 1:max(groupID)
                        col_means = [col_means mean(x(2,groupID == group))];
                    end
                    [~,ridx] = min(abs(center_row(cnt-1)-row_means));
                    %all_ridx(cnt) = ridx;
                    [~,cidx] = min(abs(center_column(cnt-1)-col_means));
                    %all_ridx(cnt) = ridx;
                    TFmatch = ridx == cidx;
                    if TFmatch==0
                        %x = x(:,groupID == max(ridx));
                        x = x(:,groupID == 1);
                        all_ridx(cnt) = 1;
                        all_cidx(cnt) = 1;
                        bott = find(x(2,:)>=prctile(x(2,:),80));
                        top = find(x(2,:)<=prctile(x(2,:),20));
                        ind = union(bott,top);
                        x = x(:,ind);
                    else
                        x = x(:,groupID == ridx);
                        all_ridx(cnt) = ridx;
                        all_cidx(cnt) = cidx;
                        bott = find(x(2,:)>=prctile(x(2,:),80));
                        top = find(x(2,:)<=prctile(x(2,:),20));
                        ind = union(bott,top);
                        x = x(:,ind);
                    end
                end
            end
         end
      
      
      
      
      
      
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
    
    % manipulations on the raw trace of current block
    first_index = find(raw_radii,1,'first'); %2p acquisition onset
    last_index = find(raw_radii,1,'last'); %2p offset
    the_radii_cut = raw_radii(first_index:last_index);
    center_row_cut = center_column(first_index:last_index);
    center_column_cut = center_column(first_index:last_index);
    
    %converting pix^2 to mm^2
    if strcmp('m', unit)
        the_radii = the_radii_cut.*0.00469426267; 
   %Adjust conversion factor according to camera and settings: 
    %Camera on 2P investigator:
        %1024 x 1280 pix res --> conversion factor = 0.00469426267
        %512 x 640 pix res --> conversion factor = 0.00949848
    %Camera on 2P+:
        %1024 x 1280 pix res --> conversion factor = 0.01171303
        %512 x 640 pix res --> conversion factor = 0.02324933
        the_areas = (the_radii.^2).*pi;
        the_areas_compare = (the_radii.^2).*pi;
        blink_threshold = .1;
    else
        the_radii= the_radii_cut;
        the_areas = (the_radii.^2).*pi;
        the_areas_compare = (the_radii.^2).*pi;
        blink_threshold = 2000;
    end
    
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

    %interpolate across eliminated artifacts
    x = 1:length(the_areas);
    y = the_areas;
    xi = x(find(~isnan(y)));
    yi = y(find(~isnan(y)));

    corrected_areas = interp1(xi,yi,x);
    %corrected_areas_mm_test = interp1(xi,yi,x);
    %figure(91)
    %clf
    %plot(corrected_areas_mm) 
    %hold on 
    %plot(corrected_areas_mm_test)
    %corrected_areas_mm = interp1(xi,yi,x);

    blink_inds=find(isnan(the_areas)==1); 
    %the_centers_cut(blink_inds)=NaN;
    %a = 1:length(the_centers_cut);
    %b = the_centers_cut;
    %ai = a(find(~isnan(b)));
    %bi = b(find(~isnan(b)));
    %corrected_centers = interp1(ai,bi,a); %centers with blinks interpolated 
    %corrected_centers(1:20)=corrected_centers(21);


    pupil_smoothed10=utils.smooth_median(corrected_areas,10,'gaussian','median');
    pupil_smoothed30=utils.smooth_median(corrected_areas,30,'gaussian','median');


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
    pupil.area.smoothed_30_timeframes = pupil_smoothed30;
    pupil.area.smoothed_10_timeframes = pupil_smoothed10;
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

keep mouse blocks date alignment km dilcon rawDataFolder acqFolder saveBaseFolder pupil_struct ;

%% Aligning pupil trace concatenated across blocks to imaging data 
if strcmp('t',align)
    [aligned_pupil_unsmoothed,aligned_pupil_smoothed10,aligned_pupil_smoothed30,...
        aligned_y_position,aligned_x_position,blockTransitions,pup_norm_unsmoothed,...
        pup_norm_10,pup_norm_30]=alignment.make_pupil_aligned_tight(acqFolder,blocks,pupil_struct);
else
    [aligned_pupil_unsmoothed,aligned_pupil_smoothed10,aligned_pupil_smoothed30,...
        aligned_y_position,aligned_x_position,blockTransitions,pup_norm_unsmoothed,...
        pup_norm_10,pup_norm_30]=alignment.make_pupil_aligned_rough(pupil_struct);
end
%cd(saveBaseFolder)
mkdir([saveBaseFolder mouse '\' num2str(date)]);
save(strcat(saveBaseFolder,'\',mouse,'\',num2str(date),'\',num2str(date),'_proc.mat'),'aligned_pupil_unsmoothed',...
    'pup_norm_30','pup_norm_10','pup_norm_unsmoothed','aligned_pupil_smoothed30',...
    'aligned_pupil_smoothed10','aligned_x_position','aligned_y_position','blockTransitions');

%% Optional K-means analysis
% Use whichever pupil variable you prefer for you data, however it should
% be normalized (pup_norm_unsmoothed, pup_norm_10, or pup_norm_30)
if strcmp('y',km)
    [clusterlow,clusterhigh,transitionSmall,transitionLarge,classificationSmallTrans,...
        classificationLargeTrans,classificationNoTrans,C]=analysis.kmeans_pupil_v3(pup_norm_unsmoothed);
    save(strcat(saveBaseFolder,'\',mouse,'\',num2str(date),'\',num2str(date),'_proc.mat'),'clusterlow','clusterhigh',...
        'transitionSmall','transitionLarge','classificationSmallTrans','classificationLargeTrans','classificationNoTrans','C','-append');
end

%% Optional dilation-contriction analysis 
% Use whatever pupil variable you prefer for your data, can be normalized
% or not
if strcmp('y',dilcon)
    [Cpts,Dpts,dEvents,dDuration,dMagnitude,cEvents,cDuration,cMagnitude,AVG_cDuration,AVG_dDuration,AVG_dMagnitude,...
        AVG_cMagnitude,new_Cpts,new_Dpts,ff]=analysis.dil_con_events_no_constraints_v2(pup_norm_unsmoothed,blockTransitions); 
    save(strcat(saveBaseFolder,'\',mouse,'\', num2str(date),'_proc.mat'),'Cpts','Dpts','dEvents','dDuration',....
        'dMagnitude','cEvents','cDuration','cMagnitude','AVG_cDuration','AVG_dDuration','AVG_dMagnitude',...
        'AVG_cMagnitude','new_Cpts','new_Dpts','ff','-append');
end



    