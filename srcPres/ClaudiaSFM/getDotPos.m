% function T = getSFMDotPos(SFM,disparity,direction)
% compute nFrames for SFM 

%initialize the dot positions
nDots = SFM.nDots;
dots.xflat(1:nDots) = [rand(nDots,1)-.5]*2;
dots.yflat(1:nDots) = [rand(nDots,1)-.5]*2;


return

% for iFrame = 1:SFM.nframe 
% end
% % first dot 
% T.dotPosXY11 = AM.radius*[cos(initPha) sin(initPha)];
% T.dotPosXY21 = AM.radius*[cos(initPha-pi) sin(initPha-pi)];
% % second dot 
% T.dotPosXY12 = AM.radius*[cos(initPha+pha) sin(initPha+pha)];
% T.dotPosXY22 = AM.radius*[cos(initPha+pha-pi) sin(initPha+pha-pi)];
