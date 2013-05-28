function run_SFM


%% Modified by NT 13 Mar 11
% based on runConf_1k_SFM_new, which contains commands related to
% communication with eyelink.

% Goals
% 1. to present SFM stimuli to parkinson's disease patient.
% - preliminary studies show that their percept switches very quickly
% - test this by passive viewing (constant stimulation) with button press,
% or, by interleaved presentation, which might elicit stronger OKN at the
% onset of the stimuli.

% Pre-requisites:
% Add Psychophysics/ to the path to use 'initializeScreen.m'

% Parameters
% SFM is a structure that contains basic parameters that specify the
% spatiotemporal parameters for structure from motion
%
% T is a structure that specifies parameters that are manipulated in each
% trial
% T.direction(1) - rotation direction for top
% T.direction(2) - rotation direction for bottom
% T.disparity(1) - disparity for top
% T.disparity(2) - disparity for top

addpath('./aux_files/');
addpath('../iViewXNao/iViewXNao/');
PsychJavaTrouble;

try
    
    
    %% Initialize screen
    % PsychJavaTrouble; % Check there are no problems with Java
    Exp.Cfg.SkipSyncTest = 0; %This should be '0' on a properly working NVIDIA video card. '1' skips the SyncTest.
    Exp.Cfg.AuxBuffers = 1; % '0' if no Auxiliary Buffers available, otherwise put it into '1'.
    % Check for OpenGL compatibility
    AssertOpenGL;
    Screen('Preference','SkipSyncTests', Exp.Cfg.SkipSyncTest);
    
    Exp.Cfg.WinSize = [];  %Empty means whole screen
    Exp.Cfg.WinColor = []; % empty for the middle gray of the screen.
    
    Exp.Cfg.xDimCm = 47; %Length in cm of the screen in X
    Exp.Cfg.yDimCm = 30; %Length in cm of the screen in Y
    Exp.Cfg.distanceCm = 60; %Viewing distance
    
    Exp.Gral.SubjectName= input('Please enter subject ID:\n', 's');
    Exp.Gral.SubjectNumber= input('Please enter subject number:\n');
    
    Exp = initializeScreen (Exp);
    
    
    %% Define Parameters
    
    % subjectID
    subjectID = upper(Exp.Gral.SubjectName);
    
    % check input parameter
    if length(subjectID) ~= 2
        error('Subject ID must have two characters');
    end
    
%     if nargin < 2
%         correctMode = 1;
%         warning('All cues correct');
%     end
%     
%     if nargin < 2
%         demoOn = 1;
%     end
%     
    % Set experiment paths
    [Exp, fileName, ~, sessionNum] = setPaths(Exp, subjectID);
    
    % global constants
    %     SIG_TGT_ON   = 50;
    SIG_SER_ON   = 10;
    SIG_SER_OFF  = 20;
    
    Exp.SFM.trackEye = 1; % 1 : collect eye tracking data
    
    Exp.SFM.stimOn = 60; % 0.200; % in msec
    % Exp.SFM.stimOn = 0.200; % in msec
    % Exp.SFM.stimOff = 0.050; % in msec
    Exp.SFM.frameRate = 60; % 100; % 60;
    Exp.SFM.nframe = round( Exp.SFM.stimOn * Exp.SFM.frameRate );
    
    Exp.SFM.fixationXY = [Exp.Cfg.windowRect(3)/2 Exp.Cfg.windowRect(4)/2]; % half of the screen
    
    Exp.SFM.distFromFixation = 200; % in pixel , from fixation to the center of SFM
    
    Exp.SFM.dotSize = 6; % size of the dot
    Exp.SFM.color1 = [150 0 0];
    Exp.SFM.color1 = [0 80 0];
    Exp.SFM.nDots = 200; % 150
    
    Exp.SFM.vDisparity = 0; % 0.01 ; % potential disparity , 0 for completely ambiguous
    
    Exp.SFM.spinaxis = 2; % 1 for vertical, 2 for horizontal rotation
    Exp.SFM.dispFlag = 1; % 0 for disabling disparity
    
    Exp.SFM.radius = 5.5;  %degrees
    Exp.SFM.pixPerDeg = 30; % roughly
    Exp.SFM.imgSize = round(Exp.Cfg.pixelsPerDegree*Exp.SFM.radius*2)+(Exp.SFM.dotSize);  %size of one circular patch (plus buffer for dot size)  (in pixels)
    
    Exp.SFM.degPerSec = 50; %deg/sec
    
    Exp.SFM.nDisparity = length(Exp.SFM.vDisparity);
    
    % Initialize random number generators to subject dependent reconstructible
    % values
    Exp.seed = 1e5 * sessionNum + 100 * subjectID(1) + subjectID(2);
    rand('state', Exp.seed);
    randn('state', Exp.seed);
    
    % Set random initial position of dots
    dots.xflat(1:Exp.SFM.nDots) = (rand(Exp.SFM.nDots,1) - .5) * 2;
    dots.yflat(1:Exp.SFM.nDots) = (rand(Exp.SFM.nDots,1) - .5) * 2;
    
    runs = 9;
    nBlocks = 5; % number of blocks for the whole experiment
    nTrials             = [40 30  20  12  17  15  12   9     1]; % trials for each block
    stimFrames          = [30 60 120 240  30  60 120 240  3600]; % duration of stimulation -in frames-
    interStimInterval   = [60 60  60  60 180 180 180 180     0]; % duration of intervals between stimulation -in frames-
    run_id              ={'0.5-1' '1-1' '2-1' '4-1' '0.5-3' '1-3' '2-3' '4-3' '60-0'}; 
    
    % Preallocate all trials.
    for rn = 1 : runs
        for blk = 1 : nBlocks
            Exp.Run(rn).block(blk).id = run_id{rn};
            Exp.Run(rn).block(blk).nTrials = nTrials(rn);
            Exp.Run(rn).block(blk).stimFrames = stimFrames(rn);
            Exp.Run(rn).block(blk).interStimInterval = interStimInterval(rn);
            Exp.Run(rn).block(blk).disparity = 0;
            for tr = 1 : nTrials(rn)
                Exp.Run(rn).block(blk).direction(tr,1) = round( rand(1) ) * 2 - 1;
                Exp.Run(rn).block(blk).respType(1, 1: stimFrames(rn)) = nan(1, stimFrames(rn));
            end
        end
    end
    
    % Set the order of blocks
    Exp.randomize = 1;
    if Exp.randomize
        Exp.rnd_idxs = randperm(runs);
        Exp.Run = Exp.Run(Exp.rnd_idxs);
    end
    
    
    %% Initialize iView
    if Exp.SFM.trackEye
        Exp.ivx = init_iView (Exp);
    end    
    
    %% MAIN LOOP HERE
    Screen('FillRect',  Exp.Cfg.win, Exp.Cfg.Color.black);
    Screen(Exp.Cfg.win, 'DrawText', 'Press a button to start session', Exp.Cfg.centerX - 300, Exp.Cfg.centerY, Exp.Cfg.Color.white);
    Screen('Flip', Exp.Cfg.win,  [], Exp.Cfg.AuxBuffers);
    HideCursor;
    ListenChar(0);
    KbWait;
    
    for rn = 1 : runs
        
        % Trigger the beginning of the block
        if Exp.SFM.trackEye
            runStart = iViewX('message', Exp.ivx, ['START_RUN_' num2str(Exp.rnd_idxs(rn))]);
        end
        
        for blk = 1 : nBlocks
            
            % Trigger the beginning of the block
            if Exp.SFM.trackEye
                blockStart = iViewX('message', Exp.ivx, ['START_BK_' num2str(blk)]);
            end
            
            for trial = 1 : Exp.Run(rn).block(blk).nTrials
                
                % PRESENT STIMULUS
                for iFrame = 1 : Exp.Run(rn).block(blk).stimFrames
                    
                    % Clean screen
                    Screen('FillRect',  Exp.Cfg.win, Exp.Cfg.Color.black);
                    % Assign dot positions for each frame
                    [dots_x, dots_y, dots] = getSFMDotPos_2( Exp.SFM, Exp, dots, ...
                        Exp.Run(rn).block(blk).disparity, Exp.Run(rn).block(blk).direction(trial) );
                    
                    % Draw dots on screen
                    Screen('DrawDots', Exp.Cfg.win, [dots_x dots_y]', 6, [0 0 220])
                    Screen('flip',Exp.Cfg.win);
                    
                    % Send trigger for the beginning of each trial
                    if iFrame == 1 && Exp.SFM.trackEye
                        trial_id = num2str([blk trial]);
                        trial_id(ismember(trial_id,' ')) = [];
                        trialstart = iViewX('message', Exp.ivx, 'START_TR');
                    end
                    
                    % COLLECT CONTINUOUS RESPONSES HERE (one each frame)
                    [keyIsDown, ~, keyCode ] = KbCheck;
                    if keyIsDown
                        aux_response = KbName(keyCode);
                        Exp.Run(rn).block(blk).respType(trial, iFrame ) = str2double(aux_response(1));
%                         iT(trial).respType(iFrame) = str2double(aux_response(1));
                        
                        % ESCAPE KEY
                        % check_escapeKey ()
                        if strcmpi(KbName(keyCode), Exp.addParams.escapeKey)
                            % esc was pressed
                            save(sprintf('%s_ESC', fileName));
                            %             Screen('CloseAll');
                            ShowCursor;
                            %             eyelink('closefile');
                            %             eyelink('shutdown');
                            warning('Esc pressed, experiment ended.');
                            %             keyboard;
                            break;
                        end    
                    end
                end
                
                % INTER STIMULUS BLANK
                for iFrame = 1 : Exp.Run(rn).block(blk).interStimInterval
                    % Clean screen
                    Screen('FillRect',  Exp.Cfg.win, Exp.Cfg.Color.black);
                    Screen('flip',Exp.Cfg.win);
                    
                    if iFrame == 1
                        if Exp.SFM.trackEye
                            trialstart = iViewX('message', Exp.ivx, 'END_TR');
                        end
                    end
                end
            end
            
            % Trigger the end of the block
            if Exp.SFM.trackEye
                blockEnd = iViewX('message', Exp.ivx, ['END_BK_' num2str(blk)]);
            end
            
            % Show screen for inter trial inteval
            % Clean screen
            Screen('FillRect',  Exp.Cfg.win, Exp.Cfg.Color.black);
            Screen(Exp.Cfg.win, 'DrawText', 'End of Block, press space bar to continue.', ...
                Exp.Cfg.centerX - 300, Exp.Cfg.centerY, Exp.Cfg.Color.white);
            Screen('flip',Exp.Cfg.win);
            
            % Continue only after pressing the space bar
            while 1
                [keyIsDown, ~, keyCode ] = KbCheck;
                if keyIsDown 
                    if isequal(KbName(keyCode), Exp.addParams.responseKey)
                        break;
                    end 
                end
                WaitSecs(0.2);
            end
                
            WaitSecs(0.5);
            
        end
        
        % Trigger the beginning of the block
        if Exp.SFM.trackEye
            runEnd = iViewX('message', Exp.ivx, ['END_RUN_' num2str(rn)]);
        end
        
        
        % TAKE A PAUSE IN BETWEEN RUNS
        Screen('FillRect',  Exp.Cfg.win, Exp.Cfg.Color.black);
        message = ['End of Run ' num2str(rn) 'of ' num2str(rn) ', take a pause.'];
        Screen(Exp.Cfg.win, 'DrawText', message, Exp.Cfg.centerX - 300, Exp.Cfg.centerY, Exp.Cfg.Color.white);
        Screen('flip',Exp.Cfg.win);
        if Exp.SFM.trackEye 
            [~, Exp.ivx] = iViewX('closeconnection', Exp.ivx);
        end
        
        
        % Continue only after pressing the space bar
        while 1
            [keyIsDown, ~, keyCode ] = KbCheck;
            if keyIsDown
                if isequal(KbName(keyCode), Exp.addParams.responseKey)
                    break;
                end
            end
            WaitSecs(0.2);
        end
        
        WaitSecs(0.5)
        
        % CALIBRATE EYE TRACKER BEFORE STARTING A NEW RUN
        if rn ~= runs && Exp.SFM.trackEye
%             [~, Exp.ivx] = iViewX('continuerecording', Exp.ivx);
            
%             [~, Exp.ivx] = iViewX('startrecording', Exp.ivx);
%             [result, Exp.ivx] = iViewX('receivedata', Exp.ivx)
% 
%             [result, Exp.ivx] = iViewX('checkconnection', Exp.ivx)
            
%             [initstop, Exp.ivx] = iViewX('stoprecording', Exp.ivx);
            
            [~, Exp.ivx] = iViewXCalibration(Exp.ivx);
            % RUN VALIDATION

            [~, Exp.ivx] = iViewXValidation(Exp.ivx);
        end
        
    end  
    
    
    ListenChar(1);
    
    % close all on and off Screens
    Screen('CloseAll');
    
    %% Stop recording & close iView
    if Exp.SFM.trackEye
        fprintf('stop recording...');
        close_iView (Exp.Gral.SubjectName, Exp.ivx); % eyelink('stoprecording');
        fprintf('done.\n');
    end
    
   
    
    % save parameters
    fprintf('saving matlab file...');
    save([ Exp.Gral.SubjectName], 'Exp');
    fprintf('done.\n');
    
    % Show Mouse pointer
    ShowCursor;
    
    
catch ME1
    rethrow(ME1)
end



function [Exp, fileName, ELName, sessionNum] = setPaths(Exp, subjectID)


if  Exp.Cfg.computer.windows == 1
    
    % Add to the path the files to communicate with the eye tracker
%     addpath('..\iViewXNao\');
%     addpath('\aux_files\');
    
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
    
elseif Exp.Cfg.computer.linux == 1 || Exp.Cfg.computer.osx == 1
    
    % Add to the path the files to communicate with the eye tracker
%     addpath('../iViewXNao/');
%     addpath('/aux_files/');
    
    
    if ~exist(sprintf('../dataRaw/%s/',subjectID));
        mkdir(sprintf('../dataRaw/%s/',subjectID));
    end
    % filename
    sessionNum = 1;
    while exist(sprintf('../dataRaw/%s/conf1C_%s%3.3d.mat',subjectID,subjectID,sessionNum));
        sessionNum = sessionNum+1;
    end
    
    fileName = sprintf('../dataRaw/%s/conf1C_%s%3.3d.mat',subjectID,subjectID,sessionNum);
    ELName   = sprintf('%s%3.3d.edf',subjectID,sessionNum);
end



