function zsection = GetZeroSection(data)
    r = ChooseZeroIndices(data);
    zs = struct;
    for i = 1:length(r)/2
        zs(i).startind = r(2*i - 1);
        zs(i).stopind = r(2*i);
        zs(i).std = std(data(zs(i).startind: zs(i).stopind));
        zs(i).mean = mean(data(zs(i).startind: zs(i).stopind));
    end
    
    dmax = max(data);
    dmin = min(data);
    
    close figure 1
    figure(1);
    plot(data);
    hold on
    s = {};
    for i = 1:length(r)/2
        c = rand(1, 3);
        plot([zs(i).startind, zs(i).startind + 1], [dmax, dmin], ...
              'Color', c, ...
              'HandleVisibility', 'on');
        plot([zs(i).stopind, zs(i).stopind + 1], [dmax, dmin], ...
              'Color', c, ...
              'HandleVisibility', 'off');
        s{i} = sprintf(['std: %f\n' ...
                        'mean: %f\n\n'], zs(i).std, zs(i).mean);
    end
    legend(s);
    zsection = zs;
end