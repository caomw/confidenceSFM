% function presentApparentMotion(AM,T)
% 08 June 10 by Nao Tsuchiya
% present apparent motion stimuli
%
% AM is a structure that contains basic parameters that specify the
% spatiotemporal parameters for apparent motion
%
% T is a structure that specifies parameters that are manipulated in each
% trial
% T.angle(1) - rotation angle for top
% T.angle(2) - rotation angle for bottom
% T.initAngle(1) - initial angle for top
% T.initAngle(2) - initial angle for bottom


screenNumber = screen('screens');
[window,windowRect] = SCREEN(screenNumber,'OpenWindow',0,[0, 0, 800, 600]);

while kbcheck; end
while ~kbcheck; end


for iTrial = 1:10
    %% angles in degree
    
    iT(iTrial).initAngle = [AM.vInitAngle(ceil(rand(1,2)*length(AM.vInitAngle))) ];
    iT(iTrial).angle =     [AM.vRotation(ceil(rand(1,2)*length(AM.vRotation))) ];
    %% convert into radian
    iT(iTrial).initPha = iT(iTrial).initAngle/180*pi;
    iT(iTrial).pha = iT(iTrial).angle/180*pi;
    iT(iTrial).rotation = round(rand(1,2))*2-1;
    %% top dots
    Top = getDotPos(AM,iT(iTrial).initPha(1),iT(iTrial).pha(1)*iT(iTrial).rotation(1) );
    %% bottom dots
    Bot = getDotPos(AM,iT(iTrial).initPha(2),iT(iTrial).pha(2)*iT(iTrial).rotation(2));

    
    
    iT(iTrial).startStimTime = getsecs;

    screen(window,'waitBlanking')
    drawDot(AM,Top.dotPosXY11 + [0 AM.distFromFixation] ,window)
    drawDot(AM,Top.dotPosXY21 + [0 AM.distFromFixation] ,window)
    drawDot(AM,Bot.dotPosXY11 - [0 AM.distFromFixation] ,window)
    drawDot(AM,Bot.dotPosXY21 - [0 AM.distFromFixation] ,window)
    waitsecs(AM.stimOn);

    screen(window,'waitBlanking')
    screen(window,'fillRect',0)
    waitsecs(AM.stimOff);

    screen(window,'waitBlanking')
    drawDot(AM,Top.dotPosXY12 + [0 AM.distFromFixation] ,window)
    drawDot(AM,Top.dotPosXY22 + [0 AM.distFromFixation] ,window)
    drawDot(AM,Bot.dotPosXY12 - [0 AM.distFromFixation] ,window)
    drawDot(AM,Bot.dotPosXY22 - [0 AM.distFromFixation] ,window)
    waitsecs(AM.stimOn);

    screen(window,'waitBlanking')
    screen(window,'fillRect',0)

    while 1
        [keyIsDown, timeSecs, keyCode ] = KbCheck; %whether there is a key pressed
        if keyIsDown
            tmp = KbName(keyCode);
            if iscell(tmp)
                continue
            end
            switch tmp(1)  %several keys pressed together -- read the first one
                case {'1','2','3','4','5','6'}
                    iT(iTrial).response = str2num(tmp(1));
                    iT(iTrial).RT = GetSecs - iT(iTrial).startStimTime;
                    break
                case 'q'
                    asdf
                    return
            end
        end
        while ~kbcheck; end
    end
    disp(['resp=',num2str(iT(iTrial).response),...
        ' : RT=',num2str(round( iT(iTrial).RT))])
end
    asdf


    if 0
        figure(1),clf, hold on
        plot(dotPosXY11(1),dotPosXY11(2),'ro')
        plot(dotPosXY21(1),dotPosXY21(2),'rx')

        plot(dotPosXY12(1),dotPosXY12(2),'bo')
        plot(dotPosXY22(1),dotPosXY22(2),'bx')
        axis([-1 1 -1 1]*AM.radius)
    end