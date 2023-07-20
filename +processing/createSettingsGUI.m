function [selectedThreshold,selectedBlink,selectedScope,selectedOrient,selectedUnit,...
    selectedConversion,selectedAlign,selectedKmeans,selectedDilCon]...
    = createSettingsGUI(the_example_image,cornMask,eyeMask,additional_cornMask)


%intialize the output variables 
selectedThreshold = .5;
selectedBlink = [];
selectedScope = '2p+';
selectedOrient = 0;
selectedUnit = 'pix^2';
selectedConversion = 1;
selectedAlign = 'rough';
selectedKmeans = 0;
selectedDilCon =0;



% create the gui figure 
fig = figure('Name','Processing Settings','Position',[250 293 776 447]);


%% processing parameters 
procLabel = uicontrol('Style','text','Position',[140,370,190,50],'String','Processing Parameters','FontSize',11);
analysisLabel = uicontrol('Style','text','Position',[450,370,150,50],'String','Elective Analyses','FontSize',11);

%blink threshold input 
blinkLabel = uicontrol('Style','text','String','Blink Threshold:','Position',[30,340,150,20],'FontSize',9.5);
blinkEdit = uicontrol('Style','edit','Position',[170,340,80,20],'Callback',@blinkCallbackFxn);

% scope - select one 
scopeLabel = uicontrol('Style','text','String','Scope/Rig:','Position',[30,310,150,20],'FontSize',9.5,'Callback',@scopesCallbackFxn);
scopes = {'2P+','Investigator','Training rig'};
scopeDrop = uicontrol('Style','popupmenu','Position',[170,280,100,50],'String',scopes,'Callback',@scopesCallbackFxn);


% oritenation
orientLabel = uicontrol('Style','text','String','Orientation:','Position',[30,280,150,20],'FontSize',9.5);
orients = {'0','90'};
orientDrop = uicontrol('Style','popupmenu','Position',[170,280,50,20],'String',orients,'Callback',@orientCallbackFxn);

%unit 
unitLabel = uicontrol('Style','text','String','Unit:','Position',[30,250,150,20],'FontSize',9.5);
units = {'pix^2','mm^2'};
unitDrop = uicontrol('Style','popupmenu','Position',[170,250,50,20],'String',units,'Callback',@unitCallbackFxn);


conversionLabel = uicontrol('Style','text','String','Conversion Factor:','Position',[30,220,150,20],'FontSize',9.5);
conversionEdit = uicontrol('Style','edit','Position',[170,220,80,20],'Callback',@conversionCallbackFxn);

%alignment
alignLabel = uicontrol('Style','text','String','Alignment type:','Position',[30,190,150,20],'FontSize',9.5);
align = {'rough','tight'};
alignDrop = uicontrol('Style','popupmenu','Position',[170,190,100,20],'String',align,'Callback',@alignCallbackFxn);

%threshold
thresholdLabel = uicontrol('Style','text','Position',[50,130,200,20],'String','Set Threshold Value');
threshold = uicontrol('Style','slider','Position',[50,90,200,20],'Min',0,'Max',1,'Value',.5,'Callback',@sliderCallback);
sLabel = uicontrol('Style','text','Position',[50,110,200,20],'String',0.5);

% could also have a save parameters button which saves a file of all these
% button properties so that it can be loaded on each dataset 


%follow up analysis
kMeansCheckBox = uicontrol('Style','checkbox','String','Kmeans Clustering','Position',[450,340,200,20],'FontSize',9.5,'Callback',@kmeansCallbackFxn);
dilconCheckBox = uicontrol('Style','checkbox','String','Dilation/Contrstriction Event Detection','Position',[450,310,250,20],'FontSize',9.5,'Callback',@dilconCallbackFxn);


% start button 
start = uicontrol('Style','pushbutton','String','Run','Position',[600,50,150,50],'Callback',@runButtonPushed);





%callback fxn for blink
    function blinkCallbackFxn(src,~)
        selectedBlink = get(src,'Value');
    end

%callback fxn for orient 
    function  orientCallbackFxn(src,~)
        selectedOrient = src.String{src.Value};
    end

%callback fxn for scope
    function scopesCallbackFxn(src,~)
        selectedScope = src.String{src.Value};
    end

%callback fxn for unit 
    function unitCallbackFxn(src,~)
        selectedUnit = src.String{src.Value};        
    end

%callback fxn for align 
    function alignCallbackFxn(src,~)
        selectedAlign = src.String{src.Value};
    end

%callback fxn for conversion factor 
    function conversionCallbackFxn(src,~)
        selectedConversion=src.Value;
    end

%callback fxn for kmeans 
    function kmeansCallbackFxn(src,~)
        selectedKmeans = src.Value;
    end

%callback fxn for dilcon
    function  dilconCallbackFxn(src,~)
        selectedDilCon = src.Value;
    end



%callback fxn for slider
    function sliderCallback(source,~)
    % get the current value of the slider
        sValue = get(source,'Value');
    
        %update label with current value 
        set(sLabel,'String',num2str(sValue));
    
        %update the plot with the current slider value
        orientation = str2num(orientDrop.String{orientDrop.Value});
        plotExampleThrehsold(the_example_image,sValue,cornMask,eyeMask,additional_cornMask,orientation)
         selectedThreshold=sValue;
    end



    function plotExampleThrehsold(the_example_image,sValue,cornMask,eyeMask,additional_cornMask,orientation)

        x=processing.createBWMatrix(the_example_image,sValue,eyeMask,cornMask,additional_cornMask);
        x=processing.getROIcoordinates(orientation,x,[],[],1);  
        try
            [z, r, ~] = processing.fitcircle_mcc(x,'linear');
        catch ME
            z = [];
            r = [];
        end
        %how to handle blank frames
        if ~isempty(r)
            z([1 2]) = z([2 1]);
        end

        figure(999);clf;
        imshow(the_example_image)
        viscircles(z',r)
        title(['Testing threshold = ' num2str(sValue)]);

    end


%callback fxn for run button 
    function  runButtonPushed(~,~)


        close(fig);
        %assignin('base','selectedThreshold',selectedThreshold);
        disp('Processing parameters saved... Beginning data processing...')
    end

    waitfor(fig);


end


