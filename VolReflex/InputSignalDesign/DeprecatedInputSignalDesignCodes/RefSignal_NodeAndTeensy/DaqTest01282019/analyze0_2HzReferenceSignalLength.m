pat50path = 'D:\VolReflexData\Pat50\RawData\';
pat50files = {'PatNo50_VR_AnklePosNeutral_DF_0-20Hz_Trial1.txt',
              'PatNo50_VR_AnklePosNeutral_DF_0-20Hz_Trial2.txt',
              'PatNo50_VR_AnklePosNeutral_DF_0-20Hz_Trial3.txt',
              'PatNo50_VR_AnklePosNeutral_DF_0-20Hz_Trial4.txt',
              'PatNo50_VR_AnklePosNeutral_DF_0-20Hz_Trial5.txt',
              'PatNo50_VR_AnklePosNeutral_DF_0-20Hz_Trial6.txt'};
pat51path = 'D:\VolReflexData\Pat51\RawData\';
pat51files = {'PatNo51_VR_AnklePosNeutral_DF_0-20Hz_Trial1.txt',
              'PatNo51_VR_AnklePosNeutral_DF_0-20Hz_Trial2.txt',
              'PatNo51_VR_AnklePosNeutral_DF_0-20Hz_Trial3.txt',
              'PatNo51_VR_AnklePosNeutral_DF_0-20Hz_Trial4.txt'};
pat52path = 'D:\VolReflexData\Pat52\RawData\';
pat52files = {'PatNo52_VR_AnklePosNeutral_DF_0-20Hz_Trial2.txt',
              'PatNo52_VR_AnklePosNeutral_DF_0-20Hz_Trial3.txt',
              'PatNo52_VR_AnklePosNeutral_DF_0-20Hz_Trial4.txt'};

files = {};
for i = 1:length(pat50files)
    files{end+1} = fullfile(pat50path, pat50files{i});
end
for i = 1:length(pat51files)
    files{end+1} = fullfile(pat51path, pat51files{i});
end
for i = 1:length(pat52files)
    files{end+1} = fullfile(pat52path, pat52files{i});
end


nSamplesPerCycle = [];

for iFile = 1:length(files)
    data = load(files{iFile});
    measdata = data(:, 1);
    refdata = data(:, 2);

    refdata1 = refdata(1:20000);

    sinesamples = 5000;

    indstart = 1;
    indstop = 20000;

    firstnonzero = [];
    lastnonzero = [];
    for i = 1:6
        iszeroread = refdata1 ~= 0;
        firstnonzero(end + 1) = find(iszeroread, 1, 'first') + indstart - 1;
        lastnonzero(end + 1) = find(iszeroread, 1, 'last') + indstart - 1;

        indstart = lastnonzero(end) + 4000;
        indstop = lastnonzero(end) + 7000 + sinesamples;
        if i < 6
            refdata1 = refdata(indstart:indstop);
        end
    end

    nSamplesPerCycle(end+1:end+6) = lastnonzero - firstnonzero;

    
    
    maxv = max(refdata);

    figure(1);
    plot(refdata);
    hold on
    for i = 1:6
        plot([firstnonzero(i), firstnonzero(i)+1], [0, maxv], 'r');
        plot([lastnonzero(i), lastnonzero(i)+1], [0, maxv], 'r');   
    end
    hold off
end

m = mean(nSamplesPerCycle)
s = std(nSamplesPerCycle)


