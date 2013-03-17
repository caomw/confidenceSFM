function [] = SFM_minimum
%% modified by NT 13 Mar 11
% based on runConf_1k_SFM_new, which contains commands related to
% communication with eyelink.
%
% Goals
% 1. to present SFM stimuli to parkinson's disease patient.
% - preliminary studies show that their percept switches very quickly
% - test this by passive viewing (constant stimulation) with button press,
% or, by interleaved presnetaiton, which might elicit stronger OKN at the
% onset of the stimuli.

if 1 % 2013 Mar 11 added by NT
    if nargin < 1
        subjectID = 'XX'
    end
    dbstop if error
end

asdf

% global constants
setConstants;

% desired screen size -- change as necessary
xSize = 1366;
ySize = 768;
% xSize = 1024;
% ySize = 768;
% setParamsAM
setParamsSFM

% subjectID
subjectID = upper(subjectID);

% check input parameter
if length(subjectID)~=2
    error('Subject ID must have two characters');
end

if nargin<2
    correctMode=1;
    warning('All cues correct');
end

if nargin<2
    demoOn=1;
end



% desired  refresh rate
scrFreq = SFM.frameRate ; % Hz

% screen parameters
whiteNL = 26; % cd/m2
blackNL = 0;  % cd/m2
grayNL  = 13; % cd/m2

lum.black = round(makeLinearKlab(blackNL));
lum.gray  = round(makeLinearKlab(grayNL));
lum.white = round(makeLinearKlab(whiteNL));
lum.text = lum.white;

verticalOff   = [178,-178];      % pixels; 5deg
verticalOffdummy   = [-178,178];      % pixels; 5deg
arrowverticalOff = [54,-54];
font1 = 30; % by NT 2013 Mar 11 % 12;
font2 = 36;
targetOri     = [0.5,1,2,3,4,5,6,7,8,9,10,16];
targetOridummy     = [0.5,1,2,3,4,5,6,7,8,9,10,16];
% maskOri       = 90;
patchSize     = 178;            % 5 deg
envSize       = 0.125;            % relative to patch
sf            = 8; %[2,3,4,6,7,8];               % cycles per patchsize
targetPhase   = pi/2;               %
targetDur     = 12;               % screen refreshes (50ms);
% targetMaskSOA = 6;               % screen refreshes (50ms);
maskDur1       = 30;              % This is half the masking time!!!
maskDur2       = 60;
arrowToStim   = 0.5;

arrowSize     = 40;              % pixel
arrowDur      = 15;             % ms;
arrowDur2       = 60;

fixationSizeH = 3;              % pixel
fixationDur   = 0.5;            % s;

% total number of trials
nTrials = 96;

if ~exist(sprintf('..\\dataRaw\\%s\\',subjectID));
    mkdir(sprintf('..\\dataRaw\\%s\\',subjectID));
end
% filename
sessionNum = 1;
while exist(sprintf('..\\dataRaw\\%s\\conf1C_%s%3.3d.mat',subjectID,subjectID,sessionNum));
    sessionNum = sessionNum+1;
end

fileName = sprintf('..\\dataRaw\\%s\\conf1C_%s%3.3d.mat',subjectID,subjectID,sessionNum)
ELName   = sprintf('%s%3.3d.edf',subjectID,sessionNum);

fileName
ELName

% initialize random number generators to subject dependent reconstructible
% values
seed = 1e5*sessionNum+100*subjectID(1)+subjectID(2);
rand('state',seed);
randn('state',seed);


% generate random order
%
% warning: if you change number of trials or number of orientations,
% change here
if ((length(targetOri)~=12)|(mod(nTrials,length(targetOri)*4)))
    error('randomization has to be changed for your number of trials');
end

tmp = randperm(nTrials);
tmp2 = mod(tmp-1,24)+1;
oriIdx = ceil(tmp2/2);

tmp_dummy = randperm(nTrials);
tmp2_dummy = mod(tmp_dummy-1,24)+1;
oriIdxdummy = ceil(tmp2_dummy/2);

if correctMode==1
    cueCorrect = ones(1,nTrials);
else
    cueCorrect = (mod(tmp2,2)>0);
end

% random tilt for each trial
tiltIdx = (rand(1,nTrials)>0.5)+1;

% random tilt for each trial
tiltIdxdummy = (rand(1,nTrials)>0.5)+1;

% random position for each trial
locIdx  = (rand(1,nTrials)>0.5)+1;


arrowIdx(find(cueCorrect))  = locIdx(find(cueCorrect));
arrowIdx(find(~cueCorrect)) = 3-locIdx(find(~cueCorrect));



%% open screen
[window,rect] = Screen(0,'OpenWindow',lum.black);

SFM.imgRect = [rect(3)/2 - SFM.imgSize/2 ,...
    rect(4)/2 - SFM.imgSize/2,...
    rect(3)/2 + SFM.imgSize/2,...
    rect(4)/2 + SFM.imgSize/2];

imgRectTop = SFM.imgRect + [ 0 1 0 1]*SFM.distFromFixation;
imgRectBot = SFM.imgRect - [ 0 1 0 1]*SFM.distFromFixation;


%% verify screen refresh rate
t0_test = GetSecs;
if 0 % 13 Mar 11 by NT
    Screen(window,'WaitBlanking',10);
    t1_test = GetSecs;
    if abs((t1_test-t0_test)/10-1/scrFreq)>1/scrFreq;
        Screen('CloseAll');
        error(sprintf('Screen rate must be within 10%% of %3.3dHz',scrFreq));
    end
end

% verify resoultion
if any(rect~=[0 0 xSize ySize])
    Screen('CloseAll');
    error('Screen Resoultion must be x=%d, y=%d',xSize,ySize');
end


Screen(window,'DrawText','Preparing session, please wait.',400,300,lum.text);


%cross
[Wcross, WcrossRect]=Screen(window,'OpenOffscreenWindow',lum.black);
crect=[0 0 20 20];
r1=[0 10 20 10];
r2=[10 0 10 20];
crossRect=CenterRect(crect,WcrossRect);
Screen(Wcross,'DrawLine',lum.white,r1(1),r1(2),r1(3),r1(4));%,scalar*1,scalar*1);
Screen(Wcross,'DrawLine',lum.white,r2(1),r2(2),r2(3),r2(4));%,scalar*1,scalar*1);


% prepare all offscreen windows
target = cell(2,2,length(targetOri)); % up/down, left/right, ori
mask   = cell(2,1);

for ud = 1 : 2
    rectLoc{ud} = [(xSize/2-patchSize/2), verticalOff(ud)+(ySize/2-patchSize/2), patchSize+(xSize/2-patchSize/2),verticalOff(ud)+patchSize+(ySize/2-patchSize/2)];
end

for ud = 1 : 2
    arrowLoc{ud} = [(xSize/2-patchSize/2), arrowverticalOff(ud)+(ySize/2-patchSize/2), patchSize+(xSize/2-patchSize/2),arrowverticalOff(ud)+patchSize+(ySize/2-patchSize/2)];
end


% Prepare arrows
for ud = 1 : 2
    arrow{ud} = Screen(window,'OpenOffscreenWindow',lum.black, [0 0 patchSize patchSize]);
    Screen(arrow{ud},'PutImage',makeArrow(ud,arrowSize,lum.white,lum.black));
end

for ud_2 = 1 : 2
    arrowLoc2{ud_2} = [(xSize/2-patchSize/2), arrowverticalOff(ud)+(ySize/2-patchSize/2), patchSize+(xSize/2-patchSize/2),arrowverticalOff(ud)+patchSize+(ySize/2-patchSize/2)];
end


% Prepare inverse arrows
for ud_2 = 1 : 2
    arrow_inv{ud_2} = Screen(window,'OpenOffscreenWindow',lum.black, [0 0 patchSize patchSize]);
    Screen(arrow_inv{ud_2},'PutImage',makeArrow(ud_2,arrowSize,lum.white,lum.black));
end

% Clear Screen and Hide Mouse pointer
Screen(window,'FillRect',lum.black);
% HideCursor;




% main loop here
respKey  = nan(1,nTrials);
respTime = nan(1,nTrials);
startTime = nan(1,nTrials);
trialStarted = zeros(1,nTrials);
arrowTime = nan(1,nTrials);
tgtOnTime = nan(1,nTrials);
maskOnTime = nan(1,nTrials);
maskOffTime = nan(1,nTrials);



for trial = 1 : nTrials

    arrow2Idx(trial)=locIdx(trial);
    arrow2locIdx(trial)=locIdx(trial);

    if locIdx(trial)==1
        locIdxdummy(trial) = 2;
    else
        locIdxdummy(trial) = 1;
    end


    %% prepare a trial
    iT(trial).disparity = 0 % [SFM.vDisparity(ceil(rand(1,2)*(SFM.nDisparity))) ];
    iT(trial).direction = [round(rand(1,2))*2-1];

    % iT(trial).disparity = [0.01 0.01]; % [SFM.vDisparity(ceil(rand(1,2)*(SFM.nDisparity))) ];
    % iT(trial).direction = [-1 1]; %[round(rand(1,2))*2-1];

    %% top SFM
    Top = getSFMDotPos(SFM,iT(trial).disparity(1),iT(trial).direction(1),window);
    %% bottom SFM
    % Bot = getSFMDotPos(SFM,iT(trial).disparity(2),iT(trial).direction(2),window);

    %    try

    
    % 13 Mar 11 by NT
  if 0 
      Screen(window,'FillRect',lum.black);
    Screen(window,'TextSize', font1);
    Screen(window,'DrawText',...
        sprintf('Press any key to start trial %3.3d/%3.3d',trial,nTrials),...
        350,390,lum.white);
    % 13 Mar 11 by NT
    Screen('flip',window');
  end 
    % 13 Mar 11 by NT
    if 0
        keyP = 0;
        while ~keyP
            [keyP,dummy,keyC] = KbCheck;
        end
    else
        [keyP,dummy,keyC] = KbCheck;
    end
    
    if keyC(27)
        % esc was pressed
        save(sprintf('%s_ESC',fileName));
        Screen('CloseAll');
        ShowCursor;
        eyelink('closefile');
        eyelink('shutdown');
        warning('Esc pressed, experiment ended.');
        keyboard;
    end

    % 13 Mar 11 by NT
    if 0
        while KbCheck end
    end

    found = 0;
    while ~found
        Screen(window,'FillRect',lum.black);
        arrowTime(trial) = GetSecs;
        if 0 % 2013 Mar 11 by NT
            Screen(window,'WaitBlanking',1);
        else
            screen('flip',window);
        end

        %        Screen('CopyWindow',target{locIdx(trial),tiltIdx(trial),sfIdx(trial)},window,[],rectLoc{locIdx(trial)});
        Screen('CopyWindow',arrow_inv{arrow2Idx(trial)},window,[],arrowLoc{arrow2locIdx(trial)}); %, rectLoc{locIdx(trial)});
        Screen(window,'TextSize', font2);
        if 0  % 13 Mar 11 by NT
            Screen(window,'DrawText',...
                sprintf('+',trial,nTrials),...
                499,396,255);
        end
        %Screen(window,'WaitBlanking',arrowDur);
        % Screen(window,'FillRect',lum.black);
        trialStarted(trial)=trialStarted(trial)+1;
        startTime(trial) = GetSecs;
        if 0 % 2013 Mar 11 by NT
            eyelink('message', 'MARKERID %i - %i', SIG_TGT_ON,trialStarted(trial));
            found = WaitUntilFound(el,512,384,72,0.5,5);
        else
            found = 1;
        end

        if ~found
            Screen(window,'WaitBlanking',1);
            Screen(window,'FillRect',lum.black);

            fprintf('Drift correction...');
            eyelink('stoprecording');
            WaitSecs(0.1);
            if 0 % 2013 Mar 11 by NT
                status = dodriftcorrection(el,1024/2,768/2,1,1);
            end
            if status~=1
                fprintf('failed (%3.3d).\n',status);
            else
                fprintf('done (ok).\n');
            end

            if 0 % 2013 Mar 11 by NT
                eyelink('startrecording');
            end
            WaitSecs(0.1);
            fprintf('recording restarted.\n');
        end

    end
    
    if trial == 1
        tgtOnTime(trial) = GetSecs;
    else

        while 1
            tgtOnTime(trial) = GetSecs;
            if tgtOnTime(trial) - tgtOnTime(trial-1) > 5
                break
            end
        end
    end
    
    if 0 % 2013 Mar 11 by NT
        eyelink('message', 'MARKERID %i', SIG_SER_ON);
    end
    % present stimulus
    for iFrame = 1:SFM.nframe
        if 0 % 2013 Mar 11 by NT
            screen(window,'waitBlanking')
        else
            screen('flip',window);
        end
        screen('copywindow',Top(iFrame),window,[],imgRectTop)
        % screen('copywindow',Bot(iFrame),window,[],imgRectBot)
    end
    if 0 % 2013 Mar 11 by NT
        screen(window,'waitBlanking')
    else
        screen('flip',window);
    end

    Screen(window,'fillRect',lum.black)

    Screen('CopyWindow',arrow_inv{arrow2Idx(trial)},window,[],arrowLoc{arrow2locIdx(trial)});
    %Screen('CopyWindow',mask{locIdx(trial)},window,[],rectLoc{locIdx(trial)});
    %Screen('CopyWindow',mask{locIdx(trial)},window,[],rectLoc{locIdxdummy(trial)});
    if 0 % 2013 Mar 11 by NT
        Screen(window,'WaitBlanking',arrowDur2);
    else
        screen('flip',window);
    end
    Screen(window,'FillRect',lum.black);
    if 0 % 2013 Mar 11 by NT
        eyelink('message', 'MARKERID %i', SIG_SER_OFF);
    end
    maskOffTime(trial) = GetSecs;

    % now read 2afc response
    if 0 % 2013 Mar 11 by NT
        Screen(window,'WaitBlanking');
    else
        screen('flip',window);
    end
    Screen(window,'TextSize', font1);
    Screen(window,'DrawText','Front surface going Left [1] or Right [0]: ',300,300,255);
 %    Screen(window,'DrawText','Counterclockwise [a]/Clockwise[s]: ',300,300,255);
    % 2013 Mar 11 by NT
    screen('flip',window);

    respOk = 0;
    while ~respOk & GetSecs - tgtOnTime(trial) < 4.5
        keyPressed = 0;
        while ~keyPressed
            [keyPressed,keyTime,keyCode] = KbCheck;
        end
        keyName = KbName(keyCode);
        if ~isempty(keyName)
            if (strcmp(lower(keyName(1)),'1'))
 %           if (strcmp(lower(keyName(1)),'a'))
                respOk = 1;
                respKey(trial)  = 2;
                respTime(trial) = keyTime;
            elseif (strcmp(lower(keyName(1)),'0'))
%            elseif (strcmp(lower(keyName(1)),'s'))
                respOk = 1;
                respKey(trial)  = 1;
                respTime(trial) = keyTime;

            end
        end

    end
    if respKey(trial)==2
        Screen(window,'DrawText','Left[1]',[],[],lum.white);
 %       Screen(window,'DrawText','Counterclockwise[a]',[],[],lum.white);
    elseif respKey(trial)==1
        Screen(window,'DrawText','Right[0]',[],[],lum.white);
%        Screen(window,'DrawText','Clockwise[s]',[],[],lum.white);
    end

    if 0 % 2013 Mar 11 by NT
        Screen(window,'WaitBlanking');
    else
        screen('flip',window);
    end

if 0 % 13 Mar 11 by NT
    WaitSecs(1);

    % now read confidence
    Screen(window,'DrawText','Confidence[1-4]: ',300,400,lum.white);
    screen('flip',window);
    % 13 Mar 11 by NT

    respOk = 0;
    while ~respOk
        keyPressed = 0;
        while ~keyPressed
            [keyPressed,keyTime,keyCode] = KbCheck;
        end
        keyName = KbName(keyCode);
        if ~isempty(keyName)
            keyNum = str2num(keyName(1));
            if ~isempty(keyNum)
                respOk = 1;
                confKey(trial)  = keyNum;
                confTime(trial) = keyTime;
            end

        end
    end
    Screen(window,'DrawText',num2str(confKey(trial)),[],[],lum.white);

    % 13 Mar 11 by NT
    screen('flip',window);
%1    WaitSecs(1);
    %    WaitSecs(0.2);
end 

    if ~mod(trial,25)
        % backup every 25 trials
        save(sprintf('%s_TMP%3.3d',fileName,trial));
    end
    if 0 % 2013 Mar 11 by NT
        % catch
        save(sprintf('%s_CRASH',fileName));
        Screen('CloseAll');
        ShowCursor;
        keyboard;
    end
end





% stop recording

fprintf('stop recording...');
eyelink('stoprecording');
fprintf('done.\n');

% close file
fprintf('Closing file...');
eyelink('closefile');
fprintf('done.\n');

% transfer data
%fprintf('Transfer data...');
% transfer eyelink result to same directory
%status = eyelink('receivefile',...
%   ELName,...
%  sprintf('..\\dataRaw\\%s\\%s',subjectID,ELName),...
% 0);
%if status~=0
%   Screen('CloseAll');
%  ShowCursor;
% error('File transfer from EL failed, check!');
%end
%fprintf('done.\n');

% save parameters
fprintf('saving matlab file...');
save(fileName,'-mat');
fprintf('done.\n');

% close all on and off Screens
Screen('CloseAll');

% Show Mouse pointer
ShowCursor;

% shutdown link
%fprintf('Eyelink shutdown...');
%eyelink('shutdown');
%fprintf('done.\n');

function [] = waitForKey

while ~KbCheck end
while KbCheck end


function [] = waitFor(charN);

flushEvents('keyDown');

keyN = 'X';
while (~strcmp(keyN,charN))
    keyP = 0;
    while ~keyP
        [keyP,keyT,keyC] = KbCheck;
        if keyP
            keyN = KbName(keyC);
            if isempty(keyN)
                keyN = 'X';
            else
                keyN = keyN(1)
            end
        end
    end
    while KbCheck end
end
