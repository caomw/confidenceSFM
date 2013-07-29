function analysis_collect_eyeData


%% Single subject preproces: Collect behavioral data and eye data for each run / subject.
%% Data is saved into 'Run' structure subjects

dbstop if error


% Loop through subjects
data_dir = '../../dataRaw/final/Young/';

% subjects = {'A' 'B' 'C' 'D' 'E' 'G' 'H' 'I' 'J' 'L' 'N' 'P' 'Q' 'R' 'T'};
subjects = {'B'};
% Here we define all subjects that we are going to analyze
subj_runs = 1:5; % 'B' 'C' 'D' 'E' 'G' 'H' 'I' 'J'};
% subj_runs = {'B1' 'B2' 'B3' 'B4' 'B5' }; %'B2' 'B3' 'B4' 'B5'

for subj = 1 : length(subjects)
    
    % Loop through subj_runs
    for su = subj_runs
        
        % Load each subject once at a time,if you don't specify any return
        % variable to 'load' you'll just get 'Exp' on the workspace
        load ( [data_dir  subjects{subj}  num2str(su) ]);
        
        % Load eye event times
        % OPEN FILE
        fid_evs = fopen([data_dir  subjects{subj} num2str(su) 'Events.txt']);
        
        % Collect data from each trial
        for rn = 1: length(Exp.Run)
            for bk = 1: length(Exp.Run(rn).block)
                
                % BEHAVIOR
                Run(rn).block(bk).id =  Exp.Run(rn).block(bk).id; %#ok
                Run(rn).block(bk).idx = Exp.rnd_idxs(rn); %#ok
                Run(rn).block(bk).nTrials =  Exp.Run(rn).block(bk).nTrials; %#ok
                Run(rn).block(bk).stimFrames =  Exp.Run(rn).block(bk).stimFrames; %#ok
                Run(rn).block(bk).interStimInterval =  Exp.Run(rn).block(bk).interStimInterval; %#ok
                Run(rn).block(bk).response = Exp.Run(rn).block(bk).respType; %#ok
                Run(rn).block(bk).response_times = (1: Exp.Run(rn).block(bk).stimFrames) / 60; %#ok % In Secs
                % Preallocate memory for later analysis
                Run(rn).block(bk).rawEyeData = []; %#ok
                Run(rn).block(bk).blinks = []; %#ok
                Run(rn).block(bk).fixations = []; %#ok
                Run(rn).block(bk).saccades = []; %#ok
            end
        end
        
        %% Search for the eye data time events
        
        % Loop through the text file
        run_idx = 0;
        bl_idxs = 1;
        fix_idxs = 1;
        sacc_idxs = 1;
        
        while (1)
            
            % get line by line of text file
            tline = fgetl(fid_evs);
            
            %Check whether we've reached the end of the file
            if ~ischar(tline), sprintf('End of Trials'), break, end;
            %Skip line if it's an empty one.
            if isempty(tline), continue, end;
            
            % Find next corresponding start of each run (they are indexed)
            if ~isempty(strfind(tline, 'UserEvent')) && ~isempty(regexp(tline, 'START_RUN_','once'))
                
                run_idx = run_idx + 1;
                % Check that the run is consistent with the behavioural data
                C= textscan(tline, '%s %n %n %n %s %s %s');
                if strcmpi(C{7}, ['START_RUN_' num2str(Exp.rnd_idxs(run_idx))])
                    disp('Behavioral and eye data match for this run')
                else
                    disp('Behavioral and eye data DO NOT MATCH for this run')
                    keyboard
                end
                bk_idx = 0; % set block index
                % go to next line
                continue;
                
            end
            
            % Find start of block
            if ~isempty(strfind(tline, 'UserEvent')) && ~isempty(regexp(tline, 'START_BK','once'))
                
                bk_idx = bk_idx + 1;
                messg = sprintf('Subject: %s, Run: %d, block: %d',  [ subjects{subj}  num2str(su)], Exp.rnd_idxs(run_idx), bk_idx);
                disp(messg)
                tr_idx = 0; % set trial index
                % go to next line
                continue;
                
            end
            
            % Collect times of trial events
            if ~isempty(strfind(tline, 'UserEvent')) && ~isempty(regexp(tline, 'START_TR','once'))
                
                tr_idx = tr_idx + 1;
                C= textscan(tline, '%s %n %n %n %s %s %s');
                Run(run_idx).block(bk_idx).trial_evTimes(tr_idx, 1) = C{4} / 1000000; %#ok % IN SECS
                continue;
                
            elseif ~isempty(strfind(tline, 'UserEvent')) && ~isempty(regexp(tline, 'END_TR','once'))
                
                C= textscan(tline, '%s %n %n %n %s %s %s');
                Run(run_idx).block(bk_idx).trial_evTimes(tr_idx, 2) = C{4} / 1000000; %#ok
                continue;
            end
            
            % As the events are at the end of the .txt we need to search for them
            % here separately and add them to the structure
            
            if ~isempty(regexp(tline, 'Fixation L','once'))
                
                % Table Header for Fixations:
                % Event Type	Trial	Number	Start	End	Duration	Location X	Location Y	Dispersion X	Dispersion Y	Plane	Avg. Pupil Size X	Avg Pupil Size Y
                C = textscan(tline, '%s %s %n %n %n %n %n %n %n %n %n %n %n %n');
                EventType = 1;
                times_ev = [C{5:7}] ./ 1000000;
                % Event_Type   Start	 End	 Duration	Location X	Location Y
                fixations(fix_idxs, 1:6) = [EventType times_ev C{8} C{9}]; %#ok
                fix_idxs = fix_idxs + 1;
                continue;
            end
            
            if ~isempty(regexp(tline, 'Saccade L','once'))
                
                % Table Header for Saccades:
                % Event_Type	Trial	Number	Start	End	Duration	Start Loc.X	Start Loc.Y	End Loc.X	End Loc.Y	Amplitude	Peak Speed	Peak Speed At	Average Speed	Peak Accel.	Peak Decel.	Average Accel.
                C = textscan(tline, '%s %s %n %n %n %n %n %n %n %n %n %n %n %n %n %n %n %n');
                EventType = 2;
                times_ev = [C{5:7}] ./ 1000000;
                % Event_Type	Start	End	 Duration	Start Loc.X	 Start Loc.Y	End Loc.X	End Loc.Y	Amplitude
                saccades(sacc_idxs, 1:9)= [EventType times_ev C{8:12}]; %#ok
                sacc_idxs = sacc_idxs + 1;
                continue;
            end
            
            if ~isempty(regexp(tline, 'Blink L','once'))
                
                % Table Header for Blinks:
                % Event_Type	Trial	Number	Start	End	Duration
                C = textscan(tline, '%s %s %n %n %n %n %n');
                EventType = 3;
                times_ev = [C{5} C{6} C{7}] ./ 1000000;
                % Event_Type	Start	End 	Duration
                blinks(bl_idxs, 1:4) = [ EventType times_ev]; %#ok
                bl_idxs = bl_idxs + 1;
                continue;
            end
            
            
        end
        
        % Save all data to disk
        % These are all the eye events for the run
        Run.blinks = blinks; Run.saccades = saccades;
        Run.fixations = fixations;
        
        %Sanity check: we corroborate that the triggers are being read
        %correctly
        for m = 1 : length(Run.block)
            if size(Run.block(m).trial_evTimes, 2) ~= 2
                msg = sprintf('Error with trial_evTimes in Subject %2.0f, run %2.0f, block %2.0f', subj, su, m);
                disp(msg)
            end
            
            if  Run.block(m).nTrials ~= size(Run.block(m).trial_evTimes, 1)
                msg = sprintf('Error with num trials in trial_evTimes in Subject %2.0f, run %2.0f, block %2.0f', subj, su, m);
                disp(msg)
%                 KbWait;
%                 keyboard;
            end
        end
        
        save([data_dir   subjects{subj}  num2str(su) '_eye_beh'], 'Exp','Run')
        %     save([data_dir   subjects{subj}  num2str(su) '_eye_beh'], 'Exp','Run', 'blinks', 'saccades', 'fixations')
        
        
        %% Finally, add the continuous data to the structure (this data is on a
        %% separate file
        
        % OPEN FILE
        fid_samps = fopen([data_dir  subjects{subj}  num2str(su) 'Samples.txt']);
        samp_idx = 1;
        samps = nan(1800000,9); % Preallocate to avoid time, then cut the unused parts
        while (1)
            
            % get line by line of text file
            tline = fgetl(fid_samps);
            
            %Check whether we've reached the end of the file
            if ~ischar(tline), sprintf('End of Trials'), break, end;
            %Skip line if it's an empty one.
            if isempty(tline), continue, end;
            
            if ~isempty(regexp(tline, 'SMP','once'))
                
                % Table Header for Sample data:
                % Time	Type	Trial	L Dia X [px]	L Dia Y [px]	R Dia X [px]	R Dia Y [px]	L POR X [px]	L POR Y [px]	R POR X [px]	R POR Y [px]	Aux1
                C = textscan(tline, '%n %s %n %n %n %n %n %n %n %n %n');
                % Time L_Dia_X	L_Dia_Y R_Dia_X  R_Dia_Y L_POR_X  L_POR_Y  R_POR_X R_POR_Y [all in pixels]
                samps(samp_idx, 1:9) = [ (C{1} / 1000000)  C{4:11}];
                samp_idx = samp_idx + 1;
            end
            
            %Show progress
            if mod(samp_idx, 100000) == 0
                messg = sprintf('Processing sample %d', samp_idx);
                disp(messg);
                
            end
        end
        
        idxs = ~isnan(samps(:,1));
        samps = samps(idxs, :); %#ok
        save([data_dir  subjects{subj}  num2str(su) '_eye_beh'], 'samps', '-append');
        
        %%
        fclose('all'); % clean fids
        clear Exp Run blinks saccades fixations samps;
        
    end
    
    
end
