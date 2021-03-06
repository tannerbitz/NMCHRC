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

% DF Bode Plot
% figure(1)
% subplot(2, 1, 1)
% title('DF Bode Plot')
% hold on
% for i = 1:length(Pat14DF)
%     semilogx(Pat14DF{i}.trialinfo.refsigfreq, Pat14DF{i}.magphase.mag, 'ro')
%     semilogx(Pat15DF{i}.trialinfo.refsigfreq, Pat15DF{i}.magphase.mag, 'bo')
%     semilogx(Pat18DF{i}.trialinfo.refsigfreq, Pat18DF{i}.magphase.mag, 'go')
% end
% hold off
% ylabel('Mag')
% xlabel('Freq (Hz)')
% legend('Pat14', 'Pat15', 'Pat18')
% 
% subplot(2 ,1 ,2)
% hold on
% for i = 1:length(Pat14DF)
%     semilogx(Pat14DF{i}.trialinfo.refsigfreq, Pat14DF{i}.magphase.phase, 'ro')
%     semilogx(Pat15DF{i}.trialinfo.refsigfreq, Pat15DF{i}.magphase.phase, 'bo')
%     semilogx(Pat18DF{i}.trialinfo.refsigfreq, Pat18DF{i}.magphase.phase, 'go')
% end
% hold off
% ylabel('Phase')
% xlabel('Freq (Hz)')
% 
% 
% % PF Bode Plot
% figure(2)
% subplot(2, 1, 1)
% title('PF Bode Plot')
% hold on
% for i = 1:length(Pat14PF)
%     semilogx(Pat14PF{i}.trialinfo.refsigfreq, Pat14PF{i}.magphase.mag, 'ro')
%     semilogx(Pat15PF{i}.trialinfo.refsigfreq, Pat15PF{i}.magphase.mag, 'bo')
%     semilogx(Pat18PF{i}.trialinfo.refsigfreq, Pat18PF{i}.magphase.mag, 'go')
% end
% hold off
% ylabel('Mag')
% xlabel('Freq (Hz)')
% legend('Pat14', 'Pat15', 'Pat18')
% 
% subplot(2 ,1 ,2)
% hold on
% for i = 1:length(Pat14PF)
%     semilogx(Pat14PF{i}.trialinfo.refsigfreq, Pat14PF{i}.magphase.phase, 'ro')
%     semilogx(Pat15PF{i}.trialinfo.refsigfreq, Pat15PF{i}.magphase.phase, 'bo')
%     semilogx(Pat18PF{i}.trialinfo.refsigfreq, Pat18PF{i}.magphase.phase, 'go')
% end
% hold off
% ylabel('Phase')
% xlabel('Freq (Hz)') 



%%

%DF
close all
for i = 0:length(Pat14DF)/3 - 1
    figure(i+1)
    titlestr = sprintf('DF - %3.2fHz', Pat14DF{i*3 + 1}.trialinfo.refsigfreq);
    
    %plot(Pat14DF{i*3 + 1}.nomrefcycle_nm, 'r')
    hold on
    plot(Pat14DF{i*3 + 2}.nomrefcycle_nm, 'r')
    %plot(Pat14DF{i*3 + 3}.nomrefcycle_nm, 'r')

    plot(Pat14DF{i*3 + 1}.nommeascycle_nm, 'b')
    plot(Pat14DF{i*3 + 2}.nommeascycle_nm, 'b--')
    plot(Pat14DF{i*3 + 3}.nommeascycle_nm, 'b-.')
    hold off
    legend('Ref', 'Trial1', 'Trial2', 'Trial3')
    title(titlestr)
    xlabel('Time (ms)')
    ylabel('Torque (N-m)')
end
    
%%

%PF
for i = 0:length(Pat14PF)/3 - 1
    figure(i+1)
    titlestr = sprintf('PF - %3.2fHz', Pat14PF{i*3 + 1}.trialinfo.refsigfreq);

    
    %plot(Pat14PF{i*3 + 1}.nomrefcycle_nm, 'r')
    hold on
    %plot(Pat14PF{i*3 + 2}.nomrefcycle_nm, 'r')
    plot(Pat14PF{i*3 + 3}.nomrefcycle_nm, 'r')

    plot(Pat14PF{i*3 + 1}.nommeascycle_nm, 'b')
    plot(Pat14PF{i*3 + 2}.nommeascycle_nm, 'b--')
    plot(Pat14PF{i*3 + 3}.nommeascycle_nm, 'b-.')
    hold off
    legend('Ref', 'Trial2', 'Trial2','Trial3')
    title(titlestr)
    xlabel('Time (ms)')
    ylabel('Torque (N-m)')
end


