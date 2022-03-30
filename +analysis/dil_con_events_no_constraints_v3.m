function [newcpts]=dil_con_events_no_constraints_v3(pupil,blockTransitions)
%going off of what christine did in the som paper
%the output is all the pupil dilation event onset indicies
%used for pupil triggered response vs opto triggered response code 

% 
% fc=1;
% fs=30;
% time = linspace(0.0333,length(pupil)/fs,length(pupil));
% 
% [b,a]=butter(4,fc/(fs/2));
% ff=filtfilt(b,a,pupil);

for i=1:length(blockTransitions)-1
   pupil(blockTransitions(i)-30:blockTransitions(i)+30) = NaN;
%    ff(blockTransitions(i)-30:blockTransitions(i)+30) = NaN;
end

[pks,locs]=findpeaks(pupil);

% 
% mins=islocalmin(pupil);
% maxs=islocalmax(pupil);


figure(1);
clf
plot(pupil)
hold on 
plot(locs,pks,'ro');

cpts=[];
for i = 1:length(locs)
    cpts=[cpts find(diff(pupil(1:locs(i)))<0,1,'last')];
end

%include if the change from inflection point to max point is at least 40%
%and less than 1s between the two 
    %she also adds criterion that the max point is at least 50% of the
    %maximum total area by the pupil during that imaging session (will try
    %to do it without this first)
    
%if the first point is a cpts
percentIncrease = (pks-pupil(cpts))./ abs(pupil(cpts))*100; 
newpks = pks(percentIncrease>=60);
newlocs=locs(percentIncrease>=60);
newcpts=cpts(percentIncrease>=60);

timeBetween = newlocs-newcpts;
newpks = newpks(timeBetween>=30);
newlocs=newlocs(timeBetween>=30);
newcpts=newcpts(timeBetween>=30);


   
percentDecrease = (pupil(newcpts(2:end))-newpks(1:end-1))./abs(newpks(1:end-1))*(-100); %probs dont need this could just do by magnitude
timeBetween = newcpts(2:end)-newlocs(1:end-1);

newpks=newpks(percentDecrease>=60 & timeBetween>=30);
newlocs=newlocs(percentDecrease>=60 & timeBetween>=30);
newcpts=newcpts(find(percentDecrease>=60 & timeBetween>=30)+1);

%now the first pt is a dpt
%magDecrease = newpks(1:end-1) - pupil(newcpts(2:end));
magDecrease = newpks -pupil(newcpts);

newpks=newpks(magDecrease>=.1);
newlocs=newlocs(magDecrease>=.1);
newcpts=newcpts(magDecrease>=.1);
           

% figure()
% clf
% plot(pupil)
% hold on 
% plot(newcpts,pupil(newcpts),'ok')
% plot(newlocs,newpks,'or')

dEvents = cell(2,length(newcpts));
for i =1:length(newcpts)-1
    dEvents{1,i}=newcpts(i):newlocs(i+1);
    dEvents{2,i}=pupil(newcpts(i):newlocs(i+1));
end


 dhasTrans=[];
for i=1: length(dEvents) 
    if any(isnan(dEvents{2,i}))
        dhasTrans=[dhasTrans i];
    end
end

newcpts(dhasTrans) = [];
newlocs(dhasTrans+1)=[];
newpks(dhasTrans+1)=[];

dEvents(:,dhasTrans) = [];



figure()
clf
plot(pupil)
hold on 
plot(newcpts,pupil(newcpts),'ok')
plot(newlocs,newpks,'or')



% might need to do this with the scenario that the first point is a cpt
% differently  (adapt it when you encounter it)


    



