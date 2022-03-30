function blinks_data_positions = noise_blinks_v3(the_areas,sampling_rate_in_hz,blink_threshold)
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
    smooth_data    = smooth(the_areas, samples2smooth);    

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
    
end
