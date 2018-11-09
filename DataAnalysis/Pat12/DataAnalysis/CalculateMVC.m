clear all;
close all;
clc;


PF = getmvc();
close all
DF = getmvc();
matfname = input('Enter MAT filename in quotes(no extension needed)\n');
save(matfname, 'PF', 'DF')
