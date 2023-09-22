function [num_tifs]=findframes_nf(base_path_tseries)
imaging_dir=dir([base_path_tseries '\' '*TSeries*']);
for i=1:length(imaging_dir)
%     num_tifs(i)=length(dir([imaging_base_path imaging_dir(i).name '/*.tif']))/2;
    num_tifs(i)=length(dir([base_path_tseries '\' imaging_dir(i).name '/*Ch2*.ome*'])); %%%to do: this is slow
end
%     cd(base_path_tseries);
%     files=dir(base_path_tseries);
%     blocks=0;
%     for i=1:length(files)
%         if contains(files(i).name,'TSeries')
%             tifnum=0;
%             blocks=blocks+1;
%             tifs=dir([base_path_tseries '\' files(i).name]);
%             for n=1:length(tifs)
%                 if contains(tifs(n).name,'Ch2')
%                     tifnum=tifnum+1;
%                 end
%             end
%             framesperblock(blocks)=tifnum;
%         end
%     end

end    