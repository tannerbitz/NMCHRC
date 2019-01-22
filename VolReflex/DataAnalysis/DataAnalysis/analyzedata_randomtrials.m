function res = analyzedata_randomtrials(varargin)
    close all;
    clc;
    
    p = inputParser;
    addParameter(p, 'matfile', '');
    addParameter(p, 'vrfile', '');
    parse(p, varargin{:});
    
    matfileinputted = ~strcmp('', p.Results.matfile);
    vrfileinputted = ~strcmp('', p.Results.vrfile);
    
    % Choose MVC MAT Files. We will get the PF and DF MVC Values which were
    % calculated and saved in this mat file
    if ~(matfileinputted)
        [mvcfile, mvcpath] = uigetfile('.mat', ...
                                'Choose MVC MAT Files', ...
                                'MultiSelect', 'on');
    else
        mvcfile = p.Results.matfile;
        mvcpath = '';
    end

    load(fullfile(mvcpath, mvcfile), 'DF', 'PF');
    mvcpf = PF;
    mvcdf = DF;

    refchannel = 2;
    measchannel = 1;

    % VR File
    if ~(vrfileinputted)
        % Choose Trial File
        [trialfile, trialpath] = uigetfile('.txt', ...
                                        'Choose VR Files', ...
                                        'MultiSelect', 'off');
    else
        trialfile = p.Results.vrfile;
        trialpath = '';
    end
    
    % Make MAT File for Processed Data
    if ispc
        pathparts = strsplit(mvcpath, '\');
    else
        pathparts = strsplit(mvcpath, '/');
    end
    
    BASE_DIR = '';
    for i = 1:length(pathparts)-2
        BASE_DIR = fullfile(BASE_DIR, pathparts{i});
    end
    PROC_DIR = fullfile(BASE_DIR, 'ProcessedData');
    
    if ~exist(PROC_DIR, 'dir')
        mkdir(PROC_DIR);
    end
            
    trialstruct = ParseFilename(trialfile, trialpath);
    procfile = sprintf('Pat%iProcessedData.mat', trialstruct.patno);
    procDataMat = fullfile(PROC_DIR, procfile);
    if ~exist(procDataMat, 'file')
        save(procDataMat);
    end
    
end  
%     
%     data = load(fullfile(trialpath, trialfile));
%     refdata = data(:,refchannel);
%     measdata = data(:, measchannel);
%     zerolevel = mean(measdata(1:5000));
%     measdata = measdata - zerolevel;
%     
%     % Take last cycle of refdata and find where it is zero (or at least
%     % minimum).  This spot will be assumed to be 3/4 of a period ahead of
%     % the start/stop of each trial period.  
%     reflastperiod = refdata(end-ceil(trialstruct.samplesperperiod):end);
%     periodmin = min(reflastperiod);
%     minindices = find(reflastperiod==periodmin);
% %     minindices = find(minindices > minindices(end) - trialstruct.samplesperperiod/2);
%     minind = round(mean(minindices));
%     minind = length(measdata) - (length(reflastperiod) - minind);
%     
%     zeroind = minind - 3/4*round(trialstruct.samplesperperiod);
% 
%     
%     % Gather data into cycles
%     numcycles = 15;
%     cycles = zeros(numcycles, floor(trialstruct.samplesperperiod));
%     startind = zeroind;
%     for i = 1:numcycles
%         actualind = zeroind - trialstruct.samplesperperiod*i;
%         startind = startind - floor(trialstruct.samplesperperiod);
%         stopind = startind + floor(trialstruct.samplesperperiod) - 1;
%         inddiff = actualind - startind;
%         if inddiff < -1
%             startind = startind -1;
%             stopind = stopind -1;
%         end
%         cycles(numcycles+1-i, :) = measdata(startind:stopind);
%         refcycles(numcycles+1-i, :) = refdata(startind:stopind);
%     end
%     
%     % Find mean and std deviation of cycles
%     nomcycle = zeros(1, floor(trialstruct.samplesperperiod));
%     stdcycle = zeros(1, floor(trialstruct.samplesperperiod));
%     
%     for i = 1:floor(trialstruct.samplesperperiod)
%         nomcycle(i) = mean(cycles(:, i));
%         stdcycle(i) = std(cycles(:, i));
%     end
%     lowerbound = nomcycle - 3*stdcycle;
%     upperbound = nomcycle + 3*stdcycle;
%     
%     % Only keep data if all data points are within 3 std deviations of
%     % mean
%     k = 1;
%     cycleslost = [];
%     for j = 1:numcycles
%         keepcycle = true;
%         for i = 1:floor(trialstruct.samplesperperiod)
%             if cycles(j, i) >= upperbound(i) || cycles(j, i) <= lowerbound(i)
%                 keepcycle = false;
%                 cycleslost(end + 1) = j;
%                 break
%             end
%         end
%         if keepcycle
%             validcycles(k, :) = cycles(j, :);
%             validrefcycles(k, :) = refcycles(j, :);
%             k = k + 1;
%         end
%     end
%     
%     % recalculate nominal measured and reference cycles
%     for i = 1:floor(trialstruct.samplesperperiod)
%         nommeascycle(i) = mean(validcycles(:, i));
%         nomrefcycle(i) = mean(validrefcycles(:,i));
%     end
%     
%     % Normalize to MVC
%     res2lbs = 250/4096;
%     lbs2newtons =  4.44822;
%     armlength = 0.15; % meters
%     percentmvc = 0.3;
%     
%     if strcmp(trialstruct.flexion, 'DF')
%         minrefval = 0;
%         maxrefval = percentmvc*mvcdf;
%         refsigspan = maxrefval - minrefval;
%         nomrefcycle_nm = minrefval + nomrefcycle/4096*refsigspan;
%     elseif strcmp(trialstruct.flexion, 'PF')
%         minrefval = -percentmvc*mvcpf;
%         maxrefval = 0;
%         refsigspan = maxrefval - minrefval;
%         nomrefcycle_nm = minrefval + nomrefcycle/4096*refsigspan;
%     end
%     
%     nommeascycle_nm = nommeascycle*res2lbs*lbs2newtons*armlength;
% 
%     
%     res = struct;
%     res.allcycles = cycles;
%     res.validcycles = validcycles;
%     res.validrefcycles = validrefcycles;
%     res.cycleslost = cycleslost;
%     res.nomrefcycle_nm = nomrefcycle_nm;
%     res.nommeascycle_nm = nommeascycle_nm;
%     res.trialinfo = trialstruct;
%     
% 
% end
