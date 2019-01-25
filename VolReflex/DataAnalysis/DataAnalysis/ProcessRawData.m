function res = ProcessRawData(varargin)
    close all;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %          Parse Arguments         %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Set up input parser
    p = inputParser;
    addParameter(p, 'mvcmatfile', '');
    addParameter(p, 'vrfile', '');
    parse(p, varargin{:});
    
    % Determine if arguments were inputted
    mvcmatfileinputted = ~strcmp('', p.Results.mvcmatfile);
    vrfileinputted = ~strcmp('', p.Results.vrfile);
    
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
    BASE_DIR = '/';                  % Build Base Folder Path
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

    data = load(fullfile(trialpath, trialfile));
    refdata = data(:,refchannel);
    measdata = data(:, measchannel);
    
    % There is a pause between 0-5s to start each trial.  Sometimes
    % patients adjust during the first couple seconds, so take the
    % zerolevel to be from 2-5s (i.e. sample 2000-5000)
    zerolevel = mean(measdata(2000:5000)); 
    measdata = measdata - zerolevel;

    
    % After the 5s initial 'zero' period, a 4-6s random pause occurs,
    % followed by a sinusoid.  We don't know when the cycle starts so we
    % will generate a 'perfect' sinusoid and use least squares to determine
    % the starting point.   Because of some possible extra time added to
    % the routine during startup, the first cycle will be searched 4-8
    % seconds after the initial 5s period.  After that, we will only search
    % the 4-6s after a cycle ends.  
    samplespersec = 1000;
    samplesbeforecycle = 1500;
    samplesaftercycle = 1500;
    startsample = 9000;
    
    refmax = max(refdata);
    refmin = min(refdata);
    trialstruct.refmaxraw = refmax;
    trialstruct.refminraw = refmin;
    sampletime = 1/samplespersec;
    sinetime = (1:1:trialstruct.samplesperperiod)*sampletime;
    perfectsine = (refmax-refmin)/2*(1-cos(2*pi*trialstruct.refsigfreq*sinetime)) + refmin;
    
    sineindexinfo = {};
    trialstruct.cyclerefdataraw = [];
    trialstruct.cyclemeasdataraw = [];
    for cyclecount = 1:6
        if (cyclecount == 1)
            intervalchecksamples = 4000;
        else
            intervalchecksamples = 2000;
        end
        norm_hist = [];
        sineindexstruct = struct;
        % Calculate square error vs perfect sine wave for each interval
        % where sine could be
        for i = 1:intervalchecksamples
            tempsinestart = startsample+i;
            refdatainterval = refdata(tempsinestart:tempsinestart+trialstruct.samplesperperiod-1)';
            norm_hist(i) = norm(perfectsine-refdatainterval);
        end
        % Index I where square error is minimized
        [Y, I] = min(norm_hist);
        sineindexstruct.cyclenumber = cyclecount;
        sineindexstruct.cyclestartind = startsample + I;
        sineindexstruct.cyclestopind = startsample + I + trialstruct.samplesperperiod -1;
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
    % of commanded ref signal (30% MVC)              %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    trialstruct.cyclerefdata_percentcommand = trialstruct.cyclerefdata_nm * 100/(trialstruct.mvc*percentmvc);
    trialstruct.cyclemeasdata_percentcommand = trialstruct.cyclemeasdata_nm * 100/(trialstruct.mvc*percentmvc);
        
    patmat.PatientData(end+1,1) = {trialstruct};
end
