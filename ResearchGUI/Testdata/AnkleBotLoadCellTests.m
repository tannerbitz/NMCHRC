close all;
clc

t1 = load('AB_LCtest1.txt');
t2 = load('AB_LCtest2.txt');
t3 = load('AB_LCtest3.txt');
t4 = load('AB_LCtest4.txt');
ta1 = load('loadcelltest7.txt');
ta2 = load('loadcelltest8.txt');
ta3 = load('loadcelltest9.txt');

T1 = t1(:,1);
T2 = t2(:,1);
T3 = t3(:,1);
T4 = t4(:,1);

Ta1 = ta1(:,1);
Ta2 = ta2(:,1);
Ta3 = ta3(:,1);

%% Std

StdT1 = std(T1(3000:9000));
StdT2 = std(T2(3000:6000));
StdT3 = std(T3(7000:10000));
StdTa1 = std(Ta1(7000:10000));
StdTa2 = std(Ta2(2000:5000));
StdTa3 = std(Ta3(7000:10000));

%% Plotting
figure(1)
plot(T1)

figure(2)
plot(T2)

figure(3)
plot(T3)

figure(4)
plot(T4)

figure(5)
plot(Ta1)

figure(6)
plot(Ta2)

figure(7)
plot(Ta3)




