function concatenate_contexts(mouse,date,tot_file_save_path,save_path_pass,save_path_spont)

%tot_file_save_loc = strcat('\\runyan-fs-01\Runyan3\Noelle\Pupil\Christine Pupil\processed\total',mouse);
%tot_file_save_loc = strcat('\\runyan-fs-01\Runyan\Noelle\reprocessed data\total',mouse);%edit to match directory where you want your concatenated file to be saved
%passcd = strcat('\\runyan-fs-01\Runyan3\Noelle\Pupil\Christine Pupil\processed\pass\',mouse);
%passcd = strcat('\\runyan-fs-01\Runyan\Noelle\reprocessed data\pass\',mouse);%edit to match directory where your passive context files are saved
passcd=save_path_pass;
cd(passcd);
passTF = isfile(strcat(mouse,'_',num2str(date),'.mat'));
%spontcd = strcat('\\runyan-fs-01\Runyan3\Noelle\Pupil\Christine Pupil\processed\spont\',mouse);
%spontcd = strcat('\\runyan-fs-01\Runyan\Noelle\reprocessed data\spont\',mouse);%edit to match directory where you spontaneous context files are saved
spontcd=save_path_spont;
cd(spontcd);
spontTF = isfile(strcat(mouse,'_',num2str(date),'.mat'));
if passTF==1 && spontTF==1
    load(strcat(passcd,'\',mouse,'_',num2str(date)));
    pup_pass_30 = aligned_pupil_smoothed_30;
    pup_pass_10 = aligned_pupil_smoothed_10;
    pup_not_smoothed_pass = aligned_pupil_unsmoothed;
    x_velocity_pass = x_velocity;
    y_velocity_pass = y_velocity;
    %position_pass = position_stretched;
    xpos_pass = aligned_x_position;
    ypos_pass = aligned_y_position;
    loco_sum_pass = loco_sum;
    loco_sum_smoothed_pass = loco_sum_smooth;
    blockTransitions_pass = blockTransitions;
    
    load(strcat(spontcd,'\',mouse,'_',num2str(date)));
    pup_spont = aligned_pupil_smoothed_30;
    pup_spont_10 = aligned_pupil_smoothed_10;
    pup_not_smoothed_spont = aligned_pupil_unsmoothed;
    x_velocity_spont = x_velocity;
    y_velocity_spont = y_velocity;
    %position_spont = position_stretched;
    xpos_spont = aligned_x_position;
    ypos_spont = aligned_y_position;
    loco_sum_spont = loco_sum;
    loco_sum_smoothed_spont =loco_sum_smooth;
    blockTransitions_spont = blockTransitions;

 clear aligned_pupil_smoothed_30 aligned_pupil_smoothed_10 aligned_pupil_unsmoothed x_velocity y_velocity aligned_x_position aligned_y_position loco_sum loco_sum_smooth blockTransitions
   
    aligned_pupil_smoothed_30=horzcat(pup_pass,pup_spont);
    aligned_pupil_smoothed_10=horzcat(pup_pass_10,pup_pass_10);
    aligned_pupil_unsmoothed=horzcat(pup_not_smoothed_pass,pup_not_smoothed_spont);
    x_velocity=horzcat(x_velocity_pass,x_velocity_spont);
    y_velocity =  horzcat(y_velocity_pass,y_velocity_spont);
    %totPos = horzcat(position_pass,position_spont);
    aligned_x_position = horzcat(xpos_pass,xpos_spont);
    aligned_y_position = horzcat(ypos_pass,ypos_spont);
    loco_sum = horzcat(loco_sum_pass,loco_sum_spont);
    loco_sum_smooth = horzcat(loco_sum_smoothed_pass,loco_sum_smoothed_spont);
    blockTransitions_spont = blockTransitions_spont+blockTransitions_pass(end);
    blockTransitions = horzcat(blockTransitions_pass, blockTransitions_spont);
    
    %if length(find(isnan(totPup)))>0
     %   nanx = isnan(totPup);
      %  t    = 1:numel(totPup);
       % totPup(nanx) = interp1(t(~nanx), totPup(~nanx), t(nanx));
    %end
    
    %m=mean(totPup);
    %totnorm=(totPup-m)/m; 
    
pup_norm_30 =(aligned_pupil_smoothed_30-mean(aligned_pupil_smoothed_30))/mean(aligned_pupil_smoothed_30);
pup_norm_10 =(aligned_pupil_smoothed_10-mean(aligned_pupil_smoothed_10))/mean(aligned_pupil_smoothed_10);
pup_norm_unsmoothed =(aligned_pupil_unsmoothed-mean(aligned_pupil_unsmoothed))/mean(aligned_pupil_unsmoothed);
    
    %save(strcat('\\runyan-fs-01\Runyan3\Noelle\Pupil\Christine Pupil\processed\total\',mouse,'\',mouse,'_',num2str(day),'.mat'),'totPup','totnorm','totXvel','totYvel','totLocosummedSmooth','totLocosummed','totPos','totBlockTransitions')  
   %save(strcat('\\runyan-fs-01\Runyan\Noelle\reprocessed data\total\',mouse,'\',mouse,'_',num2str(day),'.mat'),'totPup','totnorm','totXvel','totYvel','totLocosummedSmooth','totLocosummed','totxPos','totyPos','totBlockTransitions')  
   %save(strcat(save_path,'\',mouse,'_',num2str(date),'_allconexts.mat'),'totPup','totnorm','totXvel','totYvel','totLocosummedSmooth','totLocosummed','totxPos','totyPos','totBlockTransitions')
    save(strcat(tot_file_save_path,'\',mouse,'_',num2str(date),'_allcontexts.mat'),'aligned_pupil_unsmoothed','aligned_pupil_smoothed_10','aligned_pupil_smoothed_30','aligned_x_position','aligned_y_position','pup_norm_30','pup_norm_10','pup_norm_unsmoothed''x_velocity','y_velocity','loco_sum','loco_sum_smooth','blockTransitions');
else
    warning('Warning: Files for both contexts do not exist, contatenation skipped')
end

end