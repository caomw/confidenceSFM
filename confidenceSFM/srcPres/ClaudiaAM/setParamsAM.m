% function setParamsAM
% set parameters for AM

AM.stimOn = 0.050; % in msec 
AM.stimOff = 0.050; % in msec 

AM.fixationXY = [400 300]; % half of the screen 
    
AM.distFromFixation = 200; % in pixel , from fixation to the center of AM
AM.radius = 100 ; % radius of imaginary circle on which AM is perceived 

AM.size = 10 ; % size of the dot 
AM.color = [255 255 255]; 


AM.vRotation  = [5 10 20 45 90] ; % potential rotation angles. in degrees
AM.vInitAngle = [0 45 90 135] ; % potential inital angles. in degrees

%% from the above parameters, compute the following 

AM.nRotation = length(AM.vRotation);


