function [the_radii_cut,center_row_cut, center_column_cut,first_index,last_index]=chop_to_laser(raw_radii,obj,center_column, center_row)

raw_radii(raw_radii<10)=0;
first_index = find(raw_radii,1,'first'); %2p acquisition onset
last_index = find(raw_radii,1,'last'); %2p offset


figure(1);clf
% imshow(read(obj,first_index))
% title(strcat('Frame #',num2str(first_index)))
%figure(); 
if first_index>=3
    for i=1:3 % plot first index frame and the two frames before it
        subplot(1,3,i);
        imshow(read(obj,first_index-(i-1)));
        title(strcat('Frame #',num2str(first_index-(i-1))));
    end
else
    imshow(read(obj,first_index))
    title(strcat('Frame #', num2str(first_index)));
end
correct_start=input(strcat('Does this frame',num2str(first_index),' look like the correct start frame? 1/0'));

if correct_start==0
    start=input('What is the correct galvo start frame?');
    first_index = start;
end


figure(1);clf
% imshow(read(obj,last_index))
% title(strcat('Frame #',num2str(last_index)))
if last_index<=(length(raw_radii)-3)
    for i=1:3 % plot first index frame and the two frames before it
        subplot(1,3,i);
        imshow(read(obj,last_index+(i-1)));
        title(strcat('Frame #',num2str(last_index+(i-1))));
    end
else
    imshow(read(obj,last_index));
    title(strcat('Frame #',num2str(last_index)));
end
correct_end=input(strcat('Does this frame',num2str(last_index),' look like the correct end frame? 1/0'));

if correct_end==0
    last=input('What is the correct galvo end frame?');
    last_index = last;
end


the_radii_cut = raw_radii(first_index:last_index);
center_row_cut = center_row(first_index:last_index);
center_column_cut = center_column(first_index:last_index);
