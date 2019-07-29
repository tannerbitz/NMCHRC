basedir = 'C:\Users\tanne\Documents\Research\DaqTest01282019';
files = {'teensysetuptest1.txt','teensysetuptest2.txt','teensysetuptest3.txt'};

data1 = load(fullfile(basedir, files{1}));
data2 = load(fullfile(basedir, files{2}));
data3 = load(fullfile(basedir, files{3}));

refdata1 = data1(:,2);
refdata2 = data2(:,2);
refdata3 = data3(:,2);

figure(1);
plot(refdata3)


% Teensy test --- teensysetuptest3.txt
% Start/Stop Indices
%
% First cycle
% 1473
% 6472
% 
% Second Cycle
% 11473
% 16472
% 
% Third Cycle
% 21472
% 26471

%% File with raised floor
file = 'teensysetuptest4.txt';
data = load(fullfile(basedir,file));
figure(2)
plot(data(:,2))


% 12076 12179 12282