function [] = runConf1(subjectID,correctMode);

%
% function [] = runConf1(subjectID,fracCorrect);
%
% subjectID   - 2 character ID for subject
% correctMode - 1: 100%
%               2: 75%
% wet@caltech.edu, 2006-Aug-14
%


% global constants
setConstants;

% subjectID
subjectID = upper(subjectID);

% check input parameter
if length(subjectID)~=2
    error('Subject ID must have two characters');
end

if nargin<2
    fracCorrect=1;
    warning('All cues correct');
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
targetOri     = [0.25,0.5,1,2,4,8,16,32]; % degrees
maskOri       = 90;
patchSize     = 178;            % 5 deg
envSize       = 0.125;            % relative to patch
sf            = 8;               % cycles per patchsize
targetPhase   = pi/2;               %
targetDur     = 2;               % screen refreshes (50ms);
targetMaskSOA = 6;               % screen refreshes (50ms);
maskDur       = 60;              % screen refreshes (500ms);
arrowToStim   = 0.5;

arrowSize     = 40;              % pixel
arrowDur      = 0.5;             % ms;

fixationSizeH = 3;              % pixel
fixationDur   = 0.5;            % s;

% total number of trials
nTrials = 128;

if ~exist(sprintf('..\\dataRaw\\%s\\',subjectID));
    mkdir(sprintf('..\\dataRaw\\%s\\',subjectID));
end
% filename
sessionNum = 1;
while exist(sprintf('..\\dataRaw\\%s\\%s%3.3d.mat',subjectID,subjectID,sessionNum));
    sessionNum = sessionNum+1;
end

fileName = sprintf('..\\dataRaw\\%s\\%s%3.3d.mat',subjectID,subjectID,sessionNum)
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
if ((length(targetOri)~=8)|(mod(nTrials,length(targetOri)*4)))
    error('randomization has to be changed for your number of trials');
end 

tmp = randperm(nTrials);
tmp2 = mod(tmp-1,32)+1;
oriIdx = ceil(tmp2/4);

if correctMode==1
    cueCorrect = ones(1,nTrials);
else
    cueCorrect = (mod(tmp2,4)>0);
end 

% random tilt for each trial
tiltIdx = (rand(1,nTrials)>0.5)+1;

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

% background (fixation screen);
bgScreen = Screen(window,'OpenOffScreenWindow',lum.gray);
Screen(bgScreen,'FillRect',lum.black,...
    [xSize/2-fixationSizeH,...
    ySize/2-fixationSizeH,...
    xSize/2+fixationSizeH,...
    ySize/2+fixationSizeH]);

% prepare all offscreen windows
target = cell(2,2,length(targetOri)); % up/down, left/right, ori
mask   = cell(2,1);


for ud = 1 : 2

    for lr = 1 : 2

        for oriC = 1 : length(targetOri)

            % create offscreen window
            target{ud,lr,oriC} = Screen(window,'OpenOffScreenWindow',lum.gray);


            % total screen
            TT = lum.gray*ones(ySize,xSize);

            % place fixation cross
            TT((ySize/2-fixationSizeH+1):(ySize/2+fixationSizeH),...
                (xSize/2-fixationSizeH+1):(xSize/2+fixationSizeH))=...
                lum.black;

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

            TT((ySize/2+verticalOff(ud)-patchSize/2+1):(ySize/2+verticalOff(ud)+patchSize/2),...
                (xSize/2-patchSize/2+1):(xSize/2+patchSize/2))=Glin;

            % place TT on offscreen
            Screen(target{ud,lr,oriC},'PutImage',TT);

        end

    end

    % create offscreen window
    mask{ud} = Screen(window,'OpenOffScreenWindow',lum.gray);

    % total screen
    TT = lum.gray*ones(ySize,xSize);

    % place fixation cross
    TT((ySize/2-fixationSizeH+1):(ySize/2+fixationSizeH),...
        (xSize/2-fixationSizeH+1):(xSize/2+fixationSizeH))=...
        lum.black;

    % compute wavelet
    G = makeGabor(...
        maskOri,...
        sf,...
        envSize,...
        targetPhase,...
        patchSize);

    % linear G
    Glin = round(makeLinearKlab(grayNL*G+grayNL));

    TT((ySize/2+verticalOff(ud)-patchSize/2+1):(ySize/2+verticalOff(ud)+patchSize/2),...
        (xSize/2-patchSize/2+1):(xSize/2+patchSize/2))=Glin;

    % place TT on offscreen
    Screen(mask{ud},'PutImage',TT);

end


% Prepare arrows
for ud = 1 : 2
    arrow{ud} = Screen(window,'OpenOffscreenWindow',lum.gray);
    Screen(arrow{ud},'PutImage',makeArrow(ud,arrowSize,lum.black,lum.gray));
end

% Clear Screen and Hide Mouse pointer
Screen(window,'FillRect',lum.gray);
HideCursor;


% initialize eyetracker
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
fprintf('done.\n');

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
confKey  = nan(1,nTrials);
confTime = nan(1,nTrials);
startTime = nan(1,nTrials);
trialStarted = zeros(1,nTrials);
arrowTime = nan(1,nTrials);
arrowEnd  = nan(1,nTrials);
endTime   = nan(1,nTrials);


for trial = 1 : nTrials

    try

        fixOk = 0;

        while ~fixOk
            Screen(window,'FillRect',lum.gray);
            Screen(window,'DrawText',...
                sprintf('Press any key to start trial %3.3d/%3.3d',trial,nTrials),...
                300,300,0);
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

                Screen(window,'WaitBlanking');
                Screen(window,'FillRect',lum.gray);
                Screen(window,'WaitBlanking');
                Screen('CopyWindow',bgScreen,window);

                trialStarted(trial)=trialStarted(trial)+1;
                startTime(trial) = GetSecs;
                eyelink('message', 'MARKERID %i - %i', SIG_TGT_ON,trialStarted(trial));

                found = WaitUntilFound(el,512,384,36,0.5,5);
                if ~found
                    fprintf('Drift correction...');
                    eyelink('stoprecording');
                    WaitSecs(0.1);
                    dodriftcorrection(el,1024/2,768/2,1,1);
                    eyelink('startrecording');
                    WaitSecs(0.1);
                    fprintf('done.\n');
                end

            end
            
            arrowTime(trial) = GetSecs;

            Screen(window,'WaitBlanking',1);
            Screen('CopyWindow',arrow{arrowIdx(trial)},window);
            fixOk = verifyFixation(el,512,384,36,arrowDur);
            if fixOk
                Screen(window,'WaitBlanking');
                Screen('CopyWindow',bgScreen,window);
                fixOk = verifyFixation(el,512,384,36,arrowToStim);
            end
        end
        arrowEnd(trial) = GetSecs;
        eyelink('message', 'MARKERID %i', SIG_SER_ON);
        Screen(window,'WaitBlanking',1);
        Screen('CopyWindow',target{locIdx(trial),tiltIdx(trial),oriIdx(trial)},window);
        Screen(window,'WaitBlanking',targetDur);
        Screen('CopyWindow',bgScreen,window);
        Screen(window,'WaitBlanking',targetMaskSOA);
        Screen('CopyWindow',mask{locIdx(trial)},window);
        Screen(window,'WaitBlanking',maskDur);
        Screen(window,'FillRect',lum.gray);
        eyelink('message', 'MARKERID %i', SIG_SER_OFF);
        endTime(trial) = GetSecs;

        % now read 2afc response
        Screen(window,'WaitBlanking');
        Screen(window,'DrawText','Left/Right: ',300,300,0);
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
            Screen(window,'DrawText','Left (\)',[],[],0);
        elseif respKey(trial)==1
            Screen(window,'DrawText','Right (/)',[],[],0);
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
            % backup every 50 trials
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
fprintf('Transfer data...');
% transfer eyelink result to same directory
status = eyelink('receivefile',...
    ELName,...
    sprintf('..\\dataRaw\\%s\\%s',subjectID,ELName),...
    0);
if status~=0
    Screen('CloseAll');
    ShowCursor;
    error('File transfer from EL failed, check!');
end
fprintf('done.\n');

% save parameters
fprintf('saving matlab file...');
save(fileName,'-mat');
fprintf('done.\n');

% close all on and off screens
Screen('CloseAll');

% Show Mouse pointer
ShowCursor;

% shutdown link
fprintf('Eyelink shutdown...');
eyelink('shutdown');
fprintf('done.\n');

function [] = waitForKey

while ~KbCheck end
while KbCheck end
