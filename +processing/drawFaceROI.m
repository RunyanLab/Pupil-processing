function [faceMask] = drawFaceROI(the_example_image)

rows = size(the_example_image,1);
columns = size(the_example_image,2);

figure()
imshow(the_example_image)
title('Select Face Region')
hold on 
face = drawrectangle;
pause;

faceMask = poly2mask(face.Vertices(:,1), face.Vertices(:,2) , rows, columns);