function T = getDotPos(AM,initPha,pha)
% first dot 
T.dotPosXY11 = AM.radius*[cos(initPha) sin(initPha)];
T.dotPosXY21 = AM.radius*[cos(initPha-pi) sin(initPha-pi)];
% second dot 
T.dotPosXY12 = AM.radius*[cos(initPha+pha) sin(initPha+pha)];
T.dotPosXY22 = AM.radius*[cos(initPha+pha-pi) sin(initPha+pha-pi)];
