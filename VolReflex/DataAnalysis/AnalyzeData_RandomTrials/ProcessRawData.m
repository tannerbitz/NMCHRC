function res = ProcessRawData(varargin)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %          Parse Arguments         %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Set up input parser
    p = inputParser;
    addParameter(p, 'mvcmatfile', '');
    addParameter(p, 'vrfile', '');
    addParameter(p, 'minval', '');
    addParameter(p, 'maxval', '');
    parse(p, varargin{:});
    
    % Determine if arguments were inputted
    mvcmatfileinputted = ~strcmp('', p.Results.mvcmatfile);
    vrfileinputted = ~strcmp('', p.Results.vrfile);
    minvalinputted = ~strcmp('', p.Results.minval);
    maxvalinputted = ~strcmp('', p.Results.maxval);
    
    % Choose MVC MAT Files. Get the PF and DF MVC Values which were calculated
    % and saved in this mat file.  This file should be in raw data folder.
    if ~(mvcmatfileinputted)
        [mvcfile, mvcpath] = uigetfile('.mat', ...
                                       'Choose MVC MAT Files', ...
                                       'MultiSelect', 'on');
    else
        [mvcpath, name, ext] = fileparts(p.Results.mvcmatfile);
        mvcfile = strcat(name, ext);
    end

    % Voluntary Reflex Trial File
    if ~(vrfileinputted)
        % Choose Trial File
        [trialfile, trialpath] = uigetfile('.txt', ...
                                        'Choose VR Files', ...
                                        'MultiSelect', 'off');
    else
        [trialpath, name, ext] = fileparts(p.Results.vrfile);
        trialfile = strcat(name, ext);
    end
    
    % ParseFilename returns a struct of metadata from the voluntary reflex
    % trial filename
    trialstruct = ParseFilename(trialfile, trialpath);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   Create Correct File Structure  %
    %   and Processed Data MAT File    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Assumed file structure
    % ../PatXX                  --- Base Dir for Pat XX
    % ../PatXX/RawData          --- Dir for all raw data
    % ../PatXX/ProcessedData    --- Dir for all processed data.
    %                               (will be saving to this folder)
    
    % Create/get BASE_DIR, PD_DIR paths (PD = ProcessedData)
    mvcpath = strip(mvcpath, 'right', '/');
    mvcpath = strip(mvcpath, 'right', '\');
    if ispc  % Windows Paths
        pathparts = strsplit(mvcpath, '\');
    else     % Linux or Mac Paths
        pathparts = strsplit(mvcpath, '/');
    end
    
    RD_DIR = mvcpath;               % Raw Data Folder Path
    if ispc
        BASE_DIR = '';
    else
        BASE_DIR = '/';                  % Build Base Folder Path
    end
    
    for i = 1:length(pathparts)-1
        BASE_DIR = fullfile(BASE_DIR, pathparts{i});
    end
    PD_DIR = fullfile(BASE_DIR, 'ProcessedData'); % Processed Data Folder Path
    
    % If Processed Data dir doesn't exist, create it.
    if exist(PD_DIR, 'dir') == 0
        mkdir(PD_DIR);
    end
    
    procfile = sprintf('Pat%iProcessedData.mat', trialstruct.patno);
    procDataMat = fullfile(PD_DIR, procfile);
    if exist(procDataMat, 'file') == 0
        PatientData = {};
        save(procDataMat, 'PatientData', '-v7.3');
        patmat = matfile(procDataMat, 'Writable', true);
    else
        patmat = matfile(procDataMat, 'Writable', true);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %       Load DF/PF MVC Values      %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    load(fullfile(mvcpath, mvcfile), 'DF', 'PF');
    mvcpf = PF;
    mvcdf = DF;
    
    if strcmp(trialstruct.flexion, "DF")
        trialstruct.mvc = mvcdf;
    elseif strcmp(trialstruct.flexion, "PF")
        trialstruct.mvc = mvcpf;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %       Load Raw Data and          %
    %       Start Post-processing      %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
   % Load Data
    refchannel = 2;
    measchannel = 1;
    flagchannel = 8;

    data = load(fullfile(trialpath, trialfile));
    refdata = data(:,refchannel);
    measdata = data(:, measchannel);
    flagdata = data(:, flagchannel);
    flagdata(1:5000) = 0; % some beginning samples in flagdata are not 0, but should be
    flagdata(2:end) = diff(flagdata);
    cyclestarttemp = find(flagdata) + 5; %cycles start 5ms after flag
    
    % There is a pause between 0-5s to start each trial.  Sometimes
    % patients adjust during the first couple seconds, so take the
    % zerolevel to be from 2-5s (i.e. sample 2000-5000)
    zerolevel = mean(measdata(2000:5000)); 
    measdata = measdata - zerolevel;
    
    % The cycle starts at the indices from the find(flagdata) command, it
    % end trialstruct.samplesperperiod samples later.  We will capture this
    % range with 1500 samples on either side.
    samplespersec = 1000;
    samplesbeforecycle = 1500;
    samplesaftercycle = 1500;
    startsample = 9000;
    
    % If reference min val not inputted take min of refdata, otherwise use
    % given value
    if ~(minvalinputted)
        refmin = min(refdata);
    else
        refmin = p.Results.minval;
    end
    
    % If reference max val not inputted take max of refdata, otherwise use
    % given value
    if ~(maxvalinputted)
        refmax = max(refdata);
    else
        refmax = p.Results.maxval;
    end

    trialstruct.refmaxraw = refmax;
    trialstruct.refminraw = refmin;
    sampletime = 1/samplespersec;
    sinetime = (1:1:trialstruct.samplesperperiod)*sampletime;
    
    sineindexinfo = {};
    trialstruct.cyclerefdataraw = [];
    trialstruct.cyclemeasdataraw = [];
    for cyclecount = 1:length(cyclestarttemp)
        
        sineindexstruct.cyclenumber = cyclecount;
        sineindexstruct.cyclestartind = cyclestarttemp(cyclecount);
        sineindexstruct.cyclestopind = sineindexstruct.cyclestartind + trialstruct.samplesperperiod -1;
        sineindexstruct.intervalstartind = sineindexstruct.cyclestartind - samplesbeforecycle;
        sineindexstruct.intervalstopind = sineindexstruct.cyclestopind + samplesaftercycle;
        sineindexinfo{end+1} = sineindexstruct;
        trialstruct.cyclerefdataraw(end+1,:) = refdata(sineindexstruct.intervalstartind: sineindexstruct.intervalstopind);
        trialstruct.cyclemeasdataraw(end+1,:) = measdata(sineindexstruct.intervalstartind: sineindexstruct.intervalstopind);
        startsample = sineindexstruct.cyclestopind + 4000;
    end
    
    trialstruct.sineindexinfo = sineindexinfo;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Convert raw refdata and measdata to units of N-m %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Conversion quantities
    res2lbs = 250/4096;
    lbs2newtons =  4.44822;
    armlength = 0.15; % meters
    percentmvc = 0.3;
    
    trialstruct.cyclerefdata_nm = (trialstruct.cyclerefdataraw - refmin)/(refmax - refmin)*trialstruct.mvc*percentmvc;
    if strcmp(trialstruct.flexion, 'DF')
        trialstruct.cyclemeasdata_nm = trialstruct.cyclemeasdataraw * res2lbs * lbs2newtons * armlength;
    elseif strcmp(trialstruct.flexion, 'PF')
        trialstruct.cyclemeasdata_nm = -trialstruct.cyclemeasdataraw * res2lbs * lbs2newtons * armlength;
    end
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Convert raw refdata and measdata to percentages  %
    % of commanded ref signal (30% MVC)                %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    trialstruct.cyclerefdata_percentcommand = trialstruct.cyclerefdata_nm * 100/(trialstruct.mvc*percentmvc);
    trialstruct.cyclemeasdata_percentcommand = trialstruct.cyclemeasdata_nm * 100/(trialstruct.mvc*percentmvc);
        
    patmat.PatientData(end+1,1) = {trialstruct};
end
