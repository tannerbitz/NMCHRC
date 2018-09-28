data = load('AB_LCtest1.txt');

%%
meas = data(:,1);
measstd = zeros(size(meas));
measdiff = zeros(size(meas));
for i = 100:length(meas)
    measstd(i) = std(meas(i-99:i));
end
%measdiff(2:end) = diff(meas);

zs = GetZeroSection(meas)


