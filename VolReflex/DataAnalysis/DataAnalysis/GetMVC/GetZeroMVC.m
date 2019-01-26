function r = GetZeroMVC(d)
    figure(1)
    plot(d)
    
    xnum = 6;
        
    [x, y] = ginput(xnum*2);
    r = x;
end