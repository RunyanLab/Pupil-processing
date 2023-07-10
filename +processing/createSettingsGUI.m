function createSettingsGUI()

% create the gui figure 
fig = figure('Name','Processing Settings','Position',[200,200,300,200]);

%threshold input
thresholdLabel = uicontrol('Style','text','String','Threshold:','Position',[20,150,80,20]);
thresholdEdit = uicontrol('Style','edit','Position',[100,150,80,20]);


%blink threshold input 
blinkLabel = uicontrol('Style','text','String','Blink Threshold:','Position',[20,120,80,20]);
blinkEdit = uicontrol('Style','edit','Position',[100,120,80,20]);



%follow up analysis
kMeansCheckBox = uicontrol('Style','checkbox','String','Kmeans Clustering','Position',[20,90,200,20]);
dilconCheckBox = uicontrol('Style','checkbox','String','Dilation/Contrstriction Event Detection','Position',[]);





% button to start the analysis 
startButton = uicontrol('Style','pushbutton','String','Start Analysis','Position',[20,50,100,30]);
set(startButton, 'Callback',@startAnalysis)