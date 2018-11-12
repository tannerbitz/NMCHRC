% Patient 17 Data Analysis Script
addpath ../DataAnalysis/;  % add path to data analysis functions

matfile = 'Pat17MVC.mat';
Pat17PF = cell(1);
% PF - 0.25Hz 
Pat17PF{1} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_0-25Hz_Trial1.txt');
Pat17PF{2} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_0-25Hz_Trial2.txt');
Pat17PF{3} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_0-25Hz_Trial3.txt');
% PF - 0.50Hz
Pat17PF{4} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_0-50Hz_Trial1.txt');
Pat17PF{5} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_0-50Hz_Trial2.txt');
Pat17PF{6} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_0-50Hz_Trial3.txt');
% PF - 0.75Hz
Pat17PF{7} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_0-75Hz_Trial1.txt');
Pat17PF{8} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_0-75Hz_Trial2.txt');
Pat17PF{9} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_0-75Hz_Trial3.txt');
% PF - 1.00Hz
Pat17PF{10} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_1-00Hz_Trial1.txt');
Pat17PF{11} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_1-00Hz_Trial2.txt');
Pat17PF{12} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_1-00Hz_Trial3.txt');
% PF - 1.25Hz 
Pat17PF{13} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_1-25Hz_Trial1.txt');
Pat17PF{14} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_1-25Hz_Trial2.txt');
Pat17PF{15} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_1-25Hz_Trial3.txt');
% PF - 1.50Hz
Pat17PF{16} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_1-50Hz_Trial1.txt');
Pat17PF{17} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_1-50Hz_Trial2.txt');
Pat17PF{18} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_1-50Hz_Trial3.txt');
% PF - 1.75Hz
Pat17PF{19} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_1-75Hz_Trial1.txt');
Pat17PF{20} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_1-75Hz_Trial2.txt');
Pat17PF{21} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_1-75Hz_Trial3.txt');
% PF - 2.00Hz
%Pat17PF{22} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_2-00Hz_Trial1.txt');
Pat17PF{23} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_2-00Hz_Trial2.txt');
Pat17PF{24} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_PF_2-00Hz_Trial3.txt');

for i = 1:length(Pat17PF)
    fprintf('PF %i\n', i)
    Pat17PF{i}.magphase = getMagPhase(Pat17PF{i}.nomrefcycle_nm, Pat17PF{i}.nommeascycle_nm);
end

save('Pat1PF_dataanalysis', 'Pat17PF')

%  DF
% DF - 0.25Hz 
Pat17DF{1} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_0-25Hz_Trial1.txt');
Pat17DF{2} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_0-25Hz_Trial2.txt');
Pat17DF{3} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_0-25Hz_Trial3.txt');
% DF - 0.50Hz
Pat17DF{4} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_0-50Hz_Trial1.txt');
Pat17DF{5} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_0-50Hz_Trial2.txt');
Pat17DF{6} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_0-50Hz_Trial3.txt');
% DF - 0.75Hz
Pat17DF{7} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_0-75Hz_Trial1.txt');
Pat17DF{8} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_0-75Hz_Trial2.txt');
Pat17DF{9} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_0-75Hz_Trial3.txt');
% DF - 1.00Hz
Pat17DF{10} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_1-00Hz_Trial1.txt');
Pat17DF{11} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_1-00Hz_Trial2.txt');
Pat17DF{12} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_1-00Hz_Trial3.txt');
% DF - 1.25Hz 
Pat17DF{13} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_1-25Hz_Trial1.txt');
Pat17DF{14} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_1-25Hz_Trial2.txt');
Pat17DF{15} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_1-25Hz_Trial3.txt');
% DF - 1.50Hz
Pat17DF{16} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_1-50Hz_Trial1.txt');
Pat17DF{17} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_1-50Hz_Trial2.txt');
Pat17DF{18} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_1-50Hz_Trial3.txt');
% DF - 1.75Hz
Pat17DF{19} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_1-75Hz_Trial1.txt');
Pat17DF{20} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_1-75Hz_Trial2.txt');
Pat17DF{21} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_1-75Hz_Trial3.txt');
% DF - 2.00Hz
Pat17DF{22} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_2-00Hz_Trial1.txt');
Pat17DF{23} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_2-00Hz_Trial2.txt');
Pat17DF{24} = analyzedata('matfile', matfile, 'vrfile', 'PatNo17_VR_AnklePosNeutral_DF_2-00Hz_Trial3.txt');

for i = 1:length(Pat17DF)
    fprintf('DF %i\n', i)
    Pat17DF{i}.magphase = getMagPhase(Pat17DF{i}.nomrefcycle_nm, Pat17DF{i}.nommeascycle_nm);
end

save('Pat17DF_dataanalysis', 'Pat17DF')

