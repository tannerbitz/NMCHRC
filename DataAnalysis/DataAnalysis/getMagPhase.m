function res = getMagPhase(ref, meas)
    options = optimoptions('fmincon','Display','off');
    temp = zeros(length(meas), 3);
    for i = 1:length(meas)
        if i == 1
            meas_temp = meas;
        else
            meas_temp = [meas(i:end), meas(1:i-1)];
        end

        ls = @(M) sum((ref - M.*meas_temp).^2);
        [x, residual] = fmincon(ls, 1, [],[],[],[],[],[],[],options);
        temp(i, :) = [i, x, residual];
    end

    [Y, I] = min(temp(:, 3));
    i = temp(I, 1);
    mag = temp(I, 2);
    meas_temp = mag.*[meas(i:end), meas(1:i-1)];
    phase = (length(meas) - i)/length(meas) * 360;

    res = struct;
    res.mag = mag;
    res.phase = phase;
end
