% Patient 18 Data Analysis Script
addpath ../DataAnalysis/;  % add path to data analysis functions

matfile = 'Pat18MVC.mat';
Pat18PF = cell(1);
% PF - 0.25Hz 
Pat18PF{1} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_0-25Hz_Trial1.txt');
Pat18PF{2} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_0-25Hz_Trial2.txt');
Pat18PF{3} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_0-25Hz_Trial3.txt');
% PF - 0.50Hz
Pat18PF{4} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_0-50Hz_Trial1.txt');
Pat18PF{5} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_0-50Hz_Trial2.txt');
Pat18PF{6} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_0-50Hz_Trial3.txt');
% PF - 0.75Hz
Pat18PF{7} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_0-75Hz_Trial1.txt');
Pat18PF{8} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_0-75Hz_Trial2.txt');
Pat18PF{9} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_0-75Hz_Trial3.txt');
% PF - 1.00Hz
Pat18PF{10} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_1-00Hz_Trial1.txt');
Pat18PF{11} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_1-00Hz_Trial2.txt');
Pat18PF{12} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_1-00Hz_Trial3.txt');
% PF - 1.25Hz 
Pat18PF{13} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_1-25Hz_Trial1.txt');
Pat18PF{14} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_1-25Hz_Trial2.txt');
Pat18PF{15} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_1-25Hz_Trial3.txt');
% PF - 1.50Hz
Pat18PF{16} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_1-50Hz_Trial1.txt');
Pat18PF{17} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_1-50Hz_Trial2.txt');
Pat18PF{18} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_1-50Hz_Trial3.txt');
% PF - 1.75Hz
Pat18PF{19} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_1-75Hz_Trial1.txt');
Pat18PF{20} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_1-75Hz_Trial2.txt');
Pat18PF{21} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_1-75Hz_Trial3.txt');
% PF - 2.00Hz
Pat18PF{22} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_2-00Hz_Trial1.txt');
Pat18PF{23} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_2-00Hz_Trial2.txt');
Pat18PF{24} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_PF_2-00Hz_Trial3.txt');

for i = 1:length(Pat18PF)
    fprintf('PF %i\n', i)
    Pat18PF{i}.magphase = getMagPhase(Pat18PF{i}.nomrefcycle_nm, Pat18PF{i}.nommeascycle_nm);
end

save('Pat18PF_dataanalysis', 'Pat18PF')

%  DF
% DF - 0.25Hz 
Pat18DF{1} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_0-25Hz_Trial1.txt');
Pat18DF{2} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_0-25Hz_Trial2.txt');
Pat18DF{3} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_0-25Hz_Trial3.txt');
% DF - 0.50Hz
Pat18DF{4} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_0-50Hz_Trial1.txt');
Pat18DF{5} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_0-50Hz_Trial2.txt');
Pat18DF{6} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_0-50Hz_Trial3.txt');
% DF - 0.75Hz
Pat18DF{7} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_0-75Hz_Trial1.txt');
Pat18DF{8} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_0-75Hz_Trial2.txt');
Pat18DF{9} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_0-75Hz_Trial3.txt');
% DF - 1.00Hz
Pat18DF{10} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_1-00Hz_Trial1.txt');
Pat18DF{11} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_1-00Hz_Trial2.txt');
Pat18DF{12} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_1-00Hz_Trial3.txt');
% DF - 1.25Hz 
Pat18DF{13} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_1-25Hz_Trial1.txt');
Pat18DF{14} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_1-25Hz_Trial2.txt');
Pat18DF{15} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_1-25Hz_Trial3.txt');
% DF - 1.50Hz
Pat18DF{16} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_1-50Hz_Trial1.txt');
Pat18DF{17} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_1-50Hz_Trial2.txt');
Pat18DF{18} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_1-50Hz_Trial3.txt');
% DF - 1.75Hz
Pat18DF{19} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_1-75Hz_Trial1.txt');
Pat18DF{20} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_1-75Hz_Trial2.txt');
Pat18DF{21} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_1-75Hz_Trial3.txt');
% DF - 2.00Hz
Pat18DF{22} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_2-00Hz_Trial1.txt');
Pat18DF{23} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_2-00Hz_Trial2.txt');
Pat18DF{24} = analyzedata('matfile', matfile, 'vrfile', 'PatNo18_VR_AnklePosNeutral_DF_2-00Hz_Trial3.txt');

for i = 1:length(Pat18DF)
    fprintf('DF %i\n', i)
    Pat18DF{i}.magphase = getMagPhase(Pat18DF{i}.nomrefcycle_nm, Pat18DF{i}.nommeascycle_nm);
end

save('Pat18DF_dataanalysis', 'Pat18DF')

