clear;
clc;

p7mvcdf = load('Patient7_MVC_DF.txt');
p7df25 = load('PatNo7_VR_AnklePosNeutral_DF_0-25Hz.txt');

serial2lbs_bipolar = 125/2048;
lbs2NmAt15cm = 4.448*.15;

p7df_m = p7df25(:,1);
p7df_ref = p7df25(:,2);

% Reference
zerolevel1DF = round(mean(p7mvcdf(1:4500)));
mvcDF1 = max(p7mvcdf(5500:9500)) - zerolevel1DF;
zerolevel2DF = round(mean(p7mvcdf(10500:24500)));
mvcDF2 = max(p7mvcdf(25500:29500)) - zerolevel2DF;

mvcDF_serial = max([mvcDF1, mvcDF2]);
mvcDF_Nm = abs(mvcDF_serial)*serial2lbs_bipolar*lbs2NmAt15cm;

ref5 = p7df_ref(16005:20005);
refsigserial2NmDF = mvcDF_Nm/4096*0.2;

% Measured cycle intervals
df1 = p7df_m(1:4001);
df2 = p7df_m(4002:8002);
df3 = p7df_m(8003:12003);
df4 = p7df_m(12004:16004);
df5 = p7df_m(16005:20005);
df6 = p7df_m(20006:24006);
df7 = p7df_m(24007:28007);
df8 = p7df_m(28008:32008);
df9 = p7df_m(32009:36009);
df10 = p7df_m(40010:44010);
df11 = p7df_m(44011:48011);
df12 = p7df_m(48012:52012);
df13 = p7df_m(52013:56013);
df14 = p7df_m(56014:60014);
df15 = p7df_m(60015:64015);

dfa = (df1+df2+df3+df4+df5+df6+df7+df8+df9+df10+df11+df12+df13+df14+df15)/15;

% Measured cycle for plot
df_m = dfa*serial2lbs_bipolar*lbs2NmAt15cm;
refF = ref5*refsigserial2NmDF;

hold on;
plot(df_m+8.25);
plot(refF);



