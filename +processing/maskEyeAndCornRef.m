function [eyeMask,cornMask,additional_cornMask,the_example_image]=maskEyeAndCornRef(d,file_id,frame_id)

    exp_obj = VideoReader(d(file_id).name);
    the_example_image = read(exp_obj,frame_id);
    rows = size(the_example_image,1);
    columns = size(the_example_image,2);
    
    figure()
    imshow(the_example_image)
    title('Draw Eye ROI')
    hold on 
    eye = drawellipse;
    pause;
    eyeMask = poly2mask(eye.Vertices(:,1), eye.Vertices(:,2) , rows, columns);
    
    title('Draw Corneal Reflection')
    cornealReflection_0 = drawellipse('Color','r');
    pause
    cornMask = poly2mask(cornealReflection_0.Vertices(:,1), cornealReflection_0.Vertices(:,2) , rows, columns);
    moreCR = input('Would you like to input another corneal reflection? 0/1 \n');
    num = 0;
    additional_cornMask =[];
    while moreCR ==1
        num=num+1;
       additional_cornealReflection = drawellipse('Color','r');
       pause
       additional_cornMask{num} = poly2mask(additional_cornealReflection.Vertices(:,1), additional_cornealReflection.Vertices(:,2) , rows, columns);
       moreCR = input('Would you like to input another corneal reflection? 0/1 \n');
    end

    close all

end
