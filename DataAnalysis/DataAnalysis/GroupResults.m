clear;
clc;
close all;

addpath ../Pat14/
addpath ../Pat15/
addpath ../Pat16/
addpath ../Pat18/
addpath ../Pat17/

load('Pat14DF_dataanalysis.mat')
load('Pat14PF_dataanalysis.mat')
load('Pat15DF_dataanalysis.mat')
load('Pat15PF_dataanalysis.mat')
load('Pat16DF_dataanalysis.mat')
load('Pat16PF_dataanalysis.mat')
load('Pat17DF_dataanalysis.mat')
load('Pat17PF_dataanalysis.mat')
load('Pat18DF_dataanalysis.mat')
load('Pat18PF_dataanalysis.mat')

%% Dorsiflexion

% 0.25 Hz DF
Avg25DF = (Pat14DF{1,1}.nommeascycle_nm+Pat14DF{1,2}.nommeascycle_nm+Pat14DF{1,3}.nommeascycle_nm+...
          Pat15DF{1,1}.nommeascycle_nm+Pat15DF{1,2}.nommeascycle_nm+Pat15DF{1,3}.nommeascycle_nm+...
          Pat16DF{1,1}.nommeascycle_nm+Pat16DF{1,2}.nommeascycle_nm+Pat16DF{1,3}.nommeascycle_nm+...
          Pat17DF{1,1}.nommeascycle_nm+Pat17DF{1,2}.nommeascycle_nm+Pat17DF{1,3}.nommeascycle_nm+...
          Pat18DF{1,1}.nommeascycle_nm+Pat18DF{1,2}.nommeascycle_nm+Pat18DF{1,3}.nommeascycle_nm)/15;
      
AvgRef25DF = (Pat14DF{1,1}.nomrefcycle_nm+Pat14DF{1,2}.nomrefcycle_nm+Pat14DF{1,3}.nomrefcycle_nm+...
              Pat15DF{1,1}.nomrefcycle_nm+Pat15DF{1,2}.nomrefcycle_nm+Pat15DF{1,3}.nomrefcycle_nm+...
              Pat16DF{1,1}.nomrefcycle_nm+Pat16DF{1,2}.nomrefcycle_nm+Pat16DF{1,3}.nomrefcycle_nm+...
              Pat17DF{1,1}.nomrefcycle_nm+Pat17DF{1,2}.nomrefcycle_nm+Pat17DF{1,3}.nomrefcycle_nm+...
              Pat18DF{1,1}.nomrefcycle_nm+Pat18DF{1,2}.nomrefcycle_nm+Pat18DF{1,3}.nomrefcycle_nm)/15;

Err25DF = abs(AvgRef25DF-Avg25DF);
MeanErr25DF = mean(Err25DF);

DF25 = zeros(15,4000);
for i = 1:3
    
    DF25(i,:) = Pat14DF{1,i}.nommeascycle_nm;
    DF25(i+3,:) = Pat15DF{1,i}.nommeascycle_nm;
    DF25(i+6,:) = Pat16DF{1,i}.nommeascycle_nm;
    DF25(i+9,:) = Pat17DF{1,i}.nommeascycle_nm;
    DF25(i+12,:) = Pat18DF{1,i}.nommeascycle_nm;
    
end
StdDF25 = std(DF25);
AvgP1Std25DF = Avg25DF+StdDF25;
AvgM1Std25DF = Avg25DF-StdDF25;

figure(1)          
hold on 
plot(Avg25DF,'b')
plot(AvgRef25DF,'r')
plot(AvgP1Std25DF,'g')
plot(AvgM1Std25DF,'g')
legend('Measured','Reference','+/-1 Std Dev','HandleVisibility','off')
title('0.25 Hz Dorsiflexion')
xlabel('Time (ms)')
ylabel('Torque (N-m)')

% 0.5 Hz DF
Avg50DF = (Pat14DF{1,4}.nommeascycle_nm+Pat14DF{1,5}.nommeascycle_nm+Pat14DF{1,6}.nommeascycle_nm+...
           Pat15DF{1,4}.nommeascycle_nm+Pat15DF{1,5}.nommeascycle_nm+Pat15DF{1,6}.nommeascycle_nm+...
           Pat16DF{1,4}.nommeascycle_nm+Pat16DF{1,5}.nommeascycle_nm+Pat16DF{1,6}.nommeascycle_nm+...
           Pat17DF{1,4}.nommeascycle_nm+Pat17DF{1,5}.nommeascycle_nm+Pat17DF{1,6}.nommeascycle_nm+...
           Pat18DF{1,4}.nommeascycle_nm+Pat18DF{1,5}.nommeascycle_nm+Pat18DF{1,6}.nommeascycle_nm)/15;
      
AvgRef50DF = (Pat14DF{1,4}.nomrefcycle_nm+Pat14DF{1,5}.nomrefcycle_nm+Pat14DF{1,6}.nomrefcycle_nm+...
              Pat15DF{1,4}.nomrefcycle_nm+Pat15DF{1,5}.nomrefcycle_nm+Pat15DF{1,6}.nomrefcycle_nm+...
              Pat16DF{1,4}.nomrefcycle_nm+Pat16DF{1,5}.nomrefcycle_nm+Pat16DF{1,6}.nomrefcycle_nm+...
              Pat17DF{1,4}.nomrefcycle_nm+Pat17DF{1,5}.nomrefcycle_nm+Pat17DF{1,6}.nomrefcycle_nm+...
              Pat18DF{1,4}.nomrefcycle_nm+Pat18DF{1,5}.nomrefcycle_nm+Pat18DF{1,6}.nomrefcycle_nm)/15;

Err50DF = abs(AvgRef50DF-Avg50DF);
MeanErr50DF = mean(Err50DF);

DF50 = zeros(15,2000);
for i = 1:3
    
    DF50(i,:) = Pat14DF{1,i+3}.nommeascycle_nm;
    DF50(i+3,:) = Pat15DF{1,i+3}.nommeascycle_nm;
    DF50(i+6,:) = Pat16DF{1,i+3}.nommeascycle_nm;
    DF50(i+9,:) = Pat17DF{1,i+3}.nommeascycle_nm;
    DF50(i+12,:) = Pat18DF{1,i+3}.nommeascycle_nm;
    
end
StdDF50 = std(DF50);
AvgP1Std50DF = Avg50DF+StdDF50;
AvgM1Std50DF = Avg50DF-StdDF50;

figure(2)          
hold on 
plot(Avg50DF,'b')
plot(AvgRef50DF,'r')
plot(AvgP1Std50DF,'g')
plot(AvgM1Std50DF,'g')
legend('Measured','Reference','+/-1 Std Dev','HandleVisibility','off')
title('0.5 Hz Dorsiflexion')
xlabel('Time (ms)')
ylabel('Torque (N-m)')

% 0.75 Hz DF
Avg75DF = (Pat14DF{1,7}.nommeascycle_nm+Pat14DF{1,8}.nommeascycle_nm+Pat14DF{1,9}.nommeascycle_nm+...
           Pat15DF{1,7}.nommeascycle_nm+Pat15DF{1,8}.nommeascycle_nm+Pat15DF{1,9}.nommeascycle_nm+...
           Pat16DF{1,7}.nommeascycle_nm+Pat16DF{1,8}.nommeascycle_nm+Pat16DF{1,9}.nommeascycle_nm+...
           Pat17DF{1,7}.nommeascycle_nm+Pat17DF{1,8}.nommeascycle_nm+Pat17DF{1,9}.nommeascycle_nm+...
           Pat18DF{1,7}.nommeascycle_nm+Pat18DF{1,8}.nommeascycle_nm+Pat18DF{1,9}.nommeascycle_nm)/15;
      
AvgRef75DF = (Pat14DF{1,7}.nomrefcycle_nm+Pat14DF{1,8}.nomrefcycle_nm+Pat14DF{1,9}.nomrefcycle_nm+...
              Pat15DF{1,7}.nomrefcycle_nm+Pat15DF{1,8}.nomrefcycle_nm+Pat15DF{1,9}.nomrefcycle_nm+...
              Pat16DF{1,7}.nomrefcycle_nm+Pat16DF{1,8}.nomrefcycle_nm+Pat16DF{1,9}.nomrefcycle_nm+...
              Pat17DF{1,7}.nomrefcycle_nm+Pat17DF{1,8}.nomrefcycle_nm+Pat17DF{1,9}.nomrefcycle_nm+...
              Pat18DF{1,7}.nomrefcycle_nm+Pat18DF{1,8}.nomrefcycle_nm+Pat18DF{1,9}.nomrefcycle_nm)/15;

Err75DF = abs(AvgRef75DF-Avg75DF);
MeanErr75DF = mean(Err75DF);

DF75 = zeros(15,1333);
for i = 1:3
    
    DF75(i,:) = Pat14DF{1,i+6}.nommeascycle_nm;
    DF75(i+3,:) = Pat15DF{1,i+6}.nommeascycle_nm;
    DF75(i+6,:) = Pat16DF{1,i+6}.nommeascycle_nm;
    DF75(i+9,:) = Pat17DF{1,i+6}.nommeascycle_nm;
    DF75(i+12,:) = Pat18DF{1,i+6}.nommeascycle_nm;
    
end
StdDF75 = std(DF75);
AvgP1Std75DF = Avg75DF+StdDF75;
AvgM1Std75DF = Avg75DF-StdDF75;

figure(3)          
hold on 
plot(Avg75DF,'b')
plot(AvgRef75DF,'r')
plot(AvgP1Std75DF,'g')
plot(AvgM1Std75DF,'g')
legend('Measured','Reference','+/-1 Std Dev','HandleVisibility','off')
title('0.75 Hz Dorsiflexion')
xlabel('Time (ms)')
ylabel('Torque (N-m)')

% 1 Hz DF
Avg1DF = (Pat14DF{1,10}.nommeascycle_nm+Pat14DF{1,11}.nommeascycle_nm+Pat14DF{1,12}.nommeascycle_nm+...
          Pat15DF{1,10}.nommeascycle_nm+Pat15DF{1,11}.nommeascycle_nm+Pat15DF{1,12}.nommeascycle_nm+...
          Pat16DF{1,10}.nommeascycle_nm+Pat16DF{1,11}.nommeascycle_nm+Pat16DF{1,12}.nommeascycle_nm+...
          Pat17DF{1,10}.nommeascycle_nm+Pat17DF{1,11}.nommeascycle_nm+Pat17DF{1,12}.nommeascycle_nm+...
          Pat18DF{1,10}.nommeascycle_nm+Pat18DF{1,11}.nommeascycle_nm+Pat18DF{1,12}.nommeascycle_nm)/15;
      
AvgRef1DF = (Pat14DF{1,10}.nomrefcycle_nm+Pat14DF{1,11}.nomrefcycle_nm+Pat14DF{1,12}.nomrefcycle_nm+...
             Pat15DF{1,10}.nomrefcycle_nm+Pat15DF{1,11}.nomrefcycle_nm+Pat15DF{1,12}.nomrefcycle_nm+...
             Pat16DF{1,10}.nomrefcycle_nm+Pat16DF{1,11}.nomrefcycle_nm+Pat16DF{1,12}.nomrefcycle_nm+...
             Pat17DF{1,10}.nomrefcycle_nm+Pat17DF{1,11}.nomrefcycle_nm+Pat17DF{1,12}.nomrefcycle_nm+...
             Pat18DF{1,10}.nomrefcycle_nm+Pat18DF{1,11}.nomrefcycle_nm+Pat18DF{1,12}.nomrefcycle_nm)/15;

Err1DF = abs(AvgRef1DF-Avg1DF);
MeanErr1DF = mean(Err1DF);

DF1 = zeros(15,1000);
for i = 1:3
    
    DF1(i,:) = Pat14DF{1,i+9}.nommeascycle_nm;
    DF1(i+3,:) = Pat15DF{1,i+9}.nommeascycle_nm;
    DF1(i+6,:) = Pat16DF{1,i+9}.nommeascycle_nm;
    DF1(i+9,:) = Pat17DF{1,i+9}.nommeascycle_nm;
    DF1(i+12,:) = Pat18DF{1,i+9}.nommeascycle_nm;
    
end
StdDF1 = std(DF1);
AvgP1Std1DF = Avg1DF+StdDF1;
AvgM1Std1DF = Avg1DF-StdDF1;

figure(4)          
hold on 
plot(Avg1DF,'b')
plot(AvgRef1DF,'r')
plot(AvgP1Std1DF,'g')
plot(AvgM1Std1DF,'g')
legend('Measured','Reference','+/-1 Std Dev','HandleVisibility','off')
title('1 Hz Dorsiflexion')
xlabel('Time (ms)')
ylabel('Torque (N-m)')

% 1.25 Hz DF
Avg125DF = (Pat14DF{1,13}.nommeascycle_nm+Pat14DF{1,14}.nommeascycle_nm+Pat14DF{1,15}.nommeascycle_nm+...
          Pat15DF{1,13}.nommeascycle_nm+Pat15DF{1,14}.nommeascycle_nm+Pat15DF{1,15}.nommeascycle_nm+...
          Pat16DF{1,13}.nommeascycle_nm+Pat16DF{1,14}.nommeascycle_nm+Pat16DF{1,15}.nommeascycle_nm+...
          Pat17DF{1,13}.nommeascycle_nm+Pat17DF{1,14}.nommeascycle_nm+Pat17DF{1,15}.nommeascycle_nm+...
          Pat18DF{1,13}.nommeascycle_nm+Pat18DF{1,14}.nommeascycle_nm+Pat18DF{1,15}.nommeascycle_nm)/15;
      
AvgRef125DF = (Pat14DF{1,13}.nomrefcycle_nm+Pat14DF{1,14}.nomrefcycle_nm+Pat14DF{1,15}.nomrefcycle_nm+...
             Pat15DF{1,13}.nomrefcycle_nm+Pat15DF{1,14}.nomrefcycle_nm+Pat15DF{1,15}.nomrefcycle_nm+...
             Pat16DF{1,13}.nomrefcycle_nm+Pat16DF{1,14}.nomrefcycle_nm+Pat16DF{1,15}.nomrefcycle_nm+...
             Pat17DF{1,13}.nomrefcycle_nm+Pat17DF{1,14}.nomrefcycle_nm+Pat17DF{1,15}.nomrefcycle_nm+...
             Pat18DF{1,13}.nomrefcycle_nm+Pat18DF{1,14}.nomrefcycle_nm+Pat18DF{1,15}.nomrefcycle_nm)/15;

Err125DF = abs(AvgRef125DF-Avg125DF);
MeanErr125DF = mean(Err125DF);

DF125 = zeros(15,800);
for i = 1:3
    
    DF125(i,:) = Pat14DF{1,i+12}.nommeascycle_nm;
    DF125(i+3,:) = Pat15DF{1,i+12}.nommeascycle_nm;
    DF125(i+6,:) = Pat16DF{1,i+12}.nommeascycle_nm;
    DF125(i+9,:) = Pat17DF{1,i+12}.nommeascycle_nm;
    DF125(i+12,:) = Pat18DF{1,i+12}.nommeascycle_nm;
    
end
StdDF125 = std(DF125);
AvgP1Std125DF = Avg125DF+StdDF125;
AvgM1Std125DF = Avg125DF-StdDF125;

figure(5)          
hold on 
plot(Avg125DF,'b')
plot(AvgRef125DF,'r')
plot(AvgP1Std125DF,'g')
plot(AvgM1Std125DF,'g')
legend('Measured','Reference','+/-1 Std Dev','HandleVisibility','off')
title('1.25 Hz Dorsiflexion')
xlabel('Time (ms)')
ylabel('Torque (N-m)')

% 1.5 Hz DF
Avg15DF = (Pat14DF{1,16}.nommeascycle_nm+Pat14DF{1,17}.nommeascycle_nm+Pat14DF{1,18}.nommeascycle_nm+...
          Pat15DF{1,16}.nommeascycle_nm+Pat15DF{1,17}.nommeascycle_nm+Pat15DF{1,18}.nommeascycle_nm+...
          Pat16DF{1,16}.nommeascycle_nm+Pat16DF{1,17}.nommeascycle_nm+Pat16DF{1,18}.nommeascycle_nm+...
          Pat17DF{1,16}.nommeascycle_nm+Pat17DF{1,17}.nommeascycle_nm+Pat17DF{1,18}.nommeascycle_nm+...
          Pat18DF{1,16}.nommeascycle_nm+Pat18DF{1,17}.nommeascycle_nm+Pat18DF{1,18}.nommeascycle_nm)/15;
      
AvgRef15DF = (Pat14DF{1,16}.nomrefcycle_nm+Pat14DF{1,17}.nomrefcycle_nm+Pat14DF{1,18}.nomrefcycle_nm+...
             Pat15DF{1,16}.nomrefcycle_nm+Pat15DF{1,17}.nomrefcycle_nm+Pat15DF{1,18}.nomrefcycle_nm+...
             Pat16DF{1,16}.nomrefcycle_nm+Pat16DF{1,17}.nomrefcycle_nm+Pat16DF{1,18}.nomrefcycle_nm+...
             Pat17DF{1,16}.nomrefcycle_nm+Pat17DF{1,17}.nomrefcycle_nm+Pat17DF{1,18}.nomrefcycle_nm+...
             Pat18DF{1,16}.nomrefcycle_nm+Pat18DF{1,17}.nomrefcycle_nm+Pat18DF{1,18}.nomrefcycle_nm)/15;

Err15DF = abs(AvgRef15DF-Avg15DF);
MeanErr15DF = mean(Err15DF);

DF15 = zeros(15,666);
for i = 1:3
    
    DF15(i,:) = Pat14DF{1,i+15}.nommeascycle_nm;
    DF15(i+3,:) = Pat15DF{1,i+15}.nommeascycle_nm;
    DF15(i+6,:) = Pat16DF{1,i+15}.nommeascycle_nm;
    DF15(i+9,:) = Pat17DF{1,i+15}.nommeascycle_nm;
    DF15(i+12,:) = Pat18DF{1,i+15}.nommeascycle_nm;
    
end
StdDF15 = std(DF15);
AvgP1Std15DF = Avg15DF+StdDF15;
AvgM1Std15DF = Avg15DF-StdDF15;

figure(6)          
hold on 
plot(Avg15DF,'b')
plot(AvgRef15DF,'r')
plot(AvgP1Std15DF,'g')
plot(AvgM1Std15DF,'g')
legend('Measured','Reference','+/-1 Std Dev','HandleVisibility','off')
title('1.5 Hz Dorsiflexion')
xlabel('Time (ms)')
ylabel('Torque (N-m)')

% 1.75 Hz DF
Avg175DF = (Pat14DF{1,19}.nommeascycle_nm+Pat14DF{1,20}.nommeascycle_nm+Pat14DF{1,21}.nommeascycle_nm+...
          Pat15DF{1,19}.nommeascycle_nm+Pat15DF{1,20}.nommeascycle_nm+Pat15DF{1,21}.nommeascycle_nm+...
          Pat16DF{1,19}.nommeascycle_nm+Pat16DF{1,20}.nommeascycle_nm+Pat16DF{1,21}.nommeascycle_nm+...
          Pat17DF{1,19}.nommeascycle_nm+Pat17DF{1,20}.nommeascycle_nm+Pat17DF{1,21}.nommeascycle_nm+...
          Pat18DF{1,19}.nommeascycle_nm+Pat18DF{1,20}.nommeascycle_nm+Pat18DF{1,21}.nommeascycle_nm)/15;
      
AvgRef175DF = (Pat14DF{1,19}.nomrefcycle_nm+Pat14DF{1,20}.nomrefcycle_nm+Pat14DF{1,21}.nomrefcycle_nm+...
             Pat15DF{1,19}.nomrefcycle_nm+Pat15DF{1,20}.nomrefcycle_nm+Pat15DF{1,21}.nomrefcycle_nm+...
             Pat16DF{1,19}.nomrefcycle_nm+Pat16DF{1,20}.nomrefcycle_nm+Pat16DF{1,21}.nomrefcycle_nm+...
             Pat17DF{1,19}.nomrefcycle_nm+Pat17DF{1,20}.nomrefcycle_nm+Pat17DF{1,21}.nomrefcycle_nm+...
             Pat18DF{1,19}.nomrefcycle_nm+Pat18DF{1,20}.nomrefcycle_nm+Pat18DF{1,21}.nomrefcycle_nm)/15;

Err175DF = abs(AvgRef175DF-Avg175DF);
MeanErr175DF = mean(Err175DF);

DF175 = zeros(15,571);
for i = 1:3
    
    DF175(i,:) = Pat14DF{1,i+18}.nommeascycle_nm;
    DF175(i+3,:) = Pat15DF{1,i+18}.nommeascycle_nm;
    DF175(i+6,:) = Pat16DF{1,i+18}.nommeascycle_nm;
    DF175(i+9,:) = Pat17DF{1,i+18}.nommeascycle_nm;
    DF175(i+12,:) = Pat18DF{1,i+18}.nommeascycle_nm;
    
end
StdDF175 = std(DF175);
AvgP1Std175DF = Avg175DF+StdDF175;
AvgM1Std175DF = Avg175DF-StdDF175;

figure(7)          
hold on 
plot(Avg175DF,'b')
plot(AvgRef175DF,'r')
plot(AvgP1Std175DF,'g')
plot(AvgM1Std175DF,'g')
legend('Measured','Reference','+/-1 Std Dev','HandleVisibility','off')
title('1.75 Hz Dorsiflexion')
xlabel('Time (ms)')
ylabel('Torque (N-m)')

% 2 Hz DF
Avg2DF = (Pat14DF{1,22}.nommeascycle_nm+Pat14DF{1,23}.nommeascycle_nm+Pat14DF{1,24}.nommeascycle_nm+...
          Pat15DF{1,22}.nommeascycle_nm+Pat15DF{1,23}.nommeascycle_nm+Pat15DF{1,24}.nommeascycle_nm+...
          Pat16DF{1,22}.nommeascycle_nm+Pat16DF{1,23}.nommeascycle_nm+Pat16DF{1,24}.nommeascycle_nm+...
          Pat17DF{1,22}.nommeascycle_nm+Pat17DF{1,23}.nommeascycle_nm+Pat17DF{1,24}.nommeascycle_nm+...
          Pat18DF{1,22}.nommeascycle_nm+Pat18DF{1,23}.nommeascycle_nm+Pat18DF{1,24}.nommeascycle_nm)/15;
      
AvgRef2DF = (Pat14DF{1,22}.nomrefcycle_nm+Pat14DF{1,23}.nomrefcycle_nm+Pat14DF{1,24}.nomrefcycle_nm+...
             Pat15DF{1,22}.nomrefcycle_nm+Pat15DF{1,23}.nomrefcycle_nm+Pat15DF{1,24}.nomrefcycle_nm+...
             Pat16DF{1,22}.nomrefcycle_nm+Pat16DF{1,23}.nomrefcycle_nm+Pat16DF{1,24}.nomrefcycle_nm+...
             Pat17DF{1,22}.nomrefcycle_nm+Pat17DF{1,23}.nomrefcycle_nm+Pat17DF{1,24}.nomrefcycle_nm+...
             Pat18DF{1,22}.nomrefcycle_nm+Pat18DF{1,23}.nomrefcycle_nm+Pat18DF{1,24}.nomrefcycle_nm)/15;

Err2DF = abs(AvgRef2DF-Avg2DF);
MeanErr2DF = mean(Err2DF);

DF2 = zeros(15,500);
for i = 1:3
    
    DF2(i,:) = Pat14DF{1,i+21}.nommeascycle_nm;
    DF2(i+3,:) = Pat15DF{1,i+21}.nommeascycle_nm;
    DF2(i+6,:) = Pat16DF{1,i+21}.nommeascycle_nm;
    DF2(i+9,:) = Pat17DF{1,i+21}.nommeascycle_nm;
    DF2(i+12,:) = Pat18DF{1,i+21}.nommeascycle_nm;
    
end
StdDF2 = std(DF2);
AvgP1Std2DF = Avg2DF+StdDF2;
AvgM1Std2DF = Avg2DF-StdDF2;

figure(8)          
hold on 
plot(Avg2DF,'b')
plot(AvgRef2DF,'r')
plot(AvgP1Std2DF,'g')
plot(AvgM1Std2DF,'g')
legend('Measured','Reference','+/-1 Std Dev','HandleVisibility','off')
title('2 Hz Dorsiflexion')
xlabel('Time (ms)')
ylabel('Torque (N-m)')

%% Plantar Flexion

% 0.25 Hz PF
Avg25PF = (Pat14PF{1,1}.nommeascycle_nm+Pat14PF{1,2}.nommeascycle_nm+Pat14PF{1,3}.nommeascycle_nm+...
          Pat15PF{1,1}.nommeascycle_nm+Pat15PF{1,2}.nommeascycle_nm+Pat15PF{1,3}.nommeascycle_nm+...
          Pat16PF{1,1}.nommeascycle_nm+Pat16PF{1,2}.nommeascycle_nm+Pat16PF{1,3}.nommeascycle_nm+...
          Pat17PF{1,1}.nommeascycle_nm+Pat17PF{1,2}.nommeascycle_nm+Pat17PF{1,3}.nommeascycle_nm+...
          Pat18PF{1,1}.nommeascycle_nm+Pat18PF{1,2}.nommeascycle_nm+Pat18PF{1,3}.nommeascycle_nm)/15;
      
AvgRef25PF = (Pat14PF{1,1}.nomrefcycle_nm+Pat14PF{1,2}.nomrefcycle_nm+Pat14PF{1,3}.nomrefcycle_nm+...
              Pat15PF{1,1}.nomrefcycle_nm+Pat15PF{1,2}.nomrefcycle_nm+Pat15PF{1,3}.nomrefcycle_nm+...
              Pat16PF{1,1}.nomrefcycle_nm+Pat16PF{1,2}.nomrefcycle_nm+Pat16PF{1,3}.nomrefcycle_nm+...
              Pat17PF{1,1}.nomrefcycle_nm+Pat17PF{1,2}.nomrefcycle_nm+Pat17PF{1,3}.nomrefcycle_nm+...
              Pat18PF{1,1}.nomrefcycle_nm+Pat18PF{1,2}.nomrefcycle_nm+Pat18PF{1,3}.nomrefcycle_nm)/15;

Err25PF = abs(AvgRef25PF-Avg25PF);
MeanErr25PF = mean(Err25PF);

PF25 = zeros(15,4000);
for i = 1:3
    
    PF25(i,:) = Pat14PF{1,i}.nommeascycle_nm;
    PF25(i+3,:) = Pat15PF{1,i}.nommeascycle_nm;
    PF25(i+6,:) = Pat16PF{1,i}.nommeascycle_nm;
    PF25(i+9,:) = Pat17PF{1,i}.nommeascycle_nm;
    PF25(i+12,:) = Pat18PF{1,i}.nommeascycle_nm;
    
end
StdPF25 = std(PF25);
AvgP1Std25PF = Avg25PF+StdPF25;
AvgM1Std25PF = Avg25PF-StdPF25;

figure(9)          
hold on 
plot(Avg25PF,'b')
plot(AvgRef25PF,'r')
plot(AvgP1Std25PF,'g')
plot(AvgM1Std25PF,'g')
legend('Measured','Reference','+/-1 Std Dev','HandleVisibility','off')
title('0.25 Hz Plantar Flexion')
xlabel('Time (ms)')
ylabel('Torque (N-m)')
          
% 0.5 Hz PF
Avg50PF = (Pat14PF{1,4}.nommeascycle_nm+Pat14PF{1,5}.nommeascycle_nm+Pat14PF{1,6}.nommeascycle_nm+...
           Pat15PF{1,4}.nommeascycle_nm+Pat15PF{1,5}.nommeascycle_nm+Pat15PF{1,6}.nommeascycle_nm+...
           Pat16PF{1,4}.nommeascycle_nm+Pat16PF{1,5}.nommeascycle_nm+Pat16PF{1,6}.nommeascycle_nm+...
           Pat17PF{1,4}.nommeascycle_nm+Pat17PF{1,5}.nommeascycle_nm+Pat17PF{1,6}.nommeascycle_nm+...
           Pat18PF{1,4}.nommeascycle_nm+Pat18PF{1,5}.nommeascycle_nm+Pat18PF{1,6}.nommeascycle_nm)/15;
      
AvgRef50PF = (Pat14PF{1,4}.nomrefcycle_nm+Pat14PF{1,5}.nomrefcycle_nm+Pat14PF{1,6}.nomrefcycle_nm+...
              Pat15PF{1,4}.nomrefcycle_nm+Pat15PF{1,5}.nomrefcycle_nm+Pat15PF{1,6}.nomrefcycle_nm+...
              Pat16PF{1,4}.nomrefcycle_nm+Pat16PF{1,5}.nomrefcycle_nm+Pat16PF{1,6}.nomrefcycle_nm+...
              Pat17PF{1,4}.nomrefcycle_nm+Pat17PF{1,5}.nomrefcycle_nm+Pat17PF{1,6}.nomrefcycle_nm+...
              Pat18PF{1,4}.nomrefcycle_nm+Pat18PF{1,5}.nomrefcycle_nm+Pat18PF{1,6}.nomrefcycle_nm)/15;

Err50PF = abs(AvgRef50PF-Avg50PF);
MeanErr50PF = mean(Err50PF);

PF50 = zeros(15,2000);
for i = 1:3
    
    PF50(i,:) = Pat14PF{1,i+3}.nommeascycle_nm;
    PF50(i+3,:) = Pat15PF{1,i+3}.nommeascycle_nm;
    PF50(i+6,:) = Pat16PF{1,i+3}.nommeascycle_nm;
    PF50(i+9,:) = Pat17PF{1,i+3}.nommeascycle_nm;
    PF50(i+12,:) = Pat18PF{1,i+3}.nommeascycle_nm;
    
end
StdPF50 = std(PF50);
AvgP1Std50PF = Avg50PF+StdPF50;
AvgM1Std50PF = Avg50PF-StdPF50;

figure(10)          
hold on 
plot(Avg50PF,'b')
plot(AvgRef50PF,'r')
plot(AvgP1Std50PF,'g')
plot(AvgM1Std50PF,'g')
legend('Measured','Reference','+/-1 Std Dev','HandleVisibility','off')
title('0.5 Hz Plantar Flexion')
xlabel('Time (ms)')
ylabel('Torque (N-m)')

% 0.75 Hz PF
Avg75PF = (Pat14PF{1,7}.nommeascycle_nm+Pat14PF{1,8}.nommeascycle_nm+Pat14PF{1,9}.nommeascycle_nm+...
           Pat15PF{1,7}.nommeascycle_nm+Pat15PF{1,8}.nommeascycle_nm+Pat15PF{1,9}.nommeascycle_nm+...
           Pat16PF{1,7}.nommeascycle_nm+Pat16PF{1,8}.nommeascycle_nm+Pat16PF{1,9}.nommeascycle_nm+...
           Pat17PF{1,7}.nommeascycle_nm+Pat17PF{1,8}.nommeascycle_nm+Pat17PF{1,9}.nommeascycle_nm+...
           Pat18PF{1,7}.nommeascycle_nm+Pat18PF{1,8}.nommeascycle_nm+Pat18PF{1,9}.nommeascycle_nm)/15;
      
AvgRef75PF = (Pat14PF{1,7}.nomrefcycle_nm+Pat14PF{1,8}.nomrefcycle_nm+Pat14PF{1,9}.nomrefcycle_nm+...
              Pat15PF{1,7}.nomrefcycle_nm+Pat15PF{1,8}.nomrefcycle_nm+Pat15PF{1,9}.nomrefcycle_nm+...
              Pat16PF{1,7}.nomrefcycle_nm+Pat16PF{1,8}.nomrefcycle_nm+Pat16PF{1,9}.nomrefcycle_nm+...
              Pat17PF{1,7}.nomrefcycle_nm+Pat17PF{1,8}.nomrefcycle_nm+Pat17PF{1,9}.nomrefcycle_nm+...
              Pat18PF{1,7}.nomrefcycle_nm+Pat18PF{1,8}.nomrefcycle_nm+Pat18PF{1,9}.nomrefcycle_nm)/15;

Err75PF = abs(AvgRef75PF-Avg75PF);
MeanErr75PF = mean(Err75PF);

PF75 = zeros(15,1333);
for i = 1:3
    
    PF75(i,:) = Pat14PF{1,i+6}.nommeascycle_nm;
    PF75(i+3,:) = Pat15PF{1,i+6}.nommeascycle_nm;
    PF75(i+6,:) = Pat16PF{1,i+6}.nommeascycle_nm;
    PF75(i+9,:) = Pat17PF{1,i+6}.nommeascycle_nm;
    PF75(i+12,:) = Pat18PF{1,i+6}.nommeascycle_nm;
    
end
StdPF75 = std(PF75);
AvgP1Std75PF = Avg75PF+StdPF75;
AvgM1Std75PF = Avg75PF-StdPF75;

figure(11)          
hold on 
plot(Avg75PF,'b')
plot(AvgRef75PF,'r')
plot(AvgP1Std75PF,'g')
plot(AvgM1Std75PF,'g')
legend('Measured','Reference','+/-1 Std Dev','HandleVisibility','off')
title('0.75 Hz Plantar Flexion')
xlabel('Time (ms)')
ylabel('Torque (N-m)')

% 1 Hz PF
Avg1PF = (Pat14PF{1,10}.nommeascycle_nm+Pat14PF{1,11}.nommeascycle_nm+Pat14PF{1,12}.nommeascycle_nm+...
          Pat15PF{1,10}.nommeascycle_nm+Pat15PF{1,11}.nommeascycle_nm+Pat15PF{1,12}.nommeascycle_nm+...
          Pat16PF{1,10}.nommeascycle_nm+Pat16PF{1,11}.nommeascycle_nm+Pat16PF{1,12}.nommeascycle_nm+...
          Pat17PF{1,10}.nommeascycle_nm+Pat17PF{1,11}.nommeascycle_nm+Pat17PF{1,12}.nommeascycle_nm+...
          Pat18PF{1,10}.nommeascycle_nm+Pat18PF{1,11}.nommeascycle_nm+Pat18PF{1,12}.nommeascycle_nm)/15;
      
AvgRef1PF = (Pat14PF{1,10}.nomrefcycle_nm+Pat14PF{1,11}.nomrefcycle_nm+Pat14PF{1,12}.nomrefcycle_nm+...
             Pat15PF{1,10}.nomrefcycle_nm+Pat15PF{1,11}.nomrefcycle_nm+Pat15PF{1,12}.nomrefcycle_nm+...
             Pat16PF{1,10}.nomrefcycle_nm+Pat16PF{1,11}.nomrefcycle_nm+Pat16PF{1,12}.nomrefcycle_nm+...
             Pat17PF{1,10}.nomrefcycle_nm+Pat17PF{1,11}.nomrefcycle_nm+Pat17PF{1,12}.nomrefcycle_nm+...
             Pat18PF{1,10}.nomrefcycle_nm+Pat18PF{1,11}.nomrefcycle_nm+Pat18PF{1,12}.nomrefcycle_nm)/15;

Err1PF = abs(AvgRef1PF-Avg1PF);
MeanErr1PF = mean(Err1PF);

PF1 = zeros(15,1000);
for i = 1:3
    
    PF1(i,:) = Pat14PF{1,i+9}.nommeascycle_nm;
    PF1(i+3,:) = Pat15PF{1,i+9}.nommeascycle_nm;
    PF1(i+6,:) = Pat16PF{1,i+9}.nommeascycle_nm;
    PF1(i+9,:) = Pat17PF{1,i+9}.nommeascycle_nm;
    PF1(i+12,:) = Pat18PF{1,i+9}.nommeascycle_nm;
    
end
StdPF1 = std(PF1);
AvgP1Std1PF = Avg1PF+StdPF1;
AvgM1Std1PF = Avg1PF-StdPF1;

figure(12)          
hold on 
plot(Avg1PF,'b')
plot(AvgRef1PF,'r')
plot(AvgP1Std1PF,'g')
plot(AvgM1Std1PF,'g')
legend('Measured','Reference','+/-1 Std Dev','HandleVisibility','off')
title('1 Hz Plantar Flexion')
xlabel('Time (ms)')
ylabel('Torque (N-m)')

% 1.25 Hz PF
Avg125PF = (Pat14PF{1,13}.nommeascycle_nm+Pat14PF{1,14}.nommeascycle_nm+Pat14PF{1,15}.nommeascycle_nm+...
          Pat15PF{1,13}.nommeascycle_nm+Pat15PF{1,14}.nommeascycle_nm+Pat15PF{1,15}.nommeascycle_nm+...
          Pat16PF{1,13}.nommeascycle_nm+Pat16PF{1,14}.nommeascycle_nm+Pat16PF{1,15}.nommeascycle_nm+...
          Pat17PF{1,13}.nommeascycle_nm+Pat17PF{1,14}.nommeascycle_nm+Pat17PF{1,15}.nommeascycle_nm+...
          Pat18PF{1,13}.nommeascycle_nm+Pat18PF{1,14}.nommeascycle_nm+Pat18PF{1,15}.nommeascycle_nm)/15;
      
AvgRef125PF = (Pat14PF{1,13}.nomrefcycle_nm+Pat14PF{1,14}.nomrefcycle_nm+Pat14PF{1,15}.nomrefcycle_nm+...
             Pat15PF{1,13}.nomrefcycle_nm+Pat15PF{1,14}.nomrefcycle_nm+Pat15PF{1,15}.nomrefcycle_nm+...
             Pat16PF{1,13}.nomrefcycle_nm+Pat16PF{1,14}.nomrefcycle_nm+Pat16PF{1,15}.nomrefcycle_nm+...
             Pat17PF{1,13}.nomrefcycle_nm+Pat17PF{1,14}.nomrefcycle_nm+Pat17PF{1,15}.nomrefcycle_nm+...
             Pat18PF{1,13}.nomrefcycle_nm+Pat18PF{1,14}.nomrefcycle_nm+Pat18PF{1,15}.nomrefcycle_nm)/15;

Err125PF = abs(AvgRef125PF-Avg125PF);
MeanErr125PF = mean(Err125PF);

PF125 = zeros(15,800);
for i = 1:3
    
    PF125(i,:) = Pat14PF{1,i+12}.nommeascycle_nm;
    PF125(i+3,:) = Pat15PF{1,i+12}.nommeascycle_nm;
    PF125(i+6,:) = Pat16PF{1,i+12}.nommeascycle_nm;
    PF125(i+9,:) = Pat17PF{1,i+12}.nommeascycle_nm;
    PF125(i+12,:) = Pat18PF{1,i+12}.nommeascycle_nm;
    
end
StdPF125 = std(PF125);
AvgP1Std125PF = Avg125PF+StdPF125;
AvgM1Std125PF = Avg125PF-StdPF125;

figure(13)          
hold on 
plot(Avg125PF,'b')
plot(AvgRef125PF,'r')
plot(AvgP1Std125PF,'g')
plot(AvgM1Std125PF,'g')
legend('Measured','Reference','+/-1 Std Dev','HandleVisibility','off')
title('1.25 Hz Plantar Flexion')
xlabel('Time (ms)')
ylabel('Torque (N-m)')

% 1.5 Hz PF
Avg15PF = (Pat14PF{1,16}.nommeascycle_nm+Pat14PF{1,17}.nommeascycle_nm+Pat14PF{1,18}.nommeascycle_nm+...
          Pat15PF{1,16}.nommeascycle_nm+Pat15PF{1,17}.nommeascycle_nm+Pat15PF{1,18}.nommeascycle_nm+...
          Pat16PF{1,16}.nommeascycle_nm+Pat16PF{1,17}.nommeascycle_nm+Pat16PF{1,18}.nommeascycle_nm+...
          Pat17PF{1,16}.nommeascycle_nm+Pat17PF{1,17}.nommeascycle_nm+Pat17PF{1,18}.nommeascycle_nm+...
          Pat18PF{1,16}.nommeascycle_nm+Pat18PF{1,17}.nommeascycle_nm+Pat18PF{1,18}.nommeascycle_nm)/15;
      
AvgRef15PF = (Pat14PF{1,16}.nomrefcycle_nm+Pat14PF{1,17}.nomrefcycle_nm+Pat14PF{1,18}.nomrefcycle_nm+...
             Pat15PF{1,16}.nomrefcycle_nm+Pat15PF{1,17}.nomrefcycle_nm+Pat15PF{1,18}.nomrefcycle_nm+...
             Pat16PF{1,16}.nomrefcycle_nm+Pat16PF{1,17}.nomrefcycle_nm+Pat16PF{1,18}.nomrefcycle_nm+...
             Pat17PF{1,16}.nomrefcycle_nm+Pat17PF{1,17}.nomrefcycle_nm+Pat17PF{1,18}.nomrefcycle_nm+...
             Pat18PF{1,16}.nomrefcycle_nm+Pat18PF{1,17}.nomrefcycle_nm+Pat18PF{1,18}.nomrefcycle_nm)/15;

Err15PF = abs(AvgRef15PF-Avg15PF);
MeanErr15PF = mean(Err15PF);

PF15 = zeros(15,666);
for i = 1:3
    
    PF15(i,:) = Pat14PF{1,i+15}.nommeascycle_nm;
    PF15(i+3,:) = Pat15PF{1,i+15}.nommeascycle_nm;
    PF15(i+6,:) = Pat16PF{1,i+15}.nommeascycle_nm;
    PF15(i+9,:) = Pat17PF{1,i+15}.nommeascycle_nm;
    PF15(i+12,:) = Pat18PF{1,i+15}.nommeascycle_nm;
    
end
StdPF15 = std(PF15);
AvgP1Std15PF = Avg15PF+StdPF15;
AvgM1Std15PF = Avg15PF-StdPF15;

figure(14)          
hold on 
plot(Avg15PF,'b')
plot(AvgRef15PF,'r')
plot(AvgP1Std15PF,'g')
plot(AvgM1Std15PF,'g')
legend('Measured','Reference','+/-1 Std Dev','HandleVisibility','off')
title('1.5 Hz Plantar Flexion')
xlabel('Time (ms)')
ylabel('Torque (N-m)')

% 1.75 Hz PF
Avg175PF = (Pat14PF{1,19}.nommeascycle_nm+Pat14PF{1,20}.nommeascycle_nm+Pat14PF{1,21}.nommeascycle_nm+...
          Pat15PF{1,19}.nommeascycle_nm+Pat15PF{1,20}.nommeascycle_nm+Pat15PF{1,21}.nommeascycle_nm+...
          Pat16PF{1,19}.nommeascycle_nm+Pat16PF{1,20}.nommeascycle_nm+Pat16PF{1,21}.nommeascycle_nm+...
          Pat17PF{1,19}.nommeascycle_nm+Pat17PF{1,20}.nommeascycle_nm+Pat17PF{1,21}.nommeascycle_nm+...
          Pat18PF{1,19}.nommeascycle_nm+Pat18PF{1,20}.nommeascycle_nm+Pat18PF{1,21}.nommeascycle_nm)/15;
      
AvgRef175PF = (Pat14PF{1,19}.nomrefcycle_nm+Pat14PF{1,20}.nomrefcycle_nm+Pat14PF{1,21}.nomrefcycle_nm+...
             Pat15PF{1,19}.nomrefcycle_nm+Pat15PF{1,20}.nomrefcycle_nm+Pat15PF{1,21}.nomrefcycle_nm+...
             Pat16PF{1,19}.nomrefcycle_nm+Pat16PF{1,20}.nomrefcycle_nm+Pat16PF{1,21}.nomrefcycle_nm+...
             Pat17PF{1,19}.nomrefcycle_nm+Pat17PF{1,20}.nomrefcycle_nm+Pat17PF{1,21}.nomrefcycle_nm+...
             Pat18PF{1,19}.nomrefcycle_nm+Pat18PF{1,20}.nomrefcycle_nm+Pat18PF{1,21}.nomrefcycle_nm)/15;

Err175PF = abs(AvgRef175PF-Avg175PF);
MeanErr175PF = mean(Err175PF);

PF175 = zeros(15,571);
for i = 1:3
    
    PF175(i,:) = Pat14PF{1,i+18}.nommeascycle_nm;
    PF175(i+3,:) = Pat15PF{1,i+18}.nommeascycle_nm;
    PF175(i+6,:) = Pat16PF{1,i+18}.nommeascycle_nm;
    PF175(i+9,:) = Pat17PF{1,i+18}.nommeascycle_nm;
    PF175(i+12,:) = Pat18PF{1,i+18}.nommeascycle_nm;
    
end
StdPF175 = std(PF175);
AvgP1Std175PF = Avg175PF+StdPF175;
AvgM1Std175PF = Avg175PF-StdPF175;

figure(15)          
hold on 
plot(Avg175PF,'b')
plot(AvgRef175PF,'r')
plot(AvgP1Std175PF,'g')
plot(AvgM1Std175PF,'g')
legend('Measured','Reference','+/-1 Std Dev','HandleVisibility','off')
title('1.75 Hz Plantar Flexion')
xlabel('Time (ms)')
ylabel('Torque (N-m)')

% 2 Hz PF
Avg2PF = (Pat14PF{1,22}.nommeascycle_nm+Pat14PF{1,23}.nommeascycle_nm+Pat14PF{1,24}.nommeascycle_nm+...
          Pat15PF{1,22}.nommeascycle_nm+Pat15PF{1,23}.nommeascycle_nm+Pat15PF{1,24}.nommeascycle_nm+...
          Pat16PF{1,22}.nommeascycle_nm+Pat16PF{1,23}.nommeascycle_nm+Pat16PF{1,24}.nommeascycle_nm+...
          Pat17PF{1,22}.nommeascycle_nm+Pat17PF{1,23}.nommeascycle_nm+Pat17PF{1,24}.nommeascycle_nm+...
          Pat18PF{1,22}.nommeascycle_nm+Pat18PF{1,23}.nommeascycle_nm+Pat18PF{1,24}.nommeascycle_nm)/15;
      
AvgRef2PF = (Pat14PF{1,22}.nomrefcycle_nm+Pat14PF{1,23}.nomrefcycle_nm+Pat14PF{1,24}.nomrefcycle_nm+...
             Pat15PF{1,22}.nomrefcycle_nm+Pat15PF{1,23}.nomrefcycle_nm+Pat15PF{1,24}.nomrefcycle_nm+...
             Pat16PF{1,22}.nomrefcycle_nm+Pat16PF{1,23}.nomrefcycle_nm+Pat16PF{1,24}.nomrefcycle_nm+...
             Pat17PF{1,22}.nomrefcycle_nm+Pat17PF{1,23}.nomrefcycle_nm+Pat17PF{1,24}.nomrefcycle_nm+...
             Pat18PF{1,22}.nomrefcycle_nm+Pat18PF{1,23}.nomrefcycle_nm+Pat18PF{1,24}.nomrefcycle_nm)/15;

Err2PF = abs(AvgRef2PF-Avg2PF);
MeanErr2PF = mean(Err2PF);
          
PF2 = zeros(15,500);
for i = 1:3
    
    PF2(i,:) = Pat14PF{1,i+21}.nommeascycle_nm;
    PF2(i+3,:) = Pat15PF{1,i+21}.nommeascycle_nm;
    PF2(i+6,:) = Pat16PF{1,i+21}.nommeascycle_nm;
    PF2(i+9,:) = Pat17PF{1,i+21}.nommeascycle_nm;
    PF2(i+12,:) = Pat18PF{1,i+21}.nommeascycle_nm;
    
end
StdPF2 = std(PF2);
AvgP1Std2PF = Avg2PF+StdPF2;
AvgM1Std2PF = Avg2PF-StdPF2;

figure(16)          
hold on 
plot(Avg2PF,'b')
plot(AvgRef2PF,'r')
plot(AvgP1Std2PF,'g')
plot(AvgM1Std2PF,'g')
legend('Measured','Reference','+/-1 Std Dev','HandleVisibility','off')
title('2 Hz Plantar Flexion')
xlabel('Time (ms)')
ylabel('Torque (N-m)')

%% Error Plots

x = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2];
yDF = [MeanErr25DF,MeanErr50DF,MeanErr75DF,MeanErr1DF,MeanErr125DF,MeanErr15DF,MeanErr175DF,MeanErr2DF];
yPF = [MeanErr25PF,MeanErr50PF,MeanErr75PF,MeanErr1PF,MeanErr125PF,MeanErr15PF,MeanErr175PF,MeanErr2PF];

figure(17);
hold on
scatter(x,yDF,'b')
plot(x,yDF,'r-');
title('Error vs Frequency (Dorsiflexion)')
xlabel('Frequency (Hz)')
ylabel('Average Error (N-m)')

figure(18);
hold on
scatter(x,yPF,'b')
plot(x,yPF,'r-');
title('Error vs Frequency (Plantar Flexion)')
xlabel('Frequency (Hz)')
ylabel('Average Error (N-m)')



