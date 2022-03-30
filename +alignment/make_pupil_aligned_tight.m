function [pupil_all,aligned_pupil_unsmoothed, aligned_pupil_smoothed_10, aligned_pupil_smoothed_30, aligned_x_position, aligned_y_position] = make_pupil_aligned_tight(base_path,save_path,save_path_pass,save_path_spont,base_path_wav,blocks,cont,pupil_all)
tf_cont= strcmp(cont,'none');
tf_which_cont = strcmp(cont,'pass'); 

   cd(base_path_wav) 
   %cd('\\runyan-fs-01\runyan2\Caroline\2P\SOM_VIP\wavesurfer\2021-03-16\New folder\'); %add cont this path if nec
    z=dir('*.h5');
%real_blocks = blocks;
%real_block=0;
position_block=0;
for block=blocks 
    position_block = position_block+1;
   %cd(strcat('\\runyan-fs-01\runyan2\Caroline\2P\SOM_VIP\wavesurfer\',num2str(date),'\',mouse));


    if block<10 
        for i=1:length(z)
            if contains(z(i).name,strcat('_000',num2str(block),'.h5'))==1
                hh=h5read(z(i).name,strcat('/sweep_000',num2str(block),'/analogScans'));
            end
        end
    else
        for i = 1:length(z)
            if contains(z(i).name,strcat('_00',num2str(block),'.h5'))==1
                hh=h5read(z(i).name,strcat('/sweep_00',num2str(block),'/analogScans'));
            end
        end
    end
    
    hh=hh';
    hh=double(hh);
    rawGalvo=hh(1,:);
    rawPupil = hh(5,:);
    
    minval = min(rawGalvo);
    tallpeaks = rawGalvo > 10000; %may need to change this value each time 
    rawGalvo(tallpeaks)=minval;
    [galvo_peak, galvo_temp]=findpeaks(rawGalvo,'minpeakheight',1000);%was 1000
    %instead of increaseing this threshold could set some constraint like
    %it must be greater than x wav units away from the next peak - becuase
    %the peak size seems to be variable and i could see some cases where
    galvo_peak(diff(galvo_temp)<30) = [];
    galvo_temp(diff(galvo_temp)<30) = [];
    
    
   
    %real frames fall below the threshold
    galvo_peak = galvo_peak(1:round(length(galvo_peak),-2));
    galvo_temp = galvo_temp(1:round(length(galvo_temp),-2));
    
    rawPupil(rawPupil>10000)=8000;
    
    
    [high_op,cam_op] = findpeaks(diff(rawPupil),'minpeakheight',4060); %positive polarity (up = frame start)
    [high_cl,cam_cl] = findpeaks((-1*diff(rawPupil)),'minpeakheight',4060);%old val = 4060
    figure(90)
    clf
    hold on 
    plot(diff(rawPupil))
    plot(cam_op,high_op,'*r')
    figure(91)
    clf
    hold on 
    plot(-1*diff(rawPupil))
    plot(cam_cl,high_cl,'*k')
    
  
    framecnt = max(length(cam_op),length(cam_cl));
  
    pupil_temp = zeros(framecnt,80);
    if length(cam_op)>length(cam_cl) 
        for i = 1:length(cam_op)-1
            pupil_temp(i,1:cam_cl(i)-cam_op(i)+1) = cam_op(i):cam_cl(i);
        end
        pupil_temp(i+1,1:length(rawPupil)-cam_op(end)+1)=cam_op(end):length(rawPupil);
    else
        for i = 1:length(cam_op) 
            pupil_temp(i,1:cam_cl(i)-cam_op(i)+1)=cam_op(i):cam_cl(i);
        end
    end
    
    
    
    ExactPupFrame=[];
    
%    if block <10
%     load(strcat('\\runyan-fs-01\runyan2\Caroline\2P\SOM_VIP\pupil\2021-03-16\CU11R\CU11R_000',num2str(block),'.mat'),'pupil');
%    else 
%     load(strcat('\\runyan-fs-01\runyan2\Caroline\2P\SOM_VIP\pupil\2021-03-16\CU11R\CU11R_00',num2str(block),'.mat'),'pupil');
%    end
    %load('\\runyan-fs-01\runyan2\Caroline\2P\SOM_VIP\pupil\2021-03-16\CU11R\CU11R_0004.mat','pupil');
  %  if block<10 
   %     load(strcat(base_path,'\',num2str(mouse),'_000',block,'.mat'),'pupil');
    %else 
   %     load(strcat(base_path,'\',num2str(mouse),'_00',block,'.mat'),'pupil');
    %end
    
    
   
   loadingframes = (framecnt-length(pupil_all{position_block}.radii.uncut_uncorrected_radii)-1);
   %loadingframes = (framecnt-length(pupil_all{position_block}.radii.uncut_uncorrected_radii));
   rel_first_frame = pupil_all{position_block}.galvo_on + loadingframes;
   rel_last_frame = pupil_all{position_block}.galvo_off + loadingframes;
   
   
   

     %for i = 1:length(galvo_temp)
      %  [minval,~]= min(abs(pupil_temp'-galvo_temp(i)));
       % [~,frame]=min(minval);
        %ExactPupFrame = [ExactPupFrame frame];
     %end
    
    
    %assigning to the pupil frame that has already happened
    for i = 1:length(galvo_temp) %for every galvo frame fine the closest pupil frame
       [minval,~]= min(abs(pupil_temp'-galvo_temp(i))); 
       if min(minval)>0 %if the min isnt 0 the galvo frame happens between pupil frames
           [~,frame]=min(minval);%ID of pupil frame closest to galvo frame
           if i ==1 %if we are on the first galvo frame
               if pupil_temp(frame,find(pupil_temp(frame,:),1,'last'))<galvo_temp(1) % if the closest pupil frame occurs before the first galvo frame
                   frame = frame+1;%assign the next pupil frame
                    ExactPupFrame = [ExactPupFrame frame];
               else 
                   ExactPupFrame = [ExactPupFrame frame];
               end
           elseif i == length(galvo_temp)%if we are on the last galvo frame
               if pupil_temp(frame,find(pupil_temp(frame,:),1,'last'))>galvo_temp(end)% if the closest pupil frame occurs after the last galvo frame
                   frame = frame-1;%assign the previous pupil frame
                   ExactPupFrame = [ExactPupFrame frame];
               else 
                  ExactPupFrame = [ExactPupFrame frame];
               end
           else %if we are on neither the first or last galvo frame 
               if pupil_temp(frame,find(pupil_temp(frame,:),1,'last'))>galvo_temp(i)%if the closest pupil frame occurs after the galvo frame
                   frame = ExactPupFrame(i-1);%assign the previous pupil frame
                   ExactPupFrame = [ExactPupFrame frame];
               else
                   ExactPupFrame = [ExactPupFrame frame];% otherwise assign the pupil frame nearest
               end
              
           end
       else 
          [~,frame]=min(minval);
          ExactPupFrame = [ExactPupFrame frame]; 
       end
    end
    
    if ExactPupFrame(1) ~= rel_first_frame
        ExactPupFrame(ExactPupFrame ==ExactPupFrame(1))=rel_first_frame;
    end
    if ExactPupFrame(end) ~= rel_last_frame
        ExactPupFrame(ExactPupFrame ==ExactPupFrame(end)) = rel_last_frame;
    end
    
    
    
    %assigning to the pupil frame that is nearest, regardless if it has
    %happened yet or not
      for i = 1:length(galvo_temp) %for every galvo frame fine the closest pupil frame
       [minval,~]= min(abs(pupil_temp'-galvo_temp(i))); 
       if min(minval)>0 %if the min isnt 0 the galvo frame happens between pupil frames
           [~,frame]=min(minval);%ID of pupil frame closest to galvo frame
           if i ==1 %if we are on the first galvo frame
               if pupil_temp(frame,find(pupil_temp(frame,:),1,'last'))<galvo_temp(1) % if the closest pupil frame occurs before the first galvo frame
                   frame = frame+1;%assign the next pupil frame
                    ExactPupFrame = [ExactPupFrame frame];
               else 
                   ExactPupFrame = [ExactPupFrame frame];
               end
           elseif i == length(galvo_temp)%if we are on the last galvo frame
               if pupil_temp(frame,find(pupil_temp(frame,:),1,'last'))>galvo_temp(end)% if the closest pupil frame occurs after the last galvo frame
                   frame = frame-1;%assign the previous pupil frame
                   ExactPupFrame = [ExactPupFrame frame];
               else 
                  ExactPupFrame = [ExactPupFrame frame];
               end
           else %if we are on neither the first or last galvo frame
                   ExactPupFrame = [ExactPupFrame frame];              
           end
       else 
          [~,frame]=min(minval);
          ExactPupFrame = [ExactPupFrame frame]; 
       end
      end
    
        
    
    RelPupFrame = ExactPupFrame - (ExactPupFrame(1)-1);
    
    if ~(max(RelPupFrame) == length(pupil_all{position_block}.area.corrected_areas))
        error('Error.\ Number of frames detected in wavesurfer does not match frames detected in movie')
    end
    
    
    aligned_pupil_unsmoothed =[];
    aligned_pupil_smoothed_10=[];
    aligned_pupil_smoothed_30=[];
    aligned_x_position=[];
    aligned_y_position=[];
    
%     FrameVal_unsmoothed = zeros(1,length(RelPupFrame));
%     FrameVal_smoothed_10 = zeros(1,length(RelPupFrame));
%     FrameVal_smoothed_30 = zeros(1,length(RelPupFrame));
%     CenterCol = zeros(1,length(RelPupFrame));
%     CenterRow = zeros(1,length(RelPupFrame));
    
    for i = 1:length(RelPupFrame)
        FrameVal_unsmoothed(i) = pupil_all{position_block}.area.corrected_areas(RelPupFrame(i));
        FrameVal_smoothed_10(i) = pupil_all{position_block}.area.smoothed_30_timeframes(RelPupFrame(i));
        FrameVal_smoothed_30(i) = pupil_all{position_block}.area.smoothed_10_timeframes(RelPupFrame(i));
        CenterCol(i) = pupil_all{position_block}.center_position.center_column(RelPupFrame(i));
        CenterRow(i) = pupil_all{position_block}.center_position.center_row(RelPupFrame(i)); 
    end
    
        aligned_pupil_unsmoothed=[aligned_pupil_unsmoothed FrameVal_unsmoothed];
        aligned_pupil_smoothed_10=[aligned_pupil_smoothed_10 FrameVal_smoothed_10];
        aligned_pupil_smoothed_30=[aligned_pupil_smoothed_30 FrameVal_smoothed_30];
        aligned_x_position = [aligned_x_position CenterCol];
        aligned_y_position = [aligned_y_position CenterRow];

    
    
    
    pupil_all{1,position_block}.alignment.galvo_temp = galvo_temp;
    pupil_all{1,position_block}.alignment.galvo_peaks = galvo_peak;
    pupil_all{1,position_block}.alignment.pupil_temp = pupil_temp;
    pupil_all{1,position_block}.alignment.MatchedFrameInds = RelPupFrame;
    pupil_all{1,position_block}.alignment.MatchedFrameValsUnsmoothed = FrameVal_unsmoothed;
    pupil_all{1,position_block}.alignment.MatchedFrameValsSmoothed10 = FrameVal_smoothed_10;
    pupil_all{1,position_block}.alignment.MatchedFrameValsSmoothed30 = FrameVal_smoothed_30;
 
    
    pause;

end

pup_norm_30 =(aligned_pupil_smoothed_30-mean(aligned_pupil_smoothed_30))/mean(aligned_pupil_smoothed_30);
pup_norm_10 =(aligned_pupil_smoothed_10-mean(aligned_pupil_smoothed_10))/mean(aligned_pupil_smoothed_10);
pup_norm_unsmoothed =(aligned_pupil_unsmoothed-mean(aligned_pupil_unsmoothed))/mean(aligned_pupil_unsmoothed);

[x_velocity,y_velocity] = make_v_inputs_nf_v2(base_path_wav,blocks);

if length(x_velocity)>length(aligned_pupil_unsmoothed)
    x_velocity=x_velocity(1:length(aligned_pupil_unsmoothed));
    y_velocity=y_velocity(1:length(aligned_pupil_unsmoothed));
end

x_abs = abs(x_velocity);
y_abs = abs(y_velocity);

loco_sum = x_abs.^2 +y_abs.^2;
loco_sum = sqrt(loco_sum);
 
loco_sum_smooth = smooth(loco_sum,100,'gaussian');
 
 
blockTransitions = [];
frames=0;
for i=1:length(framesperblock)
    frames = frames+framesperblock(1,i);
    blockTransitions(i) = frames;
end
    
    
if tf_cont==1
    which_save_path = save_path;
else
    if tf_which_cont ==1
        which_save_path = save_path_pass;
    else
        which_save_path = save_path_spont;
    end
end


presence = exist(which_save_path, 'dir');
    
if presence==7
    save(strcat(which_save_path,'\',mouse,'_', num2str(day),'.mat'),'pupil_all','aligned_pupil_unsmoothed','aligned_pupil_smoothed_10','aligned_pupil_smoothed_30','aligned_x_position','aligned_y_position','pup_norm_30','pup_norm_10','pup_norm_unsmoothed','x_velocity','y_velocity','loco_sum','loco_sum_smooth','blockTransitions');
elseif presence==0
    %cd(strcat('\\runyan-fs-01\Runyan\Noelle\reprocessed data\',cont,'\'));
    mkdir which_save_path;
    movefile which_save_path 
    save(strcat(which_save_path,'\',mouse,'_', num2str(day),'_',cont,'.mat'),'pupil_all','aligned_pupil_unsmoothed','aligned_pupil_smoothed_10','aligned_pupil_smoothed_30','aligned_x_position','aligned_y_position','pup_norm_30','pup_norm_10','pup_norm_unsmoothed''x_velocity','y_velocity','loco_sum','loco_sum_smooth','blockTransitions');
end

end