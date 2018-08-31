clear;
clc;

p7mvcdf = load('Patient7_MVC_DF.txt');
p7df25 = load('PatNo7_VR_AnklePosNeutral_DF_0-25Hz.txt');

p7df_m = p7df25(:,1);
p7df_ref = p7df25(:,2);

serial2lbs_bipolar = 125/2048;
lbs2NmAt15cm = 4.448*.15;

n = 1;
for i = 1:16
   
    df(:,i) = p7df_m(n:4000+n);
    n = n + 4000;
    
end

dfm = mean(df,2);

mvcdf1 = max(p7mvcdf(5500:9500));
mvcdf2 = max(p7mvcdf(25500:29500));
mvcdf3 = max(p7mvcdf(45500:49500));

mvcdfSerial = max([mvcdf1, mvcdf2, mvcdf3]);
mvcdf_Nm = abs(mvcdfSerial)*serial2lbs_bipolar*lbs2NmAt15cm;

refsig = p7df_ref(1:4001);
refsigser2Nm = mvcdf_Nm/4096*0.2;

ref = refsig*refsigser2Nm;

hold on;
plot(dfm*serial2lbs_bipolar*lbs2NmAt15cm+8.25);
plot(ref);








