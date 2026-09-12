function [Z, mag, phase] = calc_impedance(R, L, C, f);
    w = 2*pi*f;
    Z = R + 1j*w*L + 1./(1j*w*C);
    mag = abs(Z);
    phase = angle(Z)*180/pi;
end

