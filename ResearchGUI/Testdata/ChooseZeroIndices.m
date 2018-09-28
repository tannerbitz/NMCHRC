function r = ChooseZeroIndices(d)
    figure(1)
    plot(d)
    
    xnum = input('How many zero regions?\n');
        
    [x, y] = ginput(xnum*2);
    r = x;
end