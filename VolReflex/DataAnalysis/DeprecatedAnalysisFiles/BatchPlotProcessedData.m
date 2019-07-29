basedir = '~/Documents/Research/VolReflexData/';
matfile1 = 'Pat50/ProcessedData/Pat50ProcessedData.mat';
matfile2 = 'Pat51/ProcessedData/Pat51ProcessedData.mat';
matfile3 = 'Pat52/ProcessedData/Pat52ProcessedData.mat';

matfile = {fullfile(basedir, matfile1), fullfile(basedir, matfile2), ...
            fullfile(basedir, matfile3)};
        
PlotProcessedData('ProcessedDataMats', matfile)