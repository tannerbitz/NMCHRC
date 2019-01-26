function varargout = vr_dataanalysisgui(varargin)
% VR_DATAANALYSISGUI MATLAB code for vr_dataanalysisgui.fig
%      VR_DATAANALYSISGUI, by itself, creates a new VR_DATAANALYSISGUI or raises the existing
%      singleton*.
%
%      H = VR_DATAANALYSISGUI returns the handle to a new VR_DATAANALYSISGUI or the handle to
%      the existing singleton*.
%
%      VR_DATAANALYSISGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VR_DATAANALYSISGUI.M with the given input arguments.
%
%      VR_DATAANALYSISGUI('Property','Value',...) creates a new VR_DATAANALYSISGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before vr_dataanalysisgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to vr_dataanalysisgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help vr_dataanalysisgui

% Last Modified by GUIDE v2.5 25-Jan-2019 23:11:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @vr_dataanalysisgui_OpeningFcn, ...
                   'gui_OutputFcn',  @vr_dataanalysisgui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before vr_dataanalysisgui is made visible.
function vr_dataanalysisgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to vr_dataanalysisgui (see VARARGIN)

% Choose default command line output for vr_dataanalysisgui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes vr_dataanalysisgui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = vr_dataanalysisgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btn_addprocmat.
function btn_addprocmat_Callback(hObject, eventdata, handles)
% hObject    handle to btn_addprocmat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
matlistboxstr = get(handles.listbox1, 'string');

[tempname, temppath] = uigetfile('*.mat', 'Choose Process Data MAT File', ...
                                  'MultiSelect', 'on');
matlistboxstr{end+1} = fullfile(temppath, tempname);
set(handles.listbox1, 'Value',1);
set(handles.listbox1, 'string', matlistboxstr);



% --- Executes on button press in btn_clearmatlist.
function btn_clearmatlist_Callback(hObject, eventdata, handles)
% hObject    handle to btn_clearmatlist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.listbox1, 'string', {});


% --- Executes on button press in btn_plot.
function btn_plot_Callback(hObject, eventdata, handles)
% hObject    handle to btn_plot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
matfiles = get(handles.listbox1, 'string');
if (get(handles.rbtn_violations, 'Value') == 0)
    PlotProcessedData('ProcessedDataMats', matfiles);
else
    PlotProcessedData('ProcessedDataMats', matfiles, 'PlotFilteredData', 'on');
end



% --- Executes on button press in btn_addvrfiles.
function btn_addvrfiles_Callback(hObject, eventdata, handles)
% hObject    handle to btn_addvrfiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Patient Data Analysis Script
BASE_DIR = uigetdir(pwd, ...
                    'Choose Base Directory');
RD_DIR = fullfile(BASE_DIR, 'RawData');
if exist(RD_DIR, 'dir') == 0
    set(handles.textbox_rawdatafolder, 'string', 'RawData Folder Does Not Exist');
    return
end

% Retrieve Pat Number from path string                
if ispc
    pathparts = strsplit(BASE_DIR, '\');
else
    pathparts = strsplit(BASE_DIR, '/');
end

for i = 1:length(pathparts)
    match = regexp(pathparts{i}, 'Pat(?<patNum>\d+)', 'names');
    if ~isempty(match)
        patNum = match.patNum;
    end
end
mvcmatfile = sprintf('Pat%sMVC.mat', patNum);
mvcmatfile = fullfile(RD_DIR, mvcmatfile);

if exist(mvcmatfile, 'file') == 0
    set(handles.textbox_rawdatafolder, 'string', sprintf('%s was not found', mvcmatfile));
    return
end

set(handles.textbox_rawdatafolder, 'string', RD_DIR);

    

% --- Executes on button press in btn_processvrdata.
function btn_processvrdata_Callback(hObject, eventdata, handles)
% hObject    handle to btn_processvrdata (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get all VR Files in ../PatXX/RawData directory

RD_DIR = get(handles.textbox_rawdatafolder, 'string');
if exist(RD_DIR, 'dir') == 0
    set(handles.textbox_rawdatafolder, 'string', 'Choose RawData Folder First');
    return
end

% Retrieve Pat Number from path string                
if ispc
    pathparts = strsplit(RD_DIR, '\');
else
    pathparts = strsplit(RD_DIR, '/');
end

for i = 1:length(pathparts)
    match = regexp(pathparts{i}, 'Pat(?<patNum>\d+)', 'names');
    if ~isempty(match)
        patNum = match.patNum;
    end
end
mvcmatfile = sprintf('Pat%sMVC.mat', patNum);
mvcmatfile = fullfile(RD_DIR, mvcmatfile);

if exist(mvcmatfile, 'file') == 0
    set(handles.textbox_rawdatafolder, 'string', sprintf('%s was not found', mvcmatfile));
    return
end

% Delete PatXXProcessedData.mat file if it exists
PD_DIR = strrep(RD_DIR, 'RawData', 'ProcessedData');
procDataMat = sprintf('Pat%sProcessedData.mat', patNum);
procDataMat = fullfile(PD_DIR, procDataMat);
if exist(procDataMat, 'file') ~= 0
    delete(procDataMat);
end

% Get all files from folder, put in vrfiles list if it matches regular
% expression
rawfiles = ls(RD_DIR);
if ispc
    temp = {};
    [r, c] = size(rawfiles);
    for i = 1:r
        temp{end+1} = rawfiles(i, :);
    end
    rawfiles = temp;
else
    rawfiles = splitlines(rawfiles);
end

re = 'PatNo\d+.*[D|P]F_\d-\d+Hz.*\.txt';
vrfiles = {};

for i = 1:length(rawfiles)
    temp = regexp(rawfiles{i}, re, 'match');
    if ~isempty(temp)
        vrfiles{end+1} = temp{1};
    end
end

% Run analyzedata_randomtrials on all vrfiles
warning('off', 'all');
warning;
for i = 1:length(vrfiles)    
    tempstr = sprintf('Processing %i of %i\n', i, length(vrfiles));
    set(handles.textbox_rawdatafolder, 'string', tempstr);
    drawnow;
    ProcessRawData('mvcmatfile', mvcmatfile, ...
                   'vrfile', fullfile(RD_DIR, vrfiles{i}));
end
set(handles.textbox_rawdatafolder, 'string', 'Done');
drawnow;

warning('on', 'all');


% --- Executes during object deletion, before destroying properties.
function textbox_rawdatafolder_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to textbox_rawdatafolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in rbtn_violations.
function rbtn_violations_Callback(hObject, eventdata, handles)
% hObject    handle to rbtn_violations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rbtn_violations
