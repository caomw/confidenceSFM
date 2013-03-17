function [fixOk,respKey,respTime,confKey,confTime] = singleTrial(window,el,fix,target,mask,arrow,SOA);

setConstants;

% local constants
verticalOff  = 250; % pixel;
arrowSize    = 50;  % pixel
targetLength = 20;

minFixDur = 0.5; %s 
minArrFix = 0.5; %s
SOAarrTgt = 24;  % screen cyc (200 ms)


% clear screen
Screen(window,'WaitBlanking');
Screen(window,'FillRect');

% show target




Screen('Close',mask);