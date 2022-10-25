function [the_radii_cut,center_row_cut, center_column_cut,first_index,last_index]=chop_to_laser(raw_radii,obj,center_column, center_row)

raw_radii(raw_radii<10)=0;
first_index = find(raw_radii,1,'first'); %2p acquisition onset
last_index = find(raw_radii,1,'last'); %2p offset


figure(1);clf
imshow(read(obj,first_index))
title(strcat('Frame #',num2str(first_index)))
correct_start=input('Does this look like the correct start frame? 1/0');

if correct_start==0
    start=input('What is the correct galvo start frame?');
    first_index = start;
end


figure(1);clf
imshow(read(obj,last_index))
title(strcat('Frame #',num2str(last_index)))
correct_end=input('Does this look like the correct end frame? 1/0');

if correct_end==0
    last=input('What is the correct galvo end frame?');
    last_index = last;
end


the_radii_cut = raw_radii(first_index:last_index);
center_row_cut = center_row(first_index:last_index);
center_column_cut = center_column(first_index:last_index);
