% function presentStructureFromMotion(SFM,T)
% 08 Aug 4 by Nao Tsuchiya
% present structure from motion stimuli
%
% SFM is a structure that contains basic parameters that specify the
% spatiotemporal parameters for structure from motion
%
% T is a structure that specifies parameters that are manipulated in each
% trial
% T.direction(1) - rotation direction for top
% T.direction(2) - rotation direction for bottom
% T.disparity(1) - disparity for top
% T.disparity(2) - disparity for top


addpath(genpath('c:\software\eyelink\'))
addpath(genpath('c:\software\Psychtoolbox\'))

dbstop if error
setParamsSFM_demo
clear screen
screenNumber = screen('screens');
[window,windowRect] = SCREEN(screenNumber,'OpenWindow',0);
frameRate = screen(screenNumber,'framerate');
%%
if SFM.frameRate ~= frameRate;
    error(['framerate should be ' num2str(SFM.frameRate) 'Hz'])
end

%%

SFM.imgRect = [windowRect(3)/2 - SFM.imgSize/2 ,...
    windowRect(4)/2 - SFM.imgSize/2,...
    windowRect(3)/2 + SFM.imgSize/2,...
    windowRect(4)/2 + SFM.imgSize/2];

imgRectTop = SFM.imgRect + [ 0 1 0 1]*SFM.distFromFixation;
imgRectBot = SFM.imgRect - [ 0 1 0 1]*SFM.distFromFixation;

disp('press 1-6 for report, press any key to start')
%%
for iTrial = 1:100



    %     iT(iTrial).disparity = [SFM.vDisparity(ceil(rand(1,2)*(SFM.nDisparity))) ];
    %     iT(iTrial).direction = [round(rand(1,2))*2-1];

    iT(iTrial).disparity = [SFM.vDisparity(ceil(rand(1,2)*(SFM.nDisparity))) ];
    iT(iTrial).direction = [-1 1]; %[round(rand(1,2))*2-1];

    if iTrial ==1
        %% top SFM
        Top = getSFMDotPos(SFM,iT(iTrial).disparity(1),iT(iTrial).direction(1),window);
        %% bottom SFM
        Bot = getSFMDotPos(SFM,iT(iTrial).disparity(2),iT(iTrial).direction(2),window);
    end

    if 0
        screen(window,'waitBlanking')
        screen(window,'fillrect',0)
        Screen(window,'DrawText','To start a next trial press a space bar.',400,300,255);
        while kbcheck; end
        while ~kbcheck; end
        screen(window,'waitBlanking')
        screen(window,'fillrect',0)
    end

    iT(iTrial).startStimTime = getsecs;

    for iFrame = 1:SFM.nframe
        screen(window,'waitBlanking')
        screen('copywindow',Top(iFrame),window,[],imgRectTop)
        screen('copywindow',Bot(iFrame),window,[],imgRectBot)
    end
    screen(window,'waitBlanking')
    screen(window,'fillrect',0)



    Screen(window,'DrawText','Press 1 to if the front surface moved towards LEFT. If not, press 2.',400,300,255);
    while kbcheck; end
    while ~kbcheck; end
    screen(window,'waitBlanking')
    screen(window,'fillrect',0)

    while 1
        [keyIsDown, timeSecs, keyCode ] = KbCheck; %whether there is a key pressed
        if keyIsDown

            tmp = KbName(keyCode);
            if iscell(tmp)
                continue
            end
            switch tmp(1)  %several keys pressed together -- read the first one
                case {'1','2','3','4','5','6',' '}
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

    disp(['dir = ' num2str(iT(iTrial).direction),...
        ' : resp=',num2str(iT(iTrial).response),...
        ' : disparity = ' num2str(iT(iTrial).disparity),...
        ' : RT=',num2str(( iT(iTrial).RT))])
end
asdf


