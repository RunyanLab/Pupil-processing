function [framesperblock]=findframes_nf(base_path_tseries)
    %base=['\\runyan-fs-01\Runyan3\Christine\images\' mouse '\' strcat(year,day) '\pass\'];
    %base=['\\runyan-fs-01\Runyan\Christine\images\' mouse '\',strcat(year,day),'\pass\'];
    cd(base_path_tseries);
    files=dir(base_path_tseries);
    blocks=0;
    for i=1:length(files)
        if contains(files(i).name,'TSeries')
            tifnum=0;
            blocks=blocks+1;
            tifs=dir([base_path_tseries files(i).name]);
            for n=1:length(tifs)
                if contains(tifs(n).name,'Ch2')
                    tifnum=tifnum+1;
                end
            end
            framesperblock(blocks)=tifnum;
        end
    end
%    %base=['\\runyan-fs-01\Runyan3\Christine\images\' mouse '\' strcat(year,day) '\spont\'];
%    base=['\\runyan-fs-01\Runyan\Christine\images\' mouse '\',strcat(year,day),'\spont\'];
%     cd(base);
%     files=dir(base);
%     blocks=0;
%     for i=1:length(files)
%         if contains(files(i).name,'TSeries')
%             tifnum=0;
%             blocks=blocks+1;
%             tifs=dir([base files(i).name]);
%             for n=1:length(tifs)
%                 if contains(tifs(n).name,'Ch2')
%                     tifnum=tifnum+1;
%                 end
%             end
%             framesperblockspont(blocks)=tifnum;
%         end
%     end
end    