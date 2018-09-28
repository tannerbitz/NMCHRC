% Ankle Bot load cell data
data1 = load('AB_LCtest1.txt');
data2 = load('AB_LCtest2.txt');
data3 = load('AB_LCtest3.txt');
data4 = load('AB_LCtest4.txt');

% Our load cell data
data5 = load('loadcelltest7.txt');
data6 = load('loadcelltest8.txt');
data7 = load('loadcelltest9.txt');

data = data3; % the file to be analyzed 'data'


%%
meas = data(:,1);
measstd = zeros(size(meas));
measdiff = zeros(size(meas));
for i = 100:length(meas)
    measstd(i) = std(meas(i-99:i));
end
%measdiff(2:end) = diff(meas);

zs = GetZeroSection(meas)


