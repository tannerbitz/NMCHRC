% Patient Data Analysis Script

path2add = sprintf('../Pat%s/', patNum);
addpath(path2add);  % add path to data analysis functions

matfile = sprintf('Pat%sMVC.mat', patNum);
PatPF = cell(1);

freq = {'0-20', '0-40', '0-60', '0-80', '1-00', '1-20', '1-40', '1-60', '1-80', '2-00'};

%PF
for i = 0:length(freq) - 1
    fname1 = sprintf('PatNo%s_VR_AnklePosNeutral_PF_%sHz_Trial%i.txt', patNum, freq{i+1}, 1);
    fname2 = sprintf('PatNo%s_VR_AnklePosNeutral_PF_%sHz_Trial%i.txt', patNum, freq{i+1}, 2);
    fname3 = sprintf('PatNo%s_VR_AnklePosNeutral_PF_%sHz_Trial%i.txt', patNum, freq{i+1}, 3);
    fname4 = sprintf('PatNo%s_VR_AnklePosNeutral_PF_%sHz_Trial%i.txt', patNum, freq{i+1}, 4);

    PatPF{i*3 + 1} = analyzedata_randomtrials('matfile', matfile, 'vrfile', fname1);
    PatPF{i*3 + 2} = analyzedata_randomtrials('matfile', matfile, 'vrfile', fname2);
    PatPF{i*3 + 3} = analyzedata_randomtrials('matfile', matfile, 'vrfile', fname3);
    PatPF{i*3 + 4} = analyzedata_randomtrials('matfile', matfile, 'vrfile', fname4);
end

for i = 1:length(PatPF)
    fprintf('PF %i\n', i)
    PatPF{i}.magphase = getMagPhase(PatPF{i}.nomrefcycle_nm, PatPF{i}.nommeascycle_nm);
end

pfvarname = sprintf('Pat%sPF', patNum);
assignin('base', pfvarname, PatPF);
patmatfile = sprintf('Pat%sPF_dataanalysis', patNum);
save(patmatfile, pfvarname)

%  DF
PatDF = cell(1);
for i = 0:length(freq) - 1
    fname1 = sprintf('PatNo%s_VR_AnklePosNeutral_DF_%sHz_Trial%i.txt', patNum, freq{i+1}, 1);
    fname2 = sprintf('PatNo%s_VR_AnklePosNeutral_DF_%sHz_Trial%i.txt', patNum, freq{i+1}, 2);
    fname3 = sprintf('PatNo%s_VR_AnklePosNeutral_DF_%sHz_Trial%i.txt', patNum, freq{i+1}, 3);
    fname4 = sprintf('PatNo%s_VR_AnklePosNeutral_DF_%sHz_Trial%i.txt', patNum, freq{i+1}, 4);

    PatDF{i*3 + 1} = analyzedata_randomtrials('matfile', matfile, 'vrfile', fname1);
    PatDF{i*3 + 2} = analyzedata_randomtrials('matfile', matfile, 'vrfile', fname2);
    PatDF{i*3 + 3} = analyzedata_randomtrials('matfile', matfile, 'vrfile', fname3);
    PatDF{i*3 + 4} = analyzedata_randomtrials('matfile', matfile, 'vrfile', fname4);
end

for i = 1:length(PatDF)
    fprintf('DF %i\n', i)
    PatDF{i}.magphase = getMagPhase(PatDF{i}.nomrefcycle_nm, PatDF{i}.nommeascycle_nm);
end

dfvarname = sprintf('Pat%sDF', patNum);
assignin('base', dfvarname, PatDF);
patmatfile = sprintf('Pat%sDF_dataanalysis', patNum);
save(patmatfile, dfvarname)

