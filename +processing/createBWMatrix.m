function x=createBWMatrix(the_image,threshold,eyeMask,cornMask,additional_cornMask)
    if size(the_image,3)==3
        the_image = rgb2gray(the_image);
    end
    piel = im2bw(the_image,threshold); 
    piel = bwmorph(piel,'open');
    piel = bwareaopen(piel,200);
    piel = imfill(piel,'holes');
    
    % Tagged objects in BW image
    L = bwlabel(piel);
    L(~eyeMask)=0;
    L(cornMask)=0;
    if ~isempty(additional_cornMask)
        for corn=1:length(additional_cornMask)
            L(additional_cornMask{corn})=0;
        end
    end
    
    
    BW1 = edge(L,'Canny'); 
    [row,column] = find(BW1);
    x = vertcat(row',column'); %x is the input indices used to fit the circle
