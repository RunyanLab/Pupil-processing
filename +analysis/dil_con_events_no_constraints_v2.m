function [Cpts,Dpts,dEvents,dDuration,dMagnitude,cEvents,cDuration,cMagnitude,AVG_cDuration,AVG_dDuration,AVG_dMagnitude,...
        AVG_cMagnitude,new_Cpts,new_Dpts,ff]=dil_con_events_no_constraints_v2(pupil,blockTransitions)


fc=1;
fs=30;
time = linspace(0.0333,length(pupil)/fs,length(pupil));

[b,a]=butter(4,fc/(fs/2));
ff=filtfilt(b,a,pupil);

for i=1:length(blockTransitions)-1
   pupil(blockTransitions(i)-30:blockTransitions(i)+30) = NaN;
   ff(blockTransitions(i)-30:blockTransitions(i)+30) = NaN;
end

mins=islocalmin(ff);
maxs=islocalmax(ff);


figure(1);
clf
plot(time,ff,time(maxs),ff(maxs),'r*',time(mins),ff(mins),'k*')

Cpts=find(mins==1); %Cpts = mins [pts that start constrictin)
Dpts=find(maxs==1);%Dpts = mins (pts that start dilation)
if length(Dpts)>length(Cpts)
   Dpts(1)=[];
elseif length(Cpts)>length(Dpts)
    Cpts(1)=[];
end

%%%Scenario 1: first pt is a min, there will be 1 greater dilation event than
%there wil be constriction events - for dilation events, start corresponds
%with Dpt(i), end corresponds with Cpts(i); for constriction events, start
%corresponds with Cpts(i), end corresponds with Dpt (i+1)
if Dpts(1)<Cpts(1)
    type = 1; 
    
    %create initial dilation and constriciton events
    cEvents=cell(2,length(Dpts));
    dEvents=cell(2,length(Cpts)-1);
    for i=1:length(Dpts)
        cEvents{1,i}=ff(Dpts(i):Cpts(i));
        cEvents{2,i}=Dpts(i):Cpts(i);
    end
    for i=1:length(Dpts)-1
        dEvents{1,i}=ff(Cpts(i):Dpts(i+1));
        dEvents{2,i}=Cpts(i):Dpts(i+1);
    end
    
    %DURATION
    dDuration=(cellfun(@length,dEvents(2,:)))./30;
    cDuration=(cellfun(@length,cEvents(2,:)))./30;
    
    %MAGNITUDE
    dMagnitude = zeros(1,length(dEvents));
    %avgDm=mean(dMagnitude);
    cMagnitude = zeros(1,length(cEvents));
    %avgCm=mean(cMagnitude);
    
    fun = @(m)diff(m,1,2);
    dMagnitude =abs(cellfun(@mean, cellfun(fun,dEvents(1,:),'uni',0)));
    cMagnitude = abs(cellfun(@mean, cellfun(fun,cEvents(1,:),'uni',0)));
    
   
    
    elseif Dpts(1)>Cpts(1)
    type = 2; 
    cEvents=cell(2,length(Dpts)-1);
    dEvents=cell(2,length(Cpts));
    for i=1:length(Dpts)
        dEvents{1,i}=ff(Cpts(i):Dpts(i));
        dEvents{2,i}=Cpts(i):Dpts(i);
    end
    for i=1:length(Dpts)-1
        cEvents{1,i}=ff(Dpts(i):Cpts(i+1));
        cEvents{2,i}=Dpts(i):Cpts(i+1);
    end

    %DURATIONS
    dDuration=(cellfun(@length,dEvents(2,:)))./30;
    cDuration=(cellfun(@length,cEvents(2,:)))./30;
   
    dMagnitude = zeros(1,length(dEvents));
    cMagnitude = zeros(1,length(cEvents));
    
    fun = @(m)diff(m,1,2);
    dMagnitude =abs(cellfun(@mean, cellfun(fun,dEvents(1,:),'uni',0)));
    cMagnitude = abs(cellfun(@mean, cellfun(fun,cEvents(1,:),'uni',0)));
 
end

   



    dhasTrans=[];
for i=1: length(dEvents) 
    TF=any(isnan(dEvents{1,i}));
    if TF==1
        dhasTrans=[dhasTrans i];
    end
end

dEvents(:,dhasTrans) = [];
dMagnitude(:,dhasTrans) = [];
dDuration(:,dhasTrans) = [];


chasTrans = [];
for i=1: length(cEvents) 
    TF=any(isnan(cEvents{1,i}));
    if TF==1
        chasTrans=[chasTrans i];
    end
end
cEvents(:,chasTrans) = [];
cMagnitude(:,chasTrans) = [];
cDuration(:,chasTrans) = [];

% 
figure(15);
clf
plot(time,ff,time(Dpts),ff(Dpts),'r*',time(Cpts),ff(Cpts),'k*')


 
 
  edges = 0:.5:31;
   AVG_dDuration=mean(dDuration);
   AVG_cDuration=mean(cDuration);
   AVG_dMagnitude=mean(dMagnitude);
   AVG_cMagnitude=mean(cMagnitude);
   
   
   
  new_Cpts=cellfun(@(v)v(1),dEvents);
  new_Dpts=cellfun(@(v)v(end),dEvents); 

     
    %mak a new dMagnitude that is just dpt-cpt
%     new_dMagnitude=new_Dpts(1,:)-new_Cpts(1,:);
    

  
  
  figure(13)
  clf
  plot(time,ff,time(new_Dpts(2,:)),ff(new_Dpts(2,:)),'r*',time(new_Cpts(2,:)),ff(new_Cpts(2,:)),'k*')
  
  
  
  
     %make constraint threshold events with magnitude greater than 0.7 - i
     %use this for my data but didn't do it for christine's
% for i = 1:length(new_dMagnitude)
%     if new_dMagnitude(i)<0.4
%         new_dMagnitude(i)=NaN;
%         new_Cpts(1,i)=NaN;
%         new_Dpts(1,i)=NaN;
%     end
% end
%     delete_inds=isnan(new_dMagnitude);
%     new_dMagnitude(isnan(new_dMagnitude))=[];
%     new_Cpts(:,delete_inds==1)=[];
%     new_Dpts(:,delete_inds==1)=[];
%     
%     
%     figure(1000)
%     clf
%     
%  plot(time,ff,time(new_Dpts(2,:)),ff(new_Dpts(2,:)),'r*',time(new_Cpts(2,:)),ff(new_Cpts(2,:)),'k*')      
% 

 
  
% This was my attempt at smoothing over only those parts of the trace where the derivative between timepoints was less than some threshold - my own form of highpass filtering but the for loop takes forever to run    
%   n=1;
%   temp_vect=1;
%   for i = 2:length(lp)
%       if lp(i)==lp(i-1)+1
%         temp_vect=[temp_vect lp(i)];
%         splitvectors{n}= temp_vect;
%       else 
%         n=n+1;
%         temp_vect=[];
%         temp_vect=[temp_vect lp(i)];
%       end
%   end
%   
%  for n = 1:length(splitvectors)
%      if length(splitvectors{n})>30
%          temp_pupil=pupil(splitvectors{n});
%          splitpupil{n}=smooth(temp_pupil,30,'gauss');
%      end
%  end
%  
%  pupil_new = [];
%  for n = 1:length(splitvectors)
%      for i=1:length(pupil)
%          if ~isempty(find(splitvectors{n} ==i))
%              pupil_new=[pupil_new splitpupil{n}(find(splitvectors{n} ==i))];
%          else
%              pupil_new=[pupil_new pupil(i)];
%          end
%      end
%  end

 
%              
%  
%    pupil_new = [];
%  for i = 1:length(pupil)
%      for n=1:length(splitvectors)
%          if ~isempty(find(splitvectors{n} ==i))
%              pupil_new=[pupil_new splitpupil{n}(find(splitvectors{n} ==i))];
%          else
%              pupil_new=[pupil_new pupil(i)];
%          end
%      end
%  end
%  
  


  
    
        
  
%      figure(18)
%   clf
%   subplot(2,1,1);
% histogram(dDuration,edges)
% %line([AVG_dDuration AVG_dDuration], get(gca, 'ylim'));
% title('dilations')
% subplot(2,1,2)
% histogram(cDuration,edges)
% %line([AVG_cDuration AVG_cDuration], get(gca, 'ylim'));
% title('constrictions')
% xlabel('time(s)')
% ylabel('#events')
% 
% figure(19)
% clf
% edges = 0:0.00005:0.0035;
%   subplot(2,1,1);
% histogram(dMagnitude,edges)
% line([AVG_dMagnitude AVG_dMagnitude], get(gca, 'ylim'));
% title('dilations')
% subplot(2,1,2)
% histogram(cMagnitude,edges)
% line([AVG_cMagnitude AVG_cMagnitude], get(gca, 'ylim'));
% title('constrictions')
% xlabel('average change across event')
% ylabel('#events')
 
