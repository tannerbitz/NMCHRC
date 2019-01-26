function res = PlotProcessedData(varargin)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %          Parse Arguments         %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Set up input parser
    p = inputParser;
    addParameter(p, 'ProcessedDataMats', {''});
    addParameter(p, 'PlotFilteredData', {'off'});
    parse(p, varargin{:});
    
    % Determine if arguments were inputted
    matfileinputted = ~strcmp('', p.Results.ProcessedDataMats{1});
    
    if ~(matfileinputted)
        [matfile, matdir] = uigetfile('.mat', ...
                                       'Choose Processed Data MAT File', ...
                                       'MultiSelect', 'off');
        matfile = {fullfile(matdir, matfile)};
    else
        matfile = p.Results.ProcessedDataMats;
    end

    % Load data from all matfiles
    
    data = {};
    for i = 1:length(matfile)
        data{end+1} = load(matfile{i}, 'PatientData');
    end
        
    % Lists of flexions and frequencies
    flexionlist = {'DF', 'PF'};
    freqlist = [0.2, 0.4, 0.6, 0.8, 1.0, 1.2, 1.4, 1.6, 1.8, 2.0];
  
        
    % Initialize plots
    % If the matlab version is R2018b or later the plot will have a major
    % title and subplot title.  If the matlab version is earlier than 2018b
    % then the plot will only have subplot titles.
    
    
    for iFlex = 1:length(flexionlist)
        for iFreq = 1:length(freqlist)
            i = (iFlex - 1)*10 + iFreq;
            figure(i);
            figtitle = sprintf('%s - %2.1fHz', flexionlist{iFlex}, freqlist(iFreq));
            title(figtitle);
            ylabel('Percent of 30% MVC')
        end
    end
       
    
    % Initialize unfilterdatastruct.  Unfilterdatastruct is a structure array.
    % It will be indexed unfilterdatastruct(iFlex, iFreq) and will have the
    % fields:
    % - refdata
    % - measdata
    % - refdatamean
    % - refdatastd
    % - measdatamean
    % - measdata3std
    % - measdataupperbound (measdatamean + measdata3std)
    % - measdatalowerbound (measdatamean - measdata3std)
   
    
    unfilterdatastruct = struct;
    for iFlex = 1:length(flexionlist)
        for iFreq = 1:length(freqlist)
            unfilterdatastruct(iFlex, iFreq).refdata = [];
            unfilterdatastruct(iFlex, iFreq).measdata = [];
            unfilterdatastruct(iFlex, iFreq).refdatamean = [];
            unfilterdatastruct(iFlex, iFreq).refdata3std = [];
            unfilterdatastruct(iFlex, iFreq).measdatamean = [];
            unfilterdatastruct(iFlex, iFreq).measdata3std = [];
            unfilterdatastruct(iFlex, iFreq).measdataupperbound = [];
            unfilterdatastruct(iFlex, iFreq).measdatalowerbound = [];
        end
    end
    
    % Put cycles 2:6 from each trial into unfilterdatastruct. We are
    % intentionally discarding the first cycle in each trial.
    
    for iPatient = 1:length(data)
        for iTrial = 1:length(data{iPatient}.PatientData)
            patflexion = data{iPatient}.PatientData{iTrial}.flexion;
            patfreq = data{iPatient}.PatientData{iTrial}.refsigfreq;
            iFlex = find(contains(flexionlist, patflexion));
            iFreq = find(freqlist == patfreq);
            unfilterdatastruct(iFlex, iFreq).refdata(end+1:end+5, :) = data{iPatient}.PatientData{iTrial}.cyclerefdata_percentcommand(2:6,:);
            unfilterdatastruct(iFlex, iFreq).measdata(end+1:end+5, :) = data{iPatient}.PatientData{iTrial}.cyclemeasdata_percentcommand(2:6,:);
        end
    end
       
    % Calculate mean, 3 std, upper & lower bounds and measdata
    for iFlex = 1:length(flexionlist)
        for iFreq = 1:length(freqlist)
            unfilterdatastruct(iFlex, iFreq).refdatamean = mean(unfilterdatastruct(iFlex, iFreq).refdata, 1);
            unfilterdatastruct(iFlex, iFreq).refdata3std = 3*std(unfilterdatastruct(iFlex, iFreq).refdata, 0, 1);
            unfilterdatastruct(iFlex, iFreq).measdatamean = mean(unfilterdatastruct(iFlex, iFreq).measdata, 1);
            unfilterdatastruct(iFlex, iFreq).measdata3std = 3*std(unfilterdatastruct(iFlex, iFreq).measdata, 0, 1);
            unfilterdatastruct(iFlex, iFreq).measdataupperbound = unfilterdatastruct(iFlex, iFreq).measdatamean + unfilterdatastruct(iFlex, iFreq).measdata3std;
            unfilterdatastruct(iFlex, iFreq).measdatalowerbound = unfilterdatastruct(iFlex, iFreq).measdatamean - unfilterdatastruct(iFlex, iFreq).measdata3std;
        end
    end
    
    
    cyclespertrial = 6;
    
    % Initialize struct to keep track of whether the plot has been plotted
    % on yet and how many cycles were filtered out
    for iFlex = 1:length(flexionlist)
        for iFreq = 1:length(freqlist)
            plotinfo(iFlex, iFreq).hasLine = false;
            plotinfo(iFlex, iFreq).hasFilteredLine = false;
            plotinfo(iFlex, iFreq).filteredLines = 0;
            plotinfo(iFlex, iFreq).totalLines = 0;
        end
    end
    
    
    % Initialize struct to seperate data with violations vs that with no
    % violations
    filtereddatastruct = struct;
    for iFlex = 1:length(flexionlist)
        for iFreq = 1:length(freqlist)
            filtereddatastruct(iFlex, iFreq).violated.measdata = [];
            filtereddatastruct(iFlex, iFreq).violated.patnum = [];
            filtereddatastruct(iFlex, iFreq).violated.trialnum = [];
            filtereddatastruct(iFlex, iFreq).violated.cycle = [];
            filtereddatastruct(iFlex, iFreq).unviolated.measdata = [];
            filtereddatastruct(iFlex, iFreq).unviolated.patnum = [];
            filtereddatastruct(iFlex, iFreq).unviolated.trialnum = [];
            filtereddatastruct(iFlex, iFreq).unviolated.cycle = [];
            filtereddatastruct(iFlex, iFreq).unviolated.measdatamean = [];
            filtereddatastruct(iFlex, iFreq).unviolated.measdata3std = [];
            filtereddatastruct(iFlex, iFreq).unviolated.measdataupperbound = [];
            filtereddatastruct(iFlex, iFreq).unviolated.measdatalowerbound = [];
        end
    end
    
    % Create struct for legend entries.  This is necessary as we do not
    % know if a violated or unviolated cycle will occur first.
    legendstruct = struct;
    for iFlex = 1:length(flexionlist)
        for iFreq = 1:length(freqlist)
            legendstruct(iFlex, iFreq).legendstr = {};
        end
    end
    
    
    
    % Check bounds, sort, and plot.  
    
    for iPatient = 1:length(data)
        for iTrial = 1:length(data{iPatient}.PatientData)
            patnum = data{iPatient}.PatientData{iTrial}.patno;
            trialnum = data{iPatient}.PatientData{iTrial}.trialno;
            patflexion = data{iPatient}.PatientData{iTrial}.flexion;
            patfreq = data{iPatient}.PatientData{iTrial}.refsigfreq;
            iFlex = find(contains(flexionlist, patflexion));
            iFreq = find(freqlist == patfreq);
            for iCycle = 2:cyclespertrial
                tempcycle = data{iPatient}.PatientData{iTrial}.cyclemeasdata_percentcommand(iCycle, :);
                % Check for violation of lower/upper bounds
                upperbound = unfilterdatastruct(iFlex, iFreq).measdataupperbound;
                lowerbound = unfilterdatastruct(iFlex, iFreq).measdatalowerbound;
                
                anyaboveupperbound = any( (tempcycle - upperbound) > 0 );
                anybelowlowerbound = any( (tempcycle - lowerbound) < 0 );
                
                % Plot if no violations of 3 std upper/lower bounds,
                % continue to next for loop if violation occurs
                plotinfo(iFlex, iFreq).totalLines = plotinfo(iFlex, iFreq).totalLines + 1;
                if ( anyaboveupperbound || anybelowlowerbound )
                    % Add data to filtereddatastruct
                    filtereddatastruct(iFlex, iFreq).violated.measdata(end+1, :) = tempcycle;
                    filtereddatastruct(iFlex, iFreq).violated.patnum(end+1, 1) = patnum;
                    filtereddatastruct(iFlex, iFreq).unviolated.trialnum(end+1, 1) = trialnum;
                    filtereddatastruct(iFlex, iFreq).violated.cycle(end+1, 1) = iCycle;
                    % Plot if Necessary
                    iFig = (iFlex - 1)*10 + iFreq;
                    figure(iFig)
                    plotinfo(iFlex, iFreq).filteredLines = plotinfo(iFlex, iFreq).filteredLines + 1;
                    if strcmp(p.Results.PlotFilteredData, 'on')
                        hold on
                        if ~plotinfo(iFlex, iFreq).hasFilteredLine
                            plot(tempcycle, 'color', 'g', 'LineWidth', 1);
                            plotinfo(iFlex, iFreq).hasFilteredLine = true;
                            legendstruct(iFlex, iFreq).legendstr{end+1} = 'Data With Violations';
                        else
                            plot(tempcycle, 'color', 'g', 'LineWidth', 1, 'HandleVisibility', 'off');
                        end
                        hold off
                    end
                    continue
                else
                    % Add data to filtereddatastruct
                    filtereddatastruct(iFlex, iFreq).unviolated.measdata(end+1, :) = tempcycle;
                    filtereddatastruct(iFlex, iFreq).unviolated.patnum(end+1, 1) = patnum;
                    filtereddatastruct(iFlex, iFreq).unviolated.trialnum(end+1, 1) = trialnum;
                    filtereddatastruct(iFlex, iFreq).unviolated.cycle(end+1, 1) = iCycle;
                    % Plot
                    iFig = (iFlex - 1)*10 + iFreq;
                    figure(iFig)
                    hold on
                    if ~plotinfo(iFlex, iFreq).hasLine
                        plot(tempcycle, 'color', 'r', 'LineWidth', 1);
                        plotinfo(iFlex, iFreq).hasLine = true;
                        legendstruct(iFlex, iFreq).legendstr{end+1} = 'Data Without Violations';
                    else
                        plot(tempcycle, 'color', 'r', 'LineWidth', 1, 'HandleVisibility', 'off');
                    end
                    hold off
                end
                
            end
        end
    end
    
    % Calculate unviolated data means, std, upper/lower bounds
    for iFlex = 1:length(flexionlist)
        for iFreq = 1:length(freqlist)
            filtereddatastruct(iFlex, iFreq).unviolated.measdatamean = mean(filtereddatastruct(iFlex, iFreq).unviolated.measdata, 1);
            filtereddatastruct(iFlex, iFreq).unviolated.measdata3std = 3*std(filtereddatastruct(iFlex, iFreq).unviolated.measdata, 0, 1);
            filtereddatastruct(iFlex, iFreq).unviolated.measdataupperbound = filtereddatastruct(iFlex, iFreq).unviolated.measdatamean + filtereddatastruct(iFlex, iFreq).unviolated.measdata3std;
            filtereddatastruct(iFlex, iFreq).unviolated.measdatalowerbound = filtereddatastruct(iFlex, iFreq).unviolated.measdatamean - filtereddatastruct(iFlex, iFreq).unviolated.measdata3std;
        end
    end
    
    
    % Plot Mean and Std Deviation Lines and Reference Data
    for iFlex = 1:length(flexionlist)
        for iFreq = 1:length(freqlist)
            iFig = (iFlex - 1)*10 + iFreq;
            figure(iFig)
            hold on
            lWidth = 2;
            % Plot reference data, unviolated data mean, unviolated data
            % upper/lower bounds
            plot(unfilterdatastruct(iFlex, iFreq).refdatamean, 'b', 'LineWidth', lWidth);
            plot(filtereddatastruct(iFlex, iFreq).unviolated.measdataupperbound, '--k', 'LineWidth', lWidth);
            plot(filtereddatastruct(iFlex, iFreq).unviolated.measdatalowerbound, '--k', 'LineWidth', lWidth, 'HandleVisibility', 'off');
            plot(filtereddatastruct(iFlex, iFreq).unviolated.measdatamean, 'k', 'LineWidth', lWidth);
            % Fill legendstr
            legendstruct(iFlex, iFreq).legendstr{end+1} = 'Reference Signal';
            legendstruct(iFlex, iFreq).legendstr{end+1} = '+/- 3 std';
            legendstruct(iFlex, iFreq).legendstr{end+1} = 'Mean Measured Signal';
            % Complete Plot Markings
            legend(legendstruct(iFlex, iFreq).legendstr);
            xlabelstr = sprintf(['Samples\n\n' ...
                                 '%i of %i Cycles Violated +/- 3 std'], ...
                                 plotinfo(iFlex, iFreq).filteredLines, ...
                                 plotinfo(iFlex, iFreq).totalLines);
            xlabel(xlabelstr)
            hold off
        end
    end
    
end