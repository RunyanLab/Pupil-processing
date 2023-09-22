function [blinks_data_positions,blink_inds,corrected_areas] = noise_blinks_v4(the_areas,sampling_rate_in_hz,blink_threshold)
%blinks_data_positions=[];
    sampling_interval     = round(1000/sampling_rate_in_hz); % compute the sampling time interval in milliseconds.
    gap_interval          = 100;   % set the interval between two sets that appear consecutively for concatenation.
   % blink_inds=find(isoutlier(diff(blink_cut),'mean')==1);%can also add another conditional of needing to see a monotonic increase
    deriv_pup=diff(the_areas);
    blink_indsup=find(deriv_pup>=blink_threshold); %orginally 0.1
    blink_indslow=find(deriv_pup<=-blink_threshold);

    blink_inds=union(blink_indsup,blink_indslow);
    
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

