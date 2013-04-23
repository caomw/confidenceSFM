function [gun] = makeLinear(lum);



pix = [0:10:250,255];

% shimojo lab
% Y = [1.1 1.6 2.2 3.2 4.2 4.8 6.3 7.8 9.6 12 15 17 20 22 25 27 31 36 38 44 50 54 58 62 66 71 77];

% klab, psychophysics 
% settings:
% lum = 50
% con = 75
% default settings at 32bit color / 1024x768 / 120 Hz / second screen avail
% central
% pixel size = 8, 1 8-bit value for lum
% measured with klab photometer
Y = [0.057, 0.016, 0.043, 0.15,0.23,0.36,0.60,0.97,1.4,2.1,2.6,3.4,4.2,5.1,6.3,7.3,8.9,11,14,15,17,19,20,22,25,29,29];
P = polyfit(log(pix(2:end)),log(Y(2:end)),1);
gam = P(1);



gun = (exp(-P(2)).*lum).^(1/gam);
if any((gun<0)|(gun>255))
    error('Luminance cannot be displayed');
end 
    
    