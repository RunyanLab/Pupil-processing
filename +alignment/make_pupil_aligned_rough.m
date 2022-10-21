function  [aligned_pupil_unsmoothed,aligned_pupil_smoothed10,aligned_pupil_smoothed30,...
        aligned_pupil_smoothed70,aligned_pupil_smoothed100,...
        aligned_y_position,aligned_x_position,blockTransitions,pup_norm_unsmoothed,...
        pup_norm_10,pup_norm_30,pup_norm_70,pup_norm_100] = make_pupil_aligned_rough(pupil_struct,tseriesBaseFolder)

%% get total number of frames per tsreies
[frames_per_tseries]=alignment.findframes_nf(tseriesBaseFolder);

%% stretch each individual tseries to length of imaging frames
aligned_pupil_unsmoothed =[];
aligned_y_position =[];
aligned_x_position =[];

for i=1:length(pupil_struct)
    pupil_block = imresize(pupil_struct{1,i}.area.corrected_areas,[1,frames_per_tseries(i)]);
    ypos_block = imresize(pupil_struct{1,i}.center_position.center_column,[1,frames_per_tseries(i)]);
    xpos_block = imresize(pupil_struct{1,i}.center_position.center_row,[1,frames_per_tseries(i)]);
    aligned_pupil_unsmoothed = [aligned_pupil_unsmoothed pupil_block];
    aligned_y_position = [aligned_y_position ypos_block];
    aligned_x_position = [aligned_x_position xpos_block];
end


aligned_pupil_smoothed10=utils.smooth_median(aligned_pupil_unsmoothed,10,'gaussian','median');
aligned_pupil_smoothed30= utils.smooth_median(aligned_pupil_unsmoothed,30,'gaussian','median');
aligned_pupil_smoothed100= utils.smooth_median(aligned_pupil_unsmoothed,100,'gaussian','median');
aligned_pupil_smoothed70= utils.smooth_median(aligned_pupil_unsmoothed,70,'gaussian','median');


pup_norm_30 =(aligned_pupil_smoothed30-mean(aligned_pupil_smoothed30))/mean(aligned_pupil_smoothed30);
pup_norm_10 =(aligned_pupil_smoothed10-mean(aligned_pupil_smoothed10))/mean(aligned_pupil_smoothed10);
pup_norm_unsmoothed =(aligned_pupil_unsmoothed-mean(aligned_pupil_unsmoothed))/mean(aligned_pupil_unsmoothed);
pup_norm_100 =(aligned_pupil_smoothed100-mean(aligned_pupil_smoothed100))/mean(aligned_pupil_smoothed100);
pup_norm_70 =(aligned_pupil_smoothed70-mean(aligned_pupil_smoothed70))/mean(aligned_pupil_smoothed70);

%% identify on which frames the tseries inferaces are     
blockTransitions = [];
frames = 0;
for b=1:length(frames_per_tseries)
    frames= frames+frames_per_tseries(b);
    blockTransitions(b)=frames;
end





