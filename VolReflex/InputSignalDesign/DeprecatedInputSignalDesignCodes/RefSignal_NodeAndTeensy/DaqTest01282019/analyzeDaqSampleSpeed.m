basedir = 'C:\Users\tanne\Documents\Research\DaqTest01282019\';
testfiles = {'daqtest1.txt', 'daqtest2.txt', 'daqtest3.txt'};
timefiles = {'daqtest1_times.txt', 'daqtest2_times.txt', 'daqtest3_times.txt'};

nMeas = [];
alldt = [];
for i = 1:length(testfiles)
    data = load(fullfile(basedir, testfiles{i}));   

    intchan = data(:,8);
    intchanzero = intchan == 0;
    firstind = find(intchanzero, 1, 'first');
    intchan = intchan(firstind:end);

    for intnum = 0:1:58
        intchanbool = (intchan == intnum);
        nMeas(end+1) = sum(intchanbool);
    end

    % times
    tdata = load(fullfile(basedir, timefiles{i}));
    t = tdata(:, 2);
    t = t - t(1);
    

    dt = [];
    for j = 2:length(t)
        dt(j-1) = t(j) - t(j-1);
    end
    alldt(end+1:end+length(t)-1) = dt;
end



hist(nMeas)
measSamplesMean = mean(nMeas)
measSamplesStd = std(nMeas)

% dt
meanTimeBetweenNewInt = mean(alldt)
stdTimeBetweenNewInt = std(alldt)