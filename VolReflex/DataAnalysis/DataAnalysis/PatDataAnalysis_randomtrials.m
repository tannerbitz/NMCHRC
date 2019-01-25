%Suppress warnings
warning('off', 'all');


% Patient Data Analysis Script
BASE_DIR = uigetdir(pwd, ...
                    'Choose Patient Directory');

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

% Add paths
RD_DIR = fullfile(BASE_DIR, 'RawData'); %raw data folder
PD_DIR = fullfile(BASE_DIR, 'ProcessedData'); %processed data folder
if ~exist(PD_DIR, 'dir')
    mkdir(PD_DIR)
end
addpath(BASE_DIR);
addpath(RD_DIR);
addpath(PD_DIR);

matfile = sprintf('Pat%sMVC.mat', patNum);

% Get all VR Files in ../PatXX/RawData directory
rawfiles = ls(RD_DIR);
rawfiles = splitlines(rawfiles);

re = 'PatNo\d+.*[D|P]F_\d-\d+Hz.*\.txt';
vrfiles = {};

for i = 1:length(rawfiles)
    temp = regexp(rawfiles{i}, re, 'match');
    if ~isempty(temp)
        vrfiles{end+1} = temp{1};
    end
end

% Run analyzedata_randomtrials on all vrfiles
for i = 1:length(vrfiles)
    fprintf('%i of %i\n', i, length(vrfiles));
    ProcessRawData('mvcmatfile', fullfile(RD_DIR, matfile), ...
                   'vrfile', fullfile(RD_DIR, vrfiles{i}));
end






