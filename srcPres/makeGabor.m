function [w] = makeGabor(ori,sf,envWidth,pha,patchSize);

%
% function [w] = makeGabor(ori,sf,envWidth,pha,patchSize)
%
% ori       - orientation in degree
% sf        - spatial frequency relative to patch
% envWidth  - std of envelope, relative to patch
% pha       - phase (between 0 and 2pi)
% patchSize - size of output patch in pix
%

w = zeros(patchSize);

x  = -0.5:1/(patchSize-1):0.5;

yM = x'*ones(1,patchSize); 
xM = yM';

r2  = xM.^2+yM.^2;
env = exp(-r2/2/envWidth^2);

xR   = xM*cos(pi*ori/180)+yM*sin(pi*ori/180);
grat = sin(2*pi*sf*xR+pha);

w = grat.*env;