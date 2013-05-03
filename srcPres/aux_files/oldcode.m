% desired  refresh rate
scrFreq = SFM.frameRate; % Hz

% screen parameters
whiteNL = 26; % cd/m2
blackNL = 0;  % cd/m2
grayNL  = 13; % cd/m2

lum.black = round(makeLinearKlab(blackNL));
lum.gray  = round(makeLinearKlab(grayNL));
lum.white = round(makeLinearKlab(whiteNL));
lum.text = lum.white;

verticalOff   = [178, -178];      % pixels; 5deg
verticalOffdummy   = [-178, 178];      % pixels; 5deg
arrowverticalOff = [54, -54];
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



cross
[Wcross, WcrossRect]=Screen(Exp.Cfg.win,'OpenOffscreenWindow',lum.black);
crect=[0 0 20 20];
r1=[0 10 20 10];
r2=[10 0 10 20];
crossRect = CenterRect(crect, Exp.Cfg.windowRect);
crossRect = CenterRect(crect,WcrossRect);
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
    arrow{ud} = Screen(Exp.Cfg.win,'OpenOffscreenWindow',lum.black, [0 0 patchSize patchSize]);
    Screen(arrow{ud},'PutImage',makeArrow(ud,arrowSize,lum.white,lum.black));
end

for ud_2 = 1 : 2
    arrowLoc2{ud_2} = [(xSize/2-patchSize/2), arrowverticalOff(ud)+(ySize/2-patchSize/2), patchSize+(xSize/2-patchSize/2),arrowverticalOff(ud)+patchSize+(ySize/2-patchSize/2)];
end


% Prepare inverse arrows
for ud_2 = 1 : 2
    arrow_inv{ud_2} = Screen(Exp.Cfg.win,'OpenOffscreenWindow',lum.black, [0 0 patchSize patchSize]);
    Screen(arrow_inv{ud_2},'PutImage',makeArrow(ud_2,arrowSize,lum.white,lum.black));
end

% Clear Screen and Hide Mouse pointer
Screen(Exp.Cfg.win,'FillRect',lum.black);
HideCursor;

leftarrow='<--';
rightarrow='-->';
Screen(window,'DrawText',leftarrow, 100, 100);
Screen(window,'DrawText',rightarrow, 200, 100);

%%

Screen('CopyWindow',arrow_inv{arrow2Idx(trial)}, Exp.Cfg.win, [], arrowLoc{arrow2locIdx(trial)});
%Screen('CopyWindow',mask{locIdx(trial)},Exp.Cfg.win,[],rectLoc{locIdx(trial)});
%Screen('CopyWindow',mask{locIdx(trial)},Exp.Cfg.win,[],rectLoc{locIdxdummy(trial)});
if 0 % 2013 Mar 11 by NT
    Screen(Exp.Cfg.win,'WaitBlanking',arrowDur2);
else
    screen('flip',Exp.Cfg.win);
end
Screen(Exp.Cfg.win,'FillRect',lum.black);
if 0 % 2013 Mar 11 by NT
    trialstart = iViewX('message',ivx, 'MARKERID %i', SIG_SER_OFF);
    %             eyelink('message', 'MARKERID %i', SIG_SER_OFF);
end
maskOffTime(trial) = GetSecs;

% now read 2afc response
if 0 % 2013 Mar 11 by NT
    Screen(Exp.Cfg.win,'WaitBlanking');
else
    screen('flip',Exp.Cfg.win);
end
Screen(Exp.Cfg.win,'TextSize', font1);
Screen(Exp.Cfg.win,'DrawText','Front surface going Left [1] or Right [0]: ', 300, 300, 255);
%    Screen(Exp.Cfg.win,'DrawText','Counterclockwise [a]/Clockwise[s]: ',300,300,255);
% 2013 Mar 11 by NT
screen('flip',Exp.Cfg.win);

respOk = 0;
while ~respOk && GetSecs - tgtOnTime(trial) < 4.5
    keyPressed = 0;
    while ~keyPressed
        [keyPressed,keyTime,keyCode] = KbCheck;
    end
    keyName = KbName(keyCode);
    if ~isempty(keyName)
        if (strcmp(keyName(1),'1'))
            %           if (strcmp(lower(keyName(1)),'a'))
            respOk = 1;
            respKey(trial)  = 2;
            respTime(trial) = keyTime;
        elseif (strcmp(keyName(1),'0'))
            %            elseif (strcmp(lower(keyName(1)),'s'))
            respOk = 1;
            respKey(trial)  = 1;
            respTime(trial) = keyTime;
            
        end
    end
    
end

if respKey(trial) == 2
    Screen(Exp.Cfg.win,'DrawText','Left[1]',[],[],lum.white);
    %       Screen(Exp.Cfg.win,'DrawText','Counterclockwise[a]',[],[],lum.white);
elseif respKey(trial) == 1
    Screen(Exp.Cfg.win,'DrawText','Right[0]',[],[],lum.white);
    %        Screen(Exp.Cfg.win,'DrawText','Clockwise[s]',[],[],lum.white);
end

if 0 % 2013 Mar 11 by NT
    Screen(Exp.Cfg.win,'WaitBlanking');
else
    screen('flip',Exp.Cfg.win);
end

if 0 % 13 Mar 11 by NT
    WaitSecs(1);
    
    % now read confidence
    Screen(Exp.Cfg.win,'DrawText','Confidence[1-4]: ',300,400,lum.white);
    screen('flip',Exp.Cfg.win);
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
    Screen(Exp.Cfg.win,'DrawText',num2str(confKey(trial)),[],[],lum.white);
    
    % 13 Mar 11 by NT
    screen('flip',Exp.Cfg.win);
    WaitSecs(1);
    %    WaitSecs(0.2);
end

if ~mod(trial,25)
    % backup every 25 trials
    save(sprintf('%s_TMP%3.3d',fileName,trial));
end



