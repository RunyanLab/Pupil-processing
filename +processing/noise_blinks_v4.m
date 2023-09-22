function [blinks_data_positions,blink_inds,corrected_areas2,groom_inds,corrected_row, corrected_column] = noise_blinks_v4(the_areas,center_column_cut,center_row_cut,sampling_rate,selectedBlink)
%blinks_data_positions=[];
    sampling_interval     = round(1000/sampling_rate); % compute the sampling time interval in milliseconds.
    gap_interval          = 100;   % set the interval between two sets that appear consecutively for concatenation.
   % blink_inds=find(isoutlier(diff(blink_cut),'mean')==1);%can also add another conditional of needing to see a monotonic increase
   blink_threshold = selectedBlink; 
   deriv_pup=diff(the_areas);
    blink_indsup=find(deriv_pup>=blink_threshold); %orginally 0.1
    blink_indslow=find(deriv_pup<=-blink_threshold);

    blink_inds=union(blink_indsup,blink_indslow);
    if ~isempty(blink_inds) && blink_inds(1) == 1 %making sure there is a value for first one even with blink
        blink_inds(1) = [];
    end
    binary_blinks=zeros(1,length(the_areas));
    binary_blinks(blink_inds)=1;%creating a binary response vector: 1 is blink 0 is no blink
    
    %figure(1)
    %clf
   %hold on 
    %plot(blink_cut)
    %plot(blink_inds,blink_cut(blink_inds),'-o');
    
    if (isempty(blink_inds))
        blinks_data_positions = [];
        return;
    else
    
    onsets=find(diff(binary_blinks)==1);
    if ~isempty(blink_inds) && blink_inds(1) == 2
        onsets(1) = 2;
    end
    offsets=find(diff(binary_blinks)==-1);
    if blink_inds(1)==1
        onsets=horzcat(1,onsets);
    end
    if blink_inds(end)==length(the_areas)
        offsets=horzcat(offsets,length(the_areas));
    end
    
     
    blinks      = vertcat(onsets, offsets+1); %each column corresponds to a blink event - negative number is the blink onset, positive number is blink offset
    
    %% Smoothing the data in order to increase the difference between the measurement noise and the eyelid signal.
    ms_4_smooting  = 10;                                    % using a gap of 10 ms for the smoothing
    samples2smooth = ceil(ms_4_smooting/sampling_interval); % amount of samples to smooth 
    smooth_data    = utils.smooth(the_areas, samples2smooth);    

    smooth_data(smooth_data==0) = nan;                      % replace zeros with NaN values
    diff_smooth_data            = diff(smooth_data);
    

 %% Finding the blinks' onset and offset
blinks_data_positions=cell(1,length(blinks));
%Case 1: data starts with a blink
for i=1:size(blinks,2)
    if blinks(1,i)==1
        realOnset=1;
        realOffset=find(diff_smooth_data(blinks(2,i):end)<=0,1,'first');
        blinks_data_positions{1,i}=realOnset:realOffset;
    elseif blinks(2,i)==length(the_areas)
        realOnset=find(diff_smooth_data(1:blinks(1,i))>=0,1,'last');
        realOffset=length(the_areas);
        blinks_data_positions{1,i}=realOnset:realOffset;
    elseif blinks(1,i)~=1&& blinks(2,i)~=length(the_areas)
        realOnset=find(diff_smooth_data(1:blinks(1,i))>=0,1,'last');
        realOffset=find(diff_smooth_data(blinks(2,i):end)<=0,1,'first')+(blinks(2,i)-1);
        blinks_data_positions{1,i}=realOnset:realOffset;
    end
end
    end
    
    blinks_data_positions = blinks_data_positions(~cellfun('isempty',blinks_data_positions));
    
%% making position in area vector NaN where a blink occurred then interpolate across it
if isempty(blinks_data_positions)
    fprintf('No blinks \n')
else
    for i = 1:length(blinks_data_positions)
        the_areas(blinks_data_positions{1,i}) = NaN;
        center_column_cut(blinks_data_positions{1,i}) = NaN;
        center_row_cut(blinks_data_positions{1,i}) = NaN;
        
    end
    for i = 2:length(blinks_data_positions)
        if blinks_data_positions{1,i}(1)-blinks_data_positions{1,i-1}(end)<=10
            the_areas(blinks_data_positions{1,i-1}(end):blinks_data_positions{1,i}(1)) = NaN;
            center_column_cut(blinks_data_positions{1,i-1}(end):blinks_data_positions{1,i}(1)) = NaN;
            center_row_cut(blinks_data_positions{1,i-1}(end):blinks_data_positions{1,i}(1)) = NaN;
        end
    end
    if isnan(the_areas(1,1))==1
        fr_replacement_ind=find(isnan(the_areas)==0,1,'first');
        fr_replacement_val=the_areas(fr_replacement_ind);
        fr_nan_inds = find(isnan(the_areas),fr_replacement_ind-1,'first');
        the_areas(fr_nan_inds)=fr_replacement_val;

        fr_replacement_ind=find(isnan(center_column_cut)==0,1,'first');
        fr_replacement_val=center_column_cut(fr_replacement_ind);
        fr_nan_inds = find(isnan(center_column_cut),fr_replacement_ind-1,'first');
        center_column_cut(fr_nan_inds)=fr_replacement_val;

        fr_replacement_ind=find(isnan(center_row_cut)==0,1,'first');
        fr_replacement_val=center_row_cut(fr_replacement_ind);
        fr_nan_inds = find(isnan(center_row_cut),fr_replacement_ind-1,'first');
        center_row_cut(fr_nan_inds)=fr_replacement_val;

    end
    if isnan(the_areas(1,end))==1
        lt_replacement_ind=find(isnan(the_areas)==0,1,'last');
        lt_replacement_val=the_areas(lt_replacement_ind);
        lt_nan_inds = find(isnan(the_areas),length(the_areas)-lt_replacement_ind,'last');
        the_areas(lt_nan_inds)=lt_replacement_val;

        lt_replacement_ind=find(isnan(center_column_cut)==0,1,'last');
        lt_replacement_val=center_column_cut(lt_replacement_ind);
        lt_nan_inds = find(isnan(center_column_cut),length(center_column_cut)-lt_replacement_ind,'last');
        center_column_cut(lt_nan_inds)=lt_replacement_val;

        lt_replacement_ind=find(isnan(center_row_cut)==0,1,'last');
        lt_replacement_val=center_row_cut(lt_replacement_ind);
        lt_nan_inds = find(isnan(center_row_cut),length(center_row_cut)-lt_replacement_ind,'last');
        center_row_cut(lt_nan_inds)=lt_replacement_val;
    end
end

%eliminate measurements outside of physiologically possible range
%the_areas(the_areas >5) = NaN; 
%the_areas(the_areas<.05) = NaN;
the_areas(the_areas ==0)=NaN;
center_column_cut(center_column_cut ==0)=NaN;
center_row_cut(center_row_cut ==0)=NaN;

%interpolate across eliminated artifacts
x = 1:length(the_areas);
y = the_areas;
xi = x(find(~isnan(y)));
yi = y(find(~isnan(y)));

corrected_areas = interp1(xi,yi,x);

%column
x = 1:length(center_column_cut);
y = center_column_cut;
xi = x(find(~isnan(y)));
yi = y(find(~isnan(y)));

corrected_col = interp1(xi,yi,x);

%rows
x = 1:length(center_row_cut);
y = center_row_cut;
xi = x(find(~isnan(y)));
yi = y(find(~isnan(y)));

corrected_ro = interp1(xi,yi,x);
%CB ADDITIONS!
%ADDING CODE TO DEAL WITH GROOMING!!
groom_inds = [];
[peaks,groom_locs1] = find(diff(corrected_areas) == 0);
if median(corrected_areas)<5 %if it's corrected (mm)
    groom_inds = unique([find(corrected_areas<(median(corrected_areas)-1)),groom_locs1]);
else %not corrected (pixel)
    groom_inds = unique([find(corrected_areas<(median(corrected_areas)-1000)),groom_locs1]);
end
numbers = groom_inds;
% Find the indices where the differences are greater than 1
splitIndices = find(diff(groom_inds)>1);
for i = 1:length(splitIndices) %bc im using diff it needs some values to be added to the right to make it cleaner
    if groom_inds(splitIndices(i))+3 <length(corrected_areas) %in case it's at the very end of the file
        groom_inds = [groom_inds,[groom_inds(splitIndices(i))+1:groom_inds(splitIndices(i))+3]];
    end
end

if ~isempty(groom_inds) && groom_inds(1) == 1 %making sure there is a value for first one even with blink
    groom_inds(1) = [];
    groom_locs1(1) = [];
end
%initiate variables
corrected_areas2 = [];corrected_column =[];corrected_row =[];

the_areas(groom_inds) = NaN;
y = the_areas;
xi = x(find(~isnan(y)));
yi = y(find(~isnan(y)));
corrected_areas2 = interp1(xi,yi,x);

center_column_cut(groom_inds) = NaN;
y = center_column_cut;
xi = x(find(~isnan(y)));
yi = y(find(~isnan(y)));
corrected_column = interp1(xi,yi,x);

center_row_cut(groom_inds) = NaN;
y = center_row_cut;
xi = x(find(~isnan(y)));
yi = y(find(~isnan(y)));
corrected_row = interp1(xi,yi,x);


% groom_interp = [];
%    
%     
%     % Initialize variables
%     startIdx = 1;
%     endIdx = [];
%     groupedRanges = [];
%     
%     % Iterate through split indices to extract consecutive ranges
%     for i = 1:length(splitIndices)
%         endIdx = splitIndices(i);
%         groupedRanges = [groupedRanges; numbers(startIdx), numbers(endIdx)];
%         startIdx = endIdx + 1;
%     end
%     
%     % Add the last group
%     groupedRanges = [groupedRanges; numbers(startIdx), numbers(end)];



blink_inds=find(isnan(the_areas)==1);