function  [aligned_pupil_unsmoothed,aligned_pupil_smoothed10,aligned_pupil_smoothed30,...
        aligned_y_position,aligned_x_position,blockTransitions,pup_norm_unsmoothed,...
        pup_norm_10,pup_norm_30] = make_pupil_aligned_rough(pupil_struct,tseriesBaseFolder)

% Horizontally concatenates blocks
temp_pupil_full = []; %concatenated pupil trace (all blocks), raw
temp_pupil_smoothed_30 = []; %concatenated pupil trace, smoothed by median over 30 timeframes
temp_pupil_smoothed_10 = []; %concatenated pupil trace, smoothed by median over 10 timeframes
temp_xpos = [];
temp_ypos = [];
for i=1:length(pupil_struct)
    temp_pupil_full = [temp_pupil_full pupil_struct{i}.area.corrected_areas]; %change made from pupil_cat_stretched to pupil_cat_raw_smoothed_cut NF 5/3)
    temp_pupil_smoothed_30 = [temp_pupil_smoothed_30 pupil_struct{i}.area.smoothed_30_timeframes];
    temp_pupil_smoothed_10 = [temp_pupil_smoothed_10 pupil_struct{i}.area.smoothed_10_timeframes];
    temp_xpos = [temp_xpos pupil_struct{i}.center_position.center_column];
    temp_ypos = [temp_ypos pupil_struct{i}.center_position.center_row];
end



%%CALL FUNCTION TO ALIGN PUPIL WITH GALVO 
[aligned_pupil_unsmoothed,framesperblock] = alignment.make_pupil_aligned_tseries(tseriesBaseFolder,temp_pupil_full);%uses t-series as opposed to wavesurfer to get 2p frames - since not synching signal this is easier than going through wavesurfer
aligned_pupil_smoothed10=imresize(temp_pupil_smoothed_10,[1,length(aligned_pupil_unsmoothed)]);
aligned_pupil_smoothed30=imresize(temp_pupil_smoothed_30,[1,length(aligned_pupil_unsmoothed)]);
aligned_x_position = imresize(temp_xpos,[1,length(aligned_pupil_unsmoothed)]);
aligned_y_position = imresize(temp_ypos,[1,length(aligned_pupil_unsmoothed)]);


if length(find(isnan(aligned_pupil_smoothed30)))>0
    nanx = isnan(aligned_pupil_smoothed30);
    t = 1:numel(aligned_pupil_smoothed30);
    aligned_pupil_smoothed30(nanx) = interp1(t(~nanx),aligned_pupil_smoothed30(~nanx), t(nanx));
    aligned_pupil_smoothed10(nanx) = interp1(t(~nanx),aligned_pupil_smoothed10(~nanx), t(nanx));
    aligned_pupil_unsmoothed(nanx) = interp1(t(~nanx),aligned_pupil_unsmoothed_10(~nanx), t(nanx));
end
    

%NORMALIZE PUPIL TO COMPARE ACROSS MICE AND DAYS 
%m = mean(aligned_pupil_smoothed_30);
pup_norm_30 =(aligned_pupil_smoothed30-mean(aligned_pupil_smoothed30))/mean(aligned_pupil_smoothed30);
pup_norm_10 =(aligned_pupil_smoothed10-mean(aligned_pupil_smoothed10))/mean(aligned_pupil_smoothed10);
pup_norm_unsmoothed =(aligned_pupil_unsmoothed-mean(aligned_pupil_unsmoothed))/mean(aligned_pupil_unsmoothed);


% get index of block transitions 
blockTransitions = [];
     frames=0;
    for i=1:length(framesperblock)
        frames = frames+framesperblock(1,i);
     blockTransitions(i) = frames;
    end
    





