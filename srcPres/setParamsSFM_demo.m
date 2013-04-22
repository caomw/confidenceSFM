% function setParamsSFM
% modified 08 Aug 4 by NT
% set parameters for SFM

SFM.stimOn = 1; % in sec 
% SFM.stimOff = 0.050; % in msec 
SFM.frameRate = 100; % 60; 
SFM.nframe = round( SFM.stimOn * SFM.frameRate );

SFM.fixationXY = [512 384]; % half of the screen 
    
SFM.distFromFixation = 200; % in pixel , from fixation to the center of SFM

SFM.dotSize = 6 ; % size of the dot 
SFM.color1 = [150 0 0]; 
SFM.color1 = [0 80 0]; 
SFM.nDots = 300; % 150

SFM.vDisparity = [0.04] ; % potential disparity , 0 for completely ambiguous

SFM.spinaxis = 2; % 1 for vertical, 2 for horizontal rotation 
SFM.dispFlag = 1; % 0 for disabling disparity 


SFM.radius = 5.5;  %degrees
SFM.pixPerDeg = 30; % roughly 
SFM.imgSize = round(SFM.pixPerDeg*SFM.radius*2)+(SFM.dotSize);  %size of one circular patch (plus buffer for dot size)  (in pixels)


%%
SFM.degPerSec = 150;   %deg/sec

%% from the above parameters, compute the following 
SFM.nDisparity = length(SFM.vDisparity);


