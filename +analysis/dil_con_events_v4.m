function [dilation_starts_new]=dil_con_events_v4(pupil,blockTransitions,aligned_pupil_unsmoothed)
%going off of what christine did in the som paper
%the output is all the pupil dilation event onset indicies
%used for pupil triggered response vs opto triggered response code 

smoothed_300=utils.smooth(aligned_pupil_unsmoothed,300,'gauss');

for i=1:length(blockTransitions)-1
   pupil(blockTransitions(i)-30:blockTransitions(i)+30) = NaN;
end

%[pks,locs] = findpeaks(pupil*-1,'MinPeakProminence',.1) ;

[pks,locs,] = findpeaks(pupil,'MinPeakProminence',100) ;
%[pks,locs]=findpeaks(pupil*-1);


dilation_starts=[];
for i = 1:length(locs)
    dilation_starts = [dilation_starts find(diff(pupil(1:locs(i)))<0,1,'last')];
end

figure()
hold on 
plot(pupil)
plot(dilation_starts,pupil(dilation_starts),'ok')
title('prominence only,first inflection point')

for i = 1:length(dilation_starts)
    [~,prev_loc] = findpeaks(pupil(1:dilation_starts(i)));
    prev_loc =prev_loc(end);
    prev_inflection=find(diff(pupil(1:prev_loc))<0,1,'last');
    

%     figure(1);clf;hold on
%     plot(pupil)
%     xline(dilation_starts(i))
%     xline(prev_inflection,'r')

    if smoothed_300(dilation_starts(i))-smoothed_300(prev_inflection)>0 
        dilation_starts_new(i)=prev_inflection;
    else 
        dilation_starts_new(i)=dilation_starts(i);
    end
    if dilation_starts_new(i)~=dilation_starts(i)

        figure(1);clf;hold on
        plot(pupil)
        plot(dilation_starts_new(i),pupil(dilation_starts_new(i)),'or')
        plot(dilation_starts(i),pupil(dilation_starts(i)),'ok')

        satisfied=input('Are you satisified with this starting point? 0/1/2      ');
        if satisfied==0
            dilation_starts_new(i)=input('Type correction dilation start frame    ');
        elseif satisfied ==2
            dilation_starts_new(i)=dilation_starts(i);
        end
    end


end




figure()
hold on 
plot(pupil)
plot(dilation_starts_new,pupil(dilation_starts_new),'ok')
%plot(dilation_starts,pupil(dilation_starts),'or')
title('prominence only, correction to inflections')




high_pt= locs;
low_pt = dilation_starts_new;

percentIncrease = (pks-pupil(low_pt))./ abs(pupil(low_pt))*100; 
new_high_pts = high_pt(percentIncrease>=40);
new_low_pts =low_pt(percentIncrease>=40);

timeBetween = new_high_pts-new_low_pts;
new_high_pts=new_high_pts(timeBetween>=30);
new_low_pts=new_low_pts(timeBetween>=30);




figure();hold on 
plot(pupil)
plot(new_low_pts,pupil(new_low_pts),'ok')
title('prominence + percent increase constraint')





    



