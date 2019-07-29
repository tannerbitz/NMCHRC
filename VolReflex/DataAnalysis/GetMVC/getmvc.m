function mvc = getmvc(varargin)
    defaultMeasChan = 1;
    defaultRefChan = 2;

    p = inputParser;
    addParameter(p, 'MeasChan', defaultMeasChan);
    addParameter(p, 'RefChan', defaultRefChan);
    parse(p, varargin{:});
    
    measChan = p.Results.MeasChan;
    refChan = p.Results.RefChan;

    [mvcfile, mvcpath] = uigetfile('.txt', ...
                                'Choose MVC Files', ...
                                'MultiSelect', 'off');
                            
    
    data = load(fullfile(mvcpath, mvcfile));
    measData = data(:, measChan);
    
    fs = ParseFilename(mvcfile);
    zs = GetSectionsMVC(measData);
    
    if strcmp(fs.flexion, 'DF')
        mvc1 = zs(2).max - zs(1).mean;
        mvc2 = zs(4).max - zs(3).mean;
        mvc3 = zs(6).max - zs(5).mean;
        mvcRaw = max([mvc1, mvc2, mvc3]);
    elseif strcmp(fs.flexion, 'PF')
        mvc1 = zs(2).min - zs(1).mean;
        mvc2 = zs(4).min - zs(3).mean;
        mvc3 = zs(6).min - zs(5).mean;
        mvcRaw = max(abs([mvc1, mvc2, mvc3]));
    end
    serial2lbs = 250/4096;
    lbs2Newtons = 4.44822/1;   
    leverLength = 0.15;          %m
    serial2Nm = serial2lbs*lbs2Newtons*leverLength;
    
    mvc = mvcRaw*serial2Nm;
        
end