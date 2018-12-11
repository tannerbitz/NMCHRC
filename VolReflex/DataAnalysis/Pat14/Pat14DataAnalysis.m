% Patient 14 Data Analysis Script
addpath ../DataAnalysis/;  % add path to data analysis functions

matfile = 'Pat17MVC.mat';
Pat14PF = cell(1);
% PF - 0.25Hz 
Pat14PF{1} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_0-25Hz_Trial1.txt');
Pat14PF{2} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_0-25Hz_Trial2.txt');
Pat14PF{3} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_0-25Hz_Trial3.txt');
% PF - 0.50Hz
Pat14PF{4} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_0-50Hz_Trial1.txt');
Pat14PF{5} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_0-50Hz_Trial2.txt');
Pat14PF{6} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_0-50Hz_Trial3.txt');
% PF - 0.75Hz
Pat14PF{7} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_0-75Hz_Trial1.txt');
Pat14PF{8} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_0-75Hz_Trial2.txt');
Pat14PF{9} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_0-75Hz_Trial3.txt');
% PF - 1.00Hz
Pat14PF{10} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_1-00Hz_Trial1.txt');
Pat14PF{11} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_1-00Hz_Trial2.txt');
Pat14PF{12} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_1-00Hz_Trial3.txt');
% PF - 1.25Hz 
Pat14PF{13} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_1-25Hz_Trial1.txt');
Pat14PF{14} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_1-25Hz_Trial2.txt');
Pat14PF{15} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_1-25Hz_Trial3.txt');
% PF - 1.50Hz
Pat14PF{16} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_1-50Hz_Trial1.txt');
Pat14PF{17} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_1-50Hz_Trial2.txt');
Pat14PF{18} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_1-50Hz_Trial3.txt');
% PF - 1.75Hz
Pat14PF{19} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_1-75Hz_Trial1.txt');
Pat14PF{20} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_1-75Hz_Trial2.txt');
Pat14PF{21} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_1-75Hz_Trial3.txt');
% PF - 2.00Hz
Pat14PF{22} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_2-00Hz_Trial1.txt');
Pat14PF{23} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_2-00Hz_Trial2.txt');
Pat14PF{24} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_PF_2-00Hz_Trial3.txt');

for i = 1:length(Pat14PF)
    fprintf('PF %i\n', i)
    Pat14PF{i}.magphase = getMagPhase(Pat14PF{i}.nomrefcycle_nm, Pat14PF{i}.nommeascycle_nm);
end

save('Pat14PF_dataanalysis', 'Pat14PF')

%  DF
% DF - 0.25Hz 
Pat14DF{1} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_0-25Hz_Trial1.txt');
Pat14DF{2} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_0-25Hz_Trial2.txt');
Pat14DF{3} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_0-25Hz_Trial3.txt');
% DF - 0.50Hz
Pat14DF{4} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_0-50Hz_Trial1.txt');
Pat14DF{5} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_0-50Hz_Trial2.txt');
Pat14DF{6} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_0-50Hz_Trial3.txt');
% DF - 0.75Hz
Pat14DF{7} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_0-75Hz_Trial1.txt');
Pat14DF{8} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_0-75Hz_Trial2.txt');
Pat14DF{9} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_0-75Hz_Trial3.txt');
% DF - 1.00Hz
Pat14DF{10} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_1-00Hz_Trial1.txt');
Pat14DF{11} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_1-00Hz_Trial2.txt');
Pat14DF{12} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_1-00Hz_Trial3.txt');
% DF - 1.25Hz 
Pat14DF{13} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_1-25Hz_Trial1.txt');
Pat14DF{14} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_1-25Hz_Trial2.txt');
Pat14DF{15} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_1-25Hz_Trial3.txt');
% DF - 1.50Hz
Pat14DF{16} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_1-50Hz_Trial1.txt');
Pat14DF{17} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_1-50Hz_Trial2.txt');
Pat14DF{18} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_1-50Hz_Trial3.txt');
% DF - 1.75Hz
Pat14DF{19} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_1-75Hz_Trial1.txt');
Pat14DF{20} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_1-75Hz_Trial2.txt');
Pat14DF{21} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_1-75Hz_Trial3.txt');
% DF - 2.00Hz
Pat14DF{22} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_2-00Hz_Trial1.txt');
Pat14DF{23} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_2-00Hz_Trial2.txt');
Pat14DF{24} = analyzedata('matfile', matfile, 'vrfile', 'PatNo14_VR_AnklePosNeutral_DF_2-00Hz_Trial3.txt');

for i = 1:length(Pat14DF)
    fprintf('DF %i\n', i)
    Pat14DF{i}.magphase = getMagPhase(Pat14DF{i}.nomrefcycle_nm, Pat14DF{i}.nommeascycle_nm);
end

save('Pat14DF_dataanalysis', 'Pat14DF')

