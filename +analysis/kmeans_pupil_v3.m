function [clusterlow,clusterhigh,transitionSmall,transitionLarge,classificationSmallTrans,...
        classificationLargeTrans,classificationNoTrans,C]=kmeans_pupil_v3(pup_norm)

%load(strcat(tot_file_save_path,'\',mouse,'_',num2str(date)),'pup_norm_10');

%for i=1:length(totBlockTransitions)-1
 %   totnorm(totBlockTransitions(i)-30:totBlockTransitions(i)+30) = NaN;
%end
%make sure that this works - that kmeanns funcition can handle nans in it - shouldn't actually need to do this - bc its just 2 pts  

pup_norm = pup_norm';
[classificationNoTrans,C]=kmeans(pup_norm,2,'Distance','cityblock');
pup_norm=pup_norm';
classificationNoTrans=classificationNoTrans';


clear clusterlow
clear clusterhigh

% [classification3Clusters,C]=kmeans(totnorm,3,'Distance','cityblock');
% totnorm=totnorm';

[val,idx]=min(C);
if idx==2
    clusterlow(1,:)=pup_norm(classificationNoTrans==2);
    clusterlow(2,:)=find(classificationNoTrans==2);
    clusterhigh(1,:)=pup_norm(classificationNoTrans==1);
    clusterhigh(2,:)=find(classificationNoTrans==1);
else
    clusterlow(1,:)=pup_norm(classificationNoTrans==1);
    clusterlow(2,:)=find(classificationNoTrans==1);
    clusterhigh(1,:)=pup_norm(classificationNoTrans==2);
    clusterhigh(2,:)=find(classificationNoTrans==2);
end

C=sort(C);
classificationNoTrans(clusterlow(2,:))=1;
classificationNoTrans(clusterhigh(2,:))=3;





dC1=abs(pup_norm - C(1,1));
dC2=abs(pup_norm - C(2,1));
dCs=abs(dC1-dC2);

transitionSmall = find(dCs<0.05); %test altering this value
transitionLarge = find(dCs<0.2);
classificationSmallTrans = classificationNoTrans;
classificationLargeTrans = classificationNoTrans;
classificationSmallTrans(transitionSmall)=2;
classificationLargeTrans(transitionLarge)=2;


edges=-.8:.03:.8;
figure(1);
clf
hold on; 
histogram(clusterlow(1,:),edges,'facecolor',[0, 0.4470, 0.7410]);
plot(C(1),2750,'-o','color',[0, 0.4470, 0.7410]);
histogram(clusterhigh(1,:),edges,'facecolor',[0.9290, 0.6940, 0.1250]);
plot(C(2),2750,'-o','color',[0.9290, 0.6940, 0.1250]);
histogram(pup_norm(transitionLarge),edges,'facecolor',[0.4660 0.6740 0.1880]);
xlabel('normalized pupil');
ylabel('frames')
%saveas(gca,'
%set(gca,'fontsize',18);

figure(2);
clf
hold on; 
plot(clusterlow(2,:),clusterlow(1,:),'.','color',[0, 0.4470, 0.7410])
plot(clusterhigh(2,:),clusterhigh(1,:),'.','color',[0.9290, 0.6940, 0.1250])
plot(transitionLarge,pup_norm(transitionLarge),'.','color',[0.4660 0.6740 0.1880])
xlabel('frames');
ylabel('Pupil area (normalized values)')
%saveas(gca,'
%set(gca,'fontsize',18);

