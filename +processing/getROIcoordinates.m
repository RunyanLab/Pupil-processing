function  x=getROIcoordinates(orientation,x,center_row,center_column,cnt)

%changed this so that the true top and bottom of the pupil are used to
%estimate the circle, bc that diameter is less susceptible to
%saccade-related changes compared to side/side, this can be changed is you
%feel that your data has a lot of squinty frames you want to keep


 %looks for gaps in distribution of object locations - if gaps
 %exist, this indicates more than one object was identified. This
 %allows for proper selection of the pupil as object to fit circle.



if orientation == 90 %used to be 90
    if isempty(x)
        x = []; 
    elseif ~isempty(x) &&  isempty(center_row)
        bott=find(x(1,:)>=prctile(x(1,:),80)); %only want to input the top and bottom 20% of x into fitcircles to allow a more accurate circle be fit to frames where pupil is partially occurlied by eyelid
        top=find(x(1,:)<=prctile(x(1,:),20));
        ind = union(bott,top);
        x = x(:,ind);          
    else
        groupID = dbscan(x',5,5);
        groupID = groupID';
        if max(groupID)== 1
            bott=find(x(1,:)>=prctile(x(1,:),80)); 
            top=find(x(1,:)<=prctile(x(1,:),20));
            ind = union(bott,top);
            x = x(:,ind);
        else
            row_means = [];
            col_means = [];
            for group = 1:max(groupID)
                row_means = [row_means mean(x(1,groupID == group))];
            end
            for group = 1:max(groupID)
                col_means = [col_means mean(x(2,groupID == group))];
            end
            [~,ridx] = min(abs(center_row(cnt-1)-row_means));
            %all_ridx(cnt) = ridx;
            [~,cidx] = min(abs(center_column(cnt-1)-col_means));
            %all_ridx(cnt) = ridx;
            if ridx~=cidx 
                %x = x(:,groupID == max(ridx));
                x = x(:,groupID == mode(groupID));
                bott = find(x(1,:)>=prctile(x(1,:),80));
                top = find(x(1,:)<=prctile(x(1,:),20));
                ind = union(bott,top);
                x = x(:,ind);
            else
                x = x(:,groupID == ridx);
                bott = find(x(1,:)>=prctile(x(1,:),80));
                top = find(x(1,:)<=prctile(x(1,:),20));
                ind = union(bott,top);
                x = x(:,ind);
            end
        end
    end
else
    if isempty(x)
        x = []; 
    elseif ~isempty(x) &&  isempty(center_row)
        bott=find(x(2,:)>=prctile(x(2,:),80)); %only want to input the top and bottom 20% of x into fitcircles to allow a more accurate circle be fit to frames where pupil is partially occurlied by eyelid
        top=find(x(2,:)<=prctile(x(2,:),20));
        ind = union(bott,top);
        x = x(:,ind);          

    else
        groupID = dbscan(x',5,5);
        groupID = groupID';
        if max(groupID)== 1
            bott=find(x(2,:)>=prctile(x(2,:),80)); 
            top=find(x(2,:)<=prctile(x(2,:),20));
            ind = union(bott,top);
            x = x(:,ind);
        else
            row_means = [];
            col_means = [];
            for group = 1:max(groupID)
                row_means = [row_means mean(x(1,groupID == group))];
            end
            for group = 1:max(groupID)
                col_means = [col_means mean(x(2,groupID == group))];
            end
            [~,ridx] = min(abs(center_row(cnt-1)-row_means));
            %all_ridx(cnt) = ridx;
            [~,cidx] = min(abs(center_column(cnt-1)-col_means));
            %all_ridx(cnt) = ridx; 
            if ridx ~= cidx
                %x = x(:,groupID == max(ridx));
                x = x(:,groupID == mode(groupID));
                bott = find(x(2,:)>=prctile(x(2,:),80));
                top = find(x(2,:)<=prctile(x(2,:),20));
                ind = union(bott,top);
                x = x(:,ind);
            else
                x = x(:,groupID == ridx);
                bott = find(x(2,:)>=prctile(x(2,:),80));
                top = find(x(2,:)<=prctile(x(2,:),20));
                ind = union(bott,top);
                x = x(:,ind);
            end
        end
    end
 end
      