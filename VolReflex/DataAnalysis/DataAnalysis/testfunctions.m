data = load('~/Documents/Research/VolReflexData/Pat50/RawData/PatNo50_VR_AnklePosNeutral_DF_0-20Hz_Trial1.txt');

refdata = data(:,2);
refmax = max(refdata);

freq = 0.2;
samplespersec = 1000;
sampletime = 1/samplespersec;

samplespercycle = ceil((1/freq)*1000);
sinetime = (1:1:samplespercycle)*sampletime;
sinewave = refmax/2 - refmax/2*cos(2*pi*freq*sinetime);

norm_hist = [];
startind = 9000;

for i = 1:2*samplespersec
    tempsinestart = startind+i;
    refdatatemp = refdata(tempsinestart:tempsinestart+samplespercycle-1)';
    norm_hist(i) = norm(sinewave - refdatatemp);
end

[Y, I] = min(norm_hist);
tempsine = zeros(1,startind + I + samplespercycle - 1);
tempsine(startind+I:startind+I+samplespercycle-1) = sinewave;

clear figure1
figure(1)
plot(refdata);
hold on
plot(tempsine);
hold off


%%
folder = '~/Documents/Research/VolReflexData/Pat52/RawData';
files = ls(folder);
files = splitlines(files);

re = 'PatNo\d+.*[D|P]F_\d-\d+Hz.*\.txt';
% re = 'PatNo\d+.*[D|P]F_.*\.txt';
keep = {};
for i = 1:length(files)
    temp = regexp(files{i}, re, 'match');
    if ~isempty(temp)
        keep{end+1} = temp{1};
    end
end
keep
    
    