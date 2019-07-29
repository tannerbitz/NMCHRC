clear all;
close all;
clc;

measuredchannel = input('Enter Measured Channel Number\n');
referencechannel = input('Enter Reference Channel Number\n');

fprintf('Choose Plantarflexion MVC Text File\n')
PF = getmvc('MeasChan', measuredchannel+1, ...
            'RefChan', referencechannel+1);
close all
fprintf('Choose Dorsiflexion MVC Text File\n')
DF = getmvc('MeasChan', measuredchannel+1, ...
            'RefChan', referencechannel+1);
matfname = input('Enter MAT filename in quotes(no extension needed)\n');
save(matfname, 'PF', 'DF')
