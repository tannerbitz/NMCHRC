data = load('TestDaqReadingsNoExternalI2C.txt');

data7 = data(:,7);
currNum = data(1);
cnt = 0;
for i = 1:length(data7)
    cnt = cnt + 1;
    if (data7(i) ~= currNum)
        fprintf("%d was found %d times\n", currNum, cnt)
        currNum = data7(i);
        cnt = 0;
    end
end

%% readings per cycle
readsPerCycle = data(:,8);
hist(readsPerCycle)

lessThanSixReadingsCnt = 0;
readingsLessThanSixReadingsList = [];
for i = 1:length(readsPerCycle)
    if (readsPerCycle(i) < 6)
        lessThanSixReadingsCnt = lessThanSixReadingsCnt + 1;
        readingsLessThanSixReadingsList = [readingsLessThanSixReadingsList, i];
    end
end

fprintf("There were less than six readings %d times\n", lessThanSixReadingsCnt)
fprintf("The indices at which these occurred are: ");
disp(readingsLessThanSixReadingsList)
