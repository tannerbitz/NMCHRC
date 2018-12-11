clear;
clc;
close all;

% design Butterworth Filter - 4th order, 5Hz cuttoff
[B, A] = butter(4, 0.01);
[B3, A3] = butter(5, 0.006);

loadtest1 = load('loadcelltest7.txt');
test1 = loadtest1(:,1);
test1_filter = filter(B, A, test1);
test1_filter3 = filter(B3, A3, test1);

figure(1);
plot(test1);
hold on
plot(test1_filter);
plot(test1_filter3, 'g');
hold off
legend('raw', '5Hz cuttoff', '3Hz cuttoff');
ylim([-80,120]);

loadtest2 = load('loadcelltest8.txt');
test2 = loadtest2(:,1);
test2_filter = filter(B, A, test2);
test2_filter3 = filter(B3, A3, test2);

figure(2);
hold on
plot(test2)
plot(test2_filter);
plot(test2_filter3, 'g');
legend('raw', '5Hz cuttoff', '3Hz cuttoff');
hold off


loadtest3 = load('loadcelltest9.txt');
test3 = loadtest3(:,1);
test3_filter = filter(B, A, test3);
test3_filter3 = filter(B3, A3, test3);

figure(3);
hold on
plot(test3)
plot(test3_filter);
plot(test3_filter3, 'g');
legend('raw', '5Hz cuttoff', '3Hz cuttoff');
hold off
ylim([-80,120]);