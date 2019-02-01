basedir = 'C:\Users\tanne\Documents\Research\DaqTest01282019';
file = 'nodemcutest3.txt';

data = load(fullfile(basedir, file));
refdata = data(:,2);


[Y1, I1] = max(refdata(10000:12500));
[Y2, I2] = max(refdata(15000:20000));
[Y3, I3] = max(refdata(20000:22500));
[Y4, I4] = max(refdata(25000:30000));

I1 = I1+10000;
I2 = I2+15000;
I3 = I3+20000;
I4 = I4+25000;

close all
figure(1)
plot(refdata);
hold on
plot([I1, I1+1], [0, Y1], 'r');
plot([I2, I2+1], [0, Y2], 'r');
plot([I3, I3+1], [0, Y3], 'r');
plot([I4, I4+1], [0, Y4], 'r');
hold off

% After looking at it carefully in command window:
% Interval 1
% start: 10870  end: 15859  samples (inclusive): 4990

% Interval 2
% start: 20869  end: 25860  samples (inclusive): 4992

%% 
indchan = data(:,8);
indchan2 = (indchan == 2);
indchan2start = find(indchan2, 1, 'first')