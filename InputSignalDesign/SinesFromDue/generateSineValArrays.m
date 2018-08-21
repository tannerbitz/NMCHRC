freq = [1/4, 1/2, 1, 5/4, 2];

for i = 1:length(freq)
    for sample = 0:(1000/freq(i) - 1)
        sineval(i, sample + 1) = 2048 + floor(2047.99*sin(2*pi/1000*sample*freq(i)));     
    end
end

%%

sinequarterhz = sineval(1, 1:4000);
sinehalfhz = sineval(2, 1:2000);
sineonehz = sineval(3, 1:1000);
sinefivequartershz = sineval(4, 1:800);
sinetwohz = sineval(5, 1:500);


%%
fid = fopen('sinequarterhz.txt', 'w');
for i = 1:1000
    fprintf(fid, "%i, %i, %i, %i,\n", sinequarterhz((4*(i-1)+1)), ...
                                                    sinequarterhz((4*(i-1)+2)), ...
                                                    sinequarterhz((4*(i-1)+3)), ...
                                                    sinequarterhz((4*(i-1)+4)));
end

%% 
fid = fopen('sinehalfhz.txt', 'w');
for i = 1:500
    fprintf(fid, "%i, %i, %i, %i,\n", sinehalfhz((4*(i-1)+1)), ...
                                     sinehalfhz((4*(i-1)+2)), ...
                                     sinehalfhz((4*(i-1)+3)), ...
                                     sinehalfhz((4*(i-1)+4)));
end

%% 
fid = fopen('sineonehz.txt', 'w');
for i = 1:250
    fprintf(fid, "%i, %i, %i, %i,\n", sineonehz((4*(i-1)+1)), ...
                                     sineonehz((4*(i-1)+2)), ...
                                     sineonehz((4*(i-1)+3)), ...
                                     sineonehz((4*(i-1)+4)));
end
%%
fid = fopen('sinetwohz.txt', 'w');
for i = 1:125
    fprintf(fid, "%i, %i, %i, %i,\n", sinetwohz((4*(i-1)+1)), ...
                                     sinetwohz((4*(i-1)+2)), ...
                                     sinetwohz((4*(i-1)+3)), ...
                                     sinetwohz((4*(i-1)+4)));
end

%% 
fid = fopen('sinefivequartershz.txt', 'w');
for i = 1:length(sinefivequartershz)/4
   fprintf(fid, "%i, %i, %i, %i,\n", sinefivequartershz((4*(i-1)+1)), ...
                                     sinefivequartershz((4*(i-1)+2)), ...
                                     sinefivequartershz((4*(i-1)+3)), ...
                                     sinefivequartershz((4*(i-1)+4)));    
end