% Patient 15 Data Analysis Script
addpath ../DataAnalysis/;  % add path to data analysis functions

matfile = 'Pat15MVC.mat';
Pat15PF = cell(1);
% PF - 0.25Hz 
Pat15PF{1} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_0-25Hz_Trial1.txt');
Pat15PF{2} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_0-25Hz_Trial2.txt');
Pat15PF{3} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_0-25Hz_Trial3.txt');
% PF - 0.50Hz
Pat15PF{4} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_0-50Hz_Trial1.txt');
Pat15PF{5} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_0-50Hz_Trial2.txt');
Pat15PF{6} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_0-50Hz_Trial3.txt');
% PF - 0.75Hz
Pat15PF{7} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_0-75Hz_Trial1.txt');
Pat15PF{8} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_0-75Hz_Trial2.txt');
Pat15PF{9} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_0-75Hz_Trial3.txt');
% PF - 1.00Hz
Pat15PF{10} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_1-00Hz_Trial1.txt');
Pat15PF{11} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_1-00Hz_Trial2.txt');
Pat15PF{12} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_1-00Hz_Trial3.txt');
% PF - 1.25Hz 
Pat15PF{13} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_1-25Hz_Trial1.txt');
Pat15PF{14} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_1-25Hz_Trial2.txt');
Pat15PF{15} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_1-25Hz_Trial3.txt');
% PF - 1.50Hz
Pat15PF{16} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_1-50Hz_Trial1.txt');
Pat15PF{17} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_1-50Hz_Trial2.txt');
Pat15PF{18} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_1-50Hz_Trial3.txt');
% PF - 1.75Hz
Pat15PF{19} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_1-75Hz_Trial1.txt');
Pat15PF{20} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_1-75Hz_Trial2.txt');
Pat15PF{21} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_1-75Hz_Trial3.txt');
% PF - 2.00Hz
Pat15PF{22} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_2-00Hz_Trial1.txt');
Pat15PF{23} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_2-00Hz_Trial2.txt');
Pat15PF{24} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_PF_2-00Hz_Trial3.txt');

for i = 1:length(Pat15PF)
    fprintf('PF %i\n', i)
    Pat15PF{i}.magphase = getMagPhase(Pat15PF{i}.nomrefcycle_nm, Pat15PF{i}.nommeascycle_nm);
end

save('Pat15PF_dataanalysis', 'Pat15PF')

%  DF
% DF - 0.25Hz 
Pat15DF{1} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_0-25Hz_Trial1.txt');
Pat15DF{2} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_0-25Hz_Trial2.txt');
Pat15DF{3} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_0-25Hz_Trial3.txt');
% DF - 0.50Hz
Pat15DF{4} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_0-50Hz_Trial1.txt');
Pat15DF{5} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_0-50Hz_Trial2.txt');
Pat15DF{6} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_0-50Hz_Trial3.txt');
% DF - 0.75Hz
Pat15DF{7} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_0-75Hz_Trial1.txt');
Pat15DF{8} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_0-75Hz_Trial2.txt');
Pat15DF{9} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_0-75Hz_Trial3.txt');
% DF - 1.00Hz
Pat15DF{10} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_1-00Hz_Trial1.txt');
Pat15DF{11} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_1-00Hz_Trial2.txt');
Pat15DF{12} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_1-00Hz_Trial3.txt');
% DF - 1.25Hz 
Pat15DF{13} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_1-25Hz_Trial1.txt');
Pat15DF{14} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_1-25Hz_Trial2.txt');
Pat15DF{15} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_1-25Hz_Trial3.txt');
% DF - 1.50Hz
Pat15DF{16} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_1-50Hz_Trial1.txt');
Pat15DF{17} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_1-50Hz_Trial2.txt');
Pat15DF{18} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_1-50Hz_Trial3.txt');
% DF - 1.75Hz
Pat15DF{19} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_1-75Hz_Trial1.txt');
Pat15DF{20} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_1-75Hz_Trial2.txt');
Pat15DF{21} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_1-75Hz_Trial3.txt');
% DF - 2.00Hz
Pat15DF{22} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_2-00Hz_Trial1.txt');
Pat15DF{23} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_2-00Hz_Trial2.txt');
Pat15DF{24} = analyzedata('matfile', matfile, 'vrfile', 'PatNo15_VR_AnklePosNeutral_DF_2-00Hz_Trial3.txt');

for i = 1:length(Pat15DF)
    fprintf('DF %i\n', i)
    Pat15DF{i}.magphase = getMagPhase(Pat15DF{i}.nomrefcycle_nm, Pat15DF{i}.nommeascycle_nm);
end

save('Pat15DF_dataanalysis', 'Pat15DF')

