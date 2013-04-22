function [] = runConf1(subjectID,correctMode,demoOn);

%
% function [] = runConf1(subjectID,fracCorrect);
%
% subjectID   - 2 character ID for subject
% correctMode - 1: 100%
%               2: 75%
% demoOn      - display examples at start of block
% wet@caltech.edu, 2006-Aug-14
% 2006-Sep-19

addpath(genpath('c:\software\eyelink\'))
addpath(genpath('c:\software\Psychtoolbox\'))

% global constants
setConstants;


% desired screen size
xSize = 1024;
ySize = 768;
setParamsAM

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



% desired screen refresh rate
scrFreq = 120; % Hz

% desired screen size
xSize = 1024;
ySize = 768;

% screen parameters
whiteNL = 26; % cd/m2
blackNL = 0;  % cd/m2
grayNL  = 13; % cd/m2

lum.black = round(makeLinearKlab(blackNL));
lum.gray  = round(makeLinearKlab(grayNL));
lum.white = round(makeLinearKlab(whiteNL));


verticalOff   = [178,-178];      % pixels; 5deg
verticalOffdummy   = [-178,178];      % pixels; 5deg
arrowverticalOff = [54,-54];
font1 = 12;
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



% open screen
[window,rect] = Screen(0,'OpenWindow',lum.gray);

% verify screen refresh rate
t0_test = GetSecs;
Screen(window,'WaitBlanking',10);
t1_test = GetSecs;
if abs((t1_test-t0_test)/10-1/scrFreq)>1/scrFreq;
    Screen('CloseAll');
    error(sprintf('Screen rate must be within 10%% of %3.3dHz',scrFreq));
end

% verify resoultion
if any(rect~=[0 0 xSize ySize])
    Screen('CloseAll');
    error('Screen Resoultion must be x=%d, y=%d',xSize,ySize');
end


Screen(window,'DrawText','Preparing session, please wait.',400,300,0);


%cross
[Wcross, WcrossRect]=Screen(window,'OpenOffscreenWindow',lum.gray);
crect=[0 0 20 20];
r1=[0 10 20 10];
r2=[10 0 10 20];
crossRect=CenterRect(crect,WcrossRect);
Screen(Wcross,'DrawLine',lum.black,r1(1),r1(2),r1(3),r1(4));%,scalar*1,scalar*1);
Screen(Wcross,'DrawLine',lum.black,r2(1),r2(2),r2(3),r2(4));%,scalar*1,scalar*1);


% prepare all offscreen windows
target = cell(2,2,length(targetOri)); % up/down, left/right, ori
mask   = cell(2,1);

for ud = 1 : 2
   rectLoc{ud} = [(xSize/2-patchSize/2), verticalOff(ud)+(ySize/2-patchSize/2), patchSize+(xSize/2-patchSize/2),verticalOff(ud)+patchSize+(ySize/2-patchSize/2)];
end

for ud = 1 : 2

    for lr = 1 : 2

       for oriC = 1 : length(targetOri)

            % create offscreen window
            target{ud,lr,oriC} = Screen(window,'OpenOffScreenWindow',lum.gray,[0 0 patchSize patchSize]);
               
            % compute wavelet
            if lr==1
               G = makeGabor(...
                    targetOri(oriC),...
                    sf,...
                    envSize,...
                    targetPhase,...
                    patchSize);
            else
                G = makeGabor(...
                    -targetOri(oriC),...
                    sf,...
                    envSize,...
                    targetPhase,...
                    patchSize);
            end

            % linear G
            Glin = round(makeLinearKlab(grayNL*G/2+grayNL));


            % place TT on offscreen
             Screen(target{ud,lr,oriC},'PutImage',Glin);

        end

    end

    % create offscreen window
    mask{ud} = Screen(window,'OpenOffScreenWindow',lum.gray,[0 0 patchSize patchSize]);


    % compute wavelet
    G1 = makeGabor(...
        0,...
        sf,...
        envSize,...
        targetPhase,...
        patchSize);

    G2 = makeGabor(...
        90,...
        sf,...
        envSize,...
        targetPhase,...
        patchSize);

    G = (G1+G2)/2;
    % linear G
    Glin = round(makeLinearKlab(grayNL*G+grayNL));


    % place TT on offscreen
    Screen(mask{ud},'PutImage',Glin);

end





for ud = 1 : 2
   arrowLoc{ud} = [(xSize/2-patchSize/2), arrowverticalOff(ud)+(ySize/2-patchSize/2), patchSize+(xSize/2-patchSize/2),arrowverticalOff(ud)+patchSize+(ySize/2-patchSize/2)];
end


% Prepare arrows
for ud = 1 : 2
    arrow{ud} = Screen(window,'OpenOffscreenWindow',lum.gray, [0 0 patchSize patchSize]);
    Screen(arrow{ud},'PutImage',makeArrow(ud,arrowSize,lum.black,lum.gray));
end

for ud_2 = 1 : 2
   arrowLoc2{ud_2} = [(xSize/2-patchSize/2), arrowverticalOff(ud)+(ySize/2-patchSize/2), patchSize+(xSize/2-patchSize/2),arrowverticalOff(ud)+patchSize+(ySize/2-patchSize/2)];
end


% Prepare inverse arrows
for ud_2 = 1 : 2
    arrow_inv{ud_2} = Screen(window,'OpenOffscreenWindow',lum.gray, [0 0 patchSize patchSize]);
    Screen(arrow_inv{ud_2},'PutImage',makeArrow(ud_2,arrowSize,lum.black,lum.gray));
end

% Clear Screen and Hide Mouse pointer
Screen(window,'FillRect',lum.gray);
HideCursor;

if (demoOn)
    Screen('CopyWindow',target{2,2,1},window,[],rectLoc{2});
    Screen(window,'DrawText','Here you see an example for a low frequency stimulus',100,100);
    Screen(window,'DrawText','Press any key to see another low frequency stimulus.',100,500);
    while ~KbCheck end
    while KbCheck end
    Screen('CopyWindow',target{2,2,2},window,[],rectLoc{2});
    Screen(window,'DrawText','Here you see an example for a low frequency stimulus',100,100);
    Screen(window,'DrawText','Press any key to see another low frequency stimulus.',100,500);
   % Screen(window,'DrawText','In the real experiment, it will be presented only briefly.',100,400);
   % Screen(window,'DrawText','And can occur in the upper or lower hemifield.',100,450);
    %Screen(window,'DrawText','Press any key to see a demo.',100,500);
    while ~KbCheck end
    while KbCheck end
    Screen('CopyWindow',target{2,2,3},window,[],rectLoc{2});
    Screen(window,'DrawText','Here you see an example for a low frequency stimulus',100,100);
    Screen(window,'DrawText','Press any key to see another low frequency stimulus.',100,500);
    while ~KbCheck end
    while KbCheck end
    Screen(window,'FillRect',lum.gray);
    Screen('CopyWindow',target{2,2,4},window,[],rectLoc{2});
    Screen(window,'DrawText','Here you see an example for a high frequency stimulus',100,100);
    Screen(window,'DrawText','Press any key to see another high frequency stimulus.',100,500);
    while ~KbCheck end
    while KbCheck end
    Screen('CopyWindow',target{2,2,5},window,[],rectLoc{2});
    Screen(window,'DrawText','Here you see an example for a high frequency stimulus',100,100);
    Screen(window,'DrawText','Press any key to see another high frequency stimulus.',100,500);
    while ~KbCheck end
    while KbCheck end
    Screen(window,'FillRect',lum.gray);
    Screen('CopyWindow',target{2,2,6},window,[],rectLoc{2});
    Screen(window,'DrawText','Here you see an example for a high frequency stimulus',100,100);
    Screen(window,'DrawText','In the real experiment, it will be presented only briefly.',100,400);
    Screen(window,'DrawText','And can occur in the upper or lower hemifield.',100,450);
    Screen(window,'DrawText','Press any key to see a demo.',100,500);
    while ~KbCheck end
    while KbCheck end
    Screen(window,'FillRect',lum.gray);
    Screen(window,'WaitBlanking',60);
    Screen('CopyWindow',target{2,2,1},window,[],rectLoc{2});
    Screen(window,'WaitBlanking',targetDur);
    Screen(window,'FillRect',lum.gray);
    Screen(window,'WaitBlanking');
    Screen(window,'DrawText','In addition, there will be a mask after the stimulus.',100,100);
    Screen(window,'DrawText','Press any key to see this.',100,150); 
    while ~KbCheck end
    while KbCheck end
    Screen(window,'FillRect',lum.gray);
    Screen('CopyWindow',target{2,2,3},window,[],rectLoc{2});
    Screen(window,'WaitBlanking',targetDur);
    Screen('CopyWindow',mask{2},window,[],rectLoc{2});
    Screen(window,'WaitBlanking',maskDur1);
    Screen(window,'FillRect',lum.gray);
    Screen(window,'DrawText','After each such presentation you will have to decide,.',100,100);
    Screen(window,'DrawText','whether the stimulus was low or high frequency.',100,150);    
    Screen(window,'DrawText','and how certain you are about the judgment.',100,200);    
    Screen(window,'DrawText','If the stimulus was low frequency',100,300);
    Screen(window,'DrawText','Press 1 if you are certain',200,350);
    Screen(window,'DrawText','Press 3 if you are guessing',200,375);
    Screen(window,'DrawText','Press 2 if you are between guess and certainty',200,400);
    Screen(window,'DrawText','Try to use the full scale and match it to your internal confidence.',100,450);
    Screen(window,'DrawText','Now let''s test the keys:',100,500);

    Screen(window,'WaitBlanking');
    Screen(window,'DrawText','Press 1: ',200,550);
    waitFor('1');
    Screen(window,'WaitBlanking');
    Screen(window,'DrawText','1 (low - certain)');

    Screen(window,'WaitBlanking');
    Screen(window,'DrawText','Press 2: ',200,575);
    waitFor('2');
    Screen(window,'WaitBlanking');
    Screen(window,'DrawText','2 (low - medium confidence)');

    Screen(window,'WaitBlanking');
    Screen(window,'DrawText','Press 3: ',200,600);
    waitFor('3');
    Screen(window,'WaitBlanking');
    Screen(window,'DrawText','3 (low - guessing)');
    
    Screen(window,'WaitBlanking',120);
    Screen(window,'FillRect',lum.gray);
    Screen(window,'WaitBlanking');
    Screen(window,'DrawText','For high frequency gratings, use the symmetric layout and keys 4-6:',100,200);
    
    Screen(window,'WaitBlanking');
    Screen(window,'DrawText','Press 4: ',200,250);
    waitFor('4');
    Screen(window,'WaitBlanking');
    Screen(window,'DrawText','4 (high, guessing)');

    Screen(window,'WaitBlanking');
    Screen(window,'DrawText','Press 5: ',200,275);
    waitFor('5');
    Screen(window,'WaitBlanking');
    Screen(window,'DrawText','5 (high, medium confidence)');

    Screen(window,'WaitBlanking');
    Screen(window,'DrawText','Press 6: ',200,300);
    waitFor('6');
    Screen(window,'WaitBlanking');
    Screen(window,'DrawText','6 (high, certain)');
    
    Screen(window,'WaitBlanking');
    Screen(window,'DrawText','As soon as you are ready, press any key, to start the experiment.',100,400);
    waitForKey;
end

el=initeyelinkdefaults;
el.backgroundcolour = lum.gray;
el.foregroundcolour = lum.black;
initEL1000(ELName);


% camera setup and calibration
fprintf('Setup...');
status=dotrackersetup(el, el.ENTER_KEY);
if status
    Screen('CloseAll');
    ShowCursor;
    error('Setup failed');
end
fprintf('done.\n');

% driftcorrection
fprintf('Drift correction...');
status = dodriftcorrection(el,1024/2,768/2,1,1);
if status~=1
   fprintf('failed (%3.3d).\n',status);
else
    fprintf('done.\n');
end
% start recording
fprintf('Start Recording...');
status = eyelink('startrecording');
if status
    Screen('CloseAll');
    ShowCursor;
    error('Recording failed');
end
fprintf('done.\n');


%

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
    
%    if arrowIdx(trial)==1
%    arrow2Idx(trial) = 2;
%else
%    arrow2Idx(trial) = 1;
%    end 

    if locIdx(trial)==1
    locIdxdummy(trial) = 2;
else
    locIdxdummy(trial) = 1;
    end 

    
    %% prepare a trial
    iT(trial).initAngle = [AM.vInitAngle(ceil(rand(1,2)*length(AM.vInitAngle))) ];
    iT(trial).angle =     [AM.vRotation(ceil(rand(1,2)*length(AM.vRotation))) ];
    %% convert into radian
    iT(trial).initPha = iT(trial).initAngle/180*pi;
    iT(trial).pha = iT(trial).angle/180*pi;
    iT(trial).rotation = round(rand(1,2))*2-1;
    %% top dots
    Top = getDotPos(AM,iT(trial).initPha(1),iT(trial).pha(1)*iT(trial).rotation(1) );
    %% bottom dots
    Bot = getDotPos(AM,iT(trial).initPha(2),iT(trial).pha(2)*iT(trial).rotation(2));

    
    try

        Screen(window,'FillRect',lum.gray);
         Screen(window,'TextSize', font1);
        Screen(window,'DrawText',...
            sprintf('Press any key to start trial %3.3d/%3.3d',trial,nTrials),...
            350,390,0);
        keyP = 0;
        while ~keyP
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

        while KbCheck end

        found = 0;
        while ~found
            Screen(window,'FillRect',lum.gray);
            arrowTime(trial) = GetSecs;
            Screen(window,'WaitBlanking',1);
  %                  Screen('CopyWindow',target{locIdx(trial),tiltIdx(trial),sfIdx(trial)},window,[],rectLoc{locIdx(trial)});

            Screen('CopyWindow',arrow{arrowIdx(trial)},window,[],arrowLoc{arrowIdx(trial)}); %, rectLoc{locIdx(trial)});
            Screen('CopyWindow',arrow_inv{arrow2Idx(trial)},window,[],arrowLoc{arrow2locIdx(trial)}); %, rectLoc{locIdx(trial)});
            Screen(window,'TextSize', font2); 
            Screen(window,'DrawText',...
            sprintf('+',trial,nTrials),...
            499,396,0);
            %Screen(window,'WaitBlanking',arrowDur);
            % Screen(window,'FillRect',lum.gray);
            trialStarted(trial)=trialStarted(trial)+1;
            startTime(trial) = GetSecs;
            eyelink('message', 'MARKERID %i - %i', SIG_TGT_ON,trialStarted(trial));

            found = WaitUntilFound(el,512,384,72,0.5,5);

            if ~found
                Screen(window,'WaitBlanking',1);
                Screen(window,'FillRect',lum.gray);

                fprintf('Drift correction...');
                eyelink('stoprecording');
                WaitSecs(0.1);
                status = dodriftcorrection(el,1024/2,768/2,1,1);
                if status~=1
                    fprintf('failed (%3.3d).\n',status);
                else
                    fprintf('done (ok).\n');
                end

                eyelink('startrecording');
                WaitSecs(0.1);
                fprintf('recording restarted.\n');
            end

        end
        
        tgtOnTime(trial) = GetSecs;
        eyelink('message', 'MARKERID %i', SIG_SER_ON);
        Screen(window,'WaitBlanking',1);
        %Screen('CopyWindow',target{locIdx(trial),tiltIdx(trial),oriIdx(trial)},window,[],rectLoc{locIdx(trial)});
        %Screen('CopyWindow',target{locIdxdummy(trial),tiltIdxdummy(trial),oriIdxdummy(trial)},window,[],rectLoc{locIdxdummy(trial)});
        %Screen(window,'WaitBlanking',targetDur);
        %Screen('CopyWindow',mask{locIdx(trial)},window,[],rectLoc{locIdx(trial)});
        %Screen('CopyWindow',mask{locIdx(trial)},window,[],rectLoc{locIdxdummy(trial)});
        %maskOnTime(trial) = GetSecs;
        %Screen(window,'WaitBlanking',maskDur1);
        
        Screen(window,'waitBlanking')
        drawDot(AM,Top.dotPosXY11 + [0 AM.distFromFixation] ,window)
        drawDot(AM,Top.dotPosXY21 + [0 AM.distFromFixation] ,window)
        drawDot(AM,Bot.dotPosXY11 - [0 AM.distFromFixation] ,window)
        drawDot(AM,Bot.dotPosXY21 - [0 AM.distFromFixation] ,window)
        WaitSecs(AM.stimOn);

        Screen(window,'waitBlanking',10)
        Screen(window,'fillRect',lum.gray)
        WaitSecs(AM.stimOff);

        Screen(window,'waitBlanking')
        drawDot(AM,Top.dotPosXY12 + [0 AM.distFromFixation] ,window)
        drawDot(AM,Top.dotPosXY22 + [0 AM.distFromFixation] ,window)
        drawDot(AM,Bot.dotPosXY12 - [0 AM.distFromFixation] ,window)
        drawDot(AM,Bot.dotPosXY22 - [0 AM.distFromFixation] ,window)
        WaitSecs(AM.stimOn);

        Screen(window,'waitBlanking',10)
        Screen(window,'fillRect',lum.gray)
        % end of AM presentation

        
        
        
        
        Screen('CopyWindow',arrow_inv{arrow2Idx(trial)},window,[],arrowLoc{arrow2locIdx(trial)});
        %Screen('CopyWindow',mask{locIdx(trial)},window,[],rectLoc{locIdx(trial)});
        %Screen('CopyWindow',mask{locIdx(trial)},window,[],rectLoc{locIdxdummy(trial)});
        Screen(window,'WaitBlanking',arrowDur2);
        Screen(window,'FillRect',lum.gray);
        eyelink('message', 'MARKERID %i', SIG_SER_OFF);
        maskOffTime(trial) = GetSecs;

       % now read 2afc response
        Screen(window,'WaitBlanking');
        Screen(window,'TextSize', font1);
        Screen(window,'DrawText','Counterclockwise/Clockwise: ',300,300,0);
        respOk = 0;
        while ~respOk
            keyPressed = 0;
            while ~keyPressed
                [keyPressed,keyTime,keyCode] = KbCheck;
            end
            keyName = KbName(keyCode);
            if ~isempty(keyName)
                if (strcmp(lower(keyName(1)),'a'))
                    respOk = 1;
                    respKey(trial)  = 2;
                    respTime(trial) = keyTime;
                elseif (strcmp(lower(keyName(1)),'s'))
                    respOk = 1;
                    respKey(trial)  = 1;
                    respTime(trial) = keyTime;

                end
            end

        end
        if respKey(trial)==2
            Screen(window,'DrawText','Counterclockwise',[],[],0);
        elseif respKey(trial)==1
            Screen(window,'DrawText','Clockwise',[],[],0);
        end

        % now read confidence
        Screen(window,'WaitBlanking');
        Screen(window,'DrawText','Confidence: ',300,400,0);
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
        Screen(window,'DrawText',num2str(confKey(trial)),[],[],0);
        WaitSecs(0.2);

        
        if ~mod(trial,25)
            % backup every 25 trials
            save(sprintf('%s_TMP%3.3d',fileName,trial));
        end

    catch
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
