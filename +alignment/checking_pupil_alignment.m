%Checking why pupil is misaligned

clear pupil dilation_starts discrete_pup pup_norm_10 pup_norm_30 pup_norm_unsmoothed...
    pupil_all_blocks pupil_all_blocks_uncorrected pupil_block pupil_smoothed10 pupil_smoothed30 pupil_struct...
    pupil_uncorrected_block

sampling_rate_in_hz = 10;


cd('\\runyan-fs-01\runyan3\Noelle\Pupil\Noelle Pupil\gc700\20220809_reproc\20220809')
z=dir('*.mat');
for i = 1:size(z,1)
    load(z(i).name)
    pupil_struct{i}=pupil;
    clear pupil
end


%%
for n = 1:length(pupil_struct)
    changed_start = 0;
    changed_end = 0;
    % give true start and end frame indices
    start=input('Galvo start frame?\n');
    last = input('Galvo end frame?\n');
    
    % changed the start frame in struct if its wrong
    if pupil_struct{n}.galvo_on ~= start
        fprintf(strcat('Galvo start frame in strcut does not match true galvo start frame, changing value from ', num2str(pupil_struct{n}.galvo_on), ' to ', num2str(start),'\nProceed?\n'))
        pause
        pupil_struct{n}.galvo_on = start;
        changed_start = 1;
    end

    %change the end frame in struct if its wrong
    if pupil_struct{n}.galvo_off~=last
        fprintf(strcat('Galvo end frame in strcut does not match true galvo end frame, changing value from ', num2str(pupil_struct{n}.galvo_off), ' to ', num2str(last),'\nProceed?\n'))
        pause
        pupil_struct{n}.galvo_off = last;
        changed_end = 1;
    end

    % if either the start or end frame were changed, recalculated area and
    % blinks with the correctly cut vector 
    if changed_start ==1 || changed_end ==1
        pupil_struct{n}.radii.cut_uncorrected_radii= pupil_struct{n}.radii.uncut_uncorrected_radii(start:last);
        pupil_struct{n}.area.uncorrected_areas=(pupil_struct{n}.radii.cut_uncorrected_radii.^2).*pi;
        the_areas = pupil_struct{n}.area.uncorrected_areas;
    
        blink_threshold = 1000;
        
        
        blinks_data_positions = processing.noise_blinks_v3(the_areas,sampling_rate_in_hz,blink_threshold);
    
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
        if isnan(corrected_areas(1))
            good_frame = find(~isnan(corrected_areas),1,'first');
            corrected_areas(1:good_frame)=good_frame;
        end



    
        blink_inds=find(isnan(the_areas)==1); 
    
        pupil_struct{n}.area.corrected_areas = corrected_areas;
        
    
        pupil_smoothed10=utils.smooth_median(corrected_areas,10,'gaussian','median');
        pupil_smoothed30=utils.smooth_median(corrected_areas,30,'gaussian','median');
    
        pupil_struct{n}.area.smoothed_30_timeframes = pupil_smoothed30;
        pupil_struct{n}.area.smoothed_10_timeframes = pupil_smoothed10;
    
        pupil_struct{n}.blink = blink_inds;
    end


    fprintf('\nBlock fixed\n')


end


%%
frames_per_tseries = alignment.findframes_nf('\\runyan-fs-01\runyan3\Noelle\2P\2P LC\gc700\gc700_20220809\');

pupil_all_blocks = [];
pupil_all_blocks_uncorrected =[];

for i=1:size(z,1)
    pupil_block = imresize(pupil_struct{1,i}.area.corrected_areas,[1,frames_per_tseries(i)]);
    pupil_uncorrected_block = imresize(pupil_struct{1,i}.area.uncorrected_areas,[1,frames_per_tseries(i)]);

    pupil_all_blocks = [pupil_all_blocks pupil_block];
    pupil_all_blocks_uncorrected = [pupil_all_blocks_uncorrected pupil_uncorrected_block];
end



aligned_pupil_unsmoothed = pupil_all_blocks;
aligned_pupil_smoothed10=utils.smooth_median(aligned_pupil_unsmoothed,10,'gaussian','median');
aligned_pupil_smoothed30= utils.smooth_median(aligned_pupil_unsmoothed,30,'gaussian','median');

pup_norm_30 =(aligned_pupil_smoothed30-mean(aligned_pupil_smoothed30))/mean(aligned_pupil_smoothed30);
pup_norm_10 =(aligned_pupil_smoothed10-mean(aligned_pupil_smoothed10))/mean(aligned_pupil_smoothed10);
pup_norm_unsmoothed =(aligned_pupil_unsmoothed-mean(aligned_pupil_unsmoothed))/mean(aligned_pupil_unsmoothed);



%%
%post-processing changes to artifact detection 
blink_threshold = 400; 
sampling_rate_in_hz=30;

aligned_pupil_compare = pupil_all_blocks;

blinks_data_positions = processing.noise_blinks_v3(aligned_pupil_unsmoothed,sampling_rate_in_hz,blink_threshold);
    
            if isempty(blinks_data_positions)
                fprintf('No blinks \n')
            else
                for i = 1:length(blinks_data_positions)
                    aligned_pupil_unsmoothed(blinks_data_positions{1,i}) = NaN;
                end
                for i = 2:length(blinks_data_positions)
                    if blinks_data_positions{1,i}(1)-blinks_data_positions{1,i-1}(end)<=10
                        aligned_pupil_unsmoothed(blinks_data_positions{1,i-1}(end):blinks_data_positions{1,i}(1)) = NaN;
                    end
                end
                if isnan(aligned_pupil_unsmoothed(1,1))==1
                    fr_replacement_ind=find(isnan(aligned_pupil_unsmoothed)==0,1,'first');
                    fr_replacement_val=aligned_pupil_unsmoothed(fr_replacement_ind);
                    fr_nan_inds = find(isnan(aligned_pupil_unsmoothed),fr_replacement_ind-1,'first');
                    aligned_pupil_unsmoothed(fr_nan_inds)=fr_replacement_val;
                end
                if isnan(aligned_pupil_unsmoothed(1,end))==1
                    lt_replacement_ind=find(isnan(aligned_pupil_unsmoothed)==0,1,'last');
                    lt_replacement_val=aligned_pupil_unsmoothed(lt_replacement_ind);
                    lt_nan_inds = find(isnan(aligned_pupil_unsmoothed),length(aligned_pupil_unsmoothed)-lt_replacement_ind,'last');
                    aligned_pupil_unsmoothed(lt_nan_inds)=lt_replacement_val;
                end
            end
            
            %eliminate measurements outside of physiologically possible range
            %the_areas(the_areas >5) = NaN; 
            %the_areas(the_areas<.05) = NaN;
            aligned_pupil_unsmoothed(aligned_pupil_unsmoothed <500)=NaN;
    
        %interpolate across eliminated artifacts
        x = 1:length(aligned_pupil_unsmoothed);
        y = aligned_pupil_unsmoothed;
        xi = x(find(~isnan(y)));
        yi = y(find(~isnan(y)));

         corrected_aligned_pupil_unsmoothed = interp1(xi,yi,x);

figure(10);clf;hold on;
plot(aligned_pupil_compare)
plot(corrected_aligned_pupil_unsmoothed)



aligned_pupil_unsmoothed=corrected_aligned_pupil_unsmoothed;
aligned_pupil_smoothed10=utils.smooth_median(aligned_pupil_unsmoothed,10,'gaussian','median');
aligned_pupil_smoothed30= utils.smooth_median(aligned_pupil_unsmoothed,30,'gaussian','median');
aligned_pupil_smoothed100= utils.smooth_median(aligned_pupil_unsmoothed,100,'gaussian','median');
aligned_pupil_smoothed70= utils.smooth_median(aligned_pupil_unsmoothed,70,'gaussian','median');

pup_norm_30 =(aligned_pupil_smoothed30-mean(aligned_pupil_smoothed30))/mean(aligned_pupil_smoothed30);
pup_norm_10 =(aligned_pupil_smoothed10-mean(aligned_pupil_smoothed10))/mean(aligned_pupil_smoothed10);
pup_norm_unsmoothed =(aligned_pupil_unsmoothed-mean(aligned_pupil_unsmoothed))/mean(aligned_pupil_unsmoothed);
pup_norm_100 =(aligned_pupil_smoothed100-mean(aligned_pupil_smoothed100))/mean(aligned_pupil_smoothed100);
pup_norm_70 =(aligned_pupil_smoothed70-mean(aligned_pupil_smoothed70))/mean(aligned_pupil_smoothed70);



%% get the dilation points 
pupil = pup_norm_70;
[dilation_starts_final]=analysis.dil_con_events_no_constraints_v3(pupil,blockTransitions);

save('20220809_proc_final', 'dilation_starts_final','pup_norm_unsmoothed',...
    'pup_norm_10','pup_norm_30','pup_norm_70','pup_norm_100','aligned_pupil_unsmoothed',...
    'aligned_pupil_smoothed10','aligned_pupil_smoothed30','aligned_pupil_smoothed70',...
    'aligned_pupil_smoothed100','blockTransitions');

        













