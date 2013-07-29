function analysis_eyeData


%% Put together the behavioral data for each subject across runs
%% Save data into file 'Subj_all_eye_beh'


%% Loop across subjects and gather all data across subjects
%% Save data in AllSubjs_eye_beh

%% Analyze and plot behavioral and eye data

try
    
    %% Load data
    
    % Loop through subjects
    data_dir = '../../dataRaw/final/Young/';
    figs_dir = '../../figures/';
    
    % Here we define all subjects that we are going to analyze
    subjects = {'A' 'D' 'E' 'G' 'H' 'I' 'J' 'L' 'N' 'P' 'Q' 'R' 'T'};
    
    putDataTogether = 0;
    plotRawXY = 0;
    plot_XAlone = 1;
    
    
    %% Put all data together
    %  Loop through subjects
    if putDataTogether
        
        % Get runs together for each and all subject
%         getRunsTogether;
        
        for su = 1 : length(subjects)
            
            % Load each subject once at a time,if you don't specify any return
            % variable to load you'll just get 'Exp' on the workspace
            load ( [data_dir subjects{su} '_allruns_eye_beh']);
            
            % Add all the info about eye position for each trial: raw data, saccades, fix and
            % blinks into Run
            
          
            for rn = 1: length(Runs)
                
                aux = [];
                aux_filt = [];
                aux_resp = [];
                aux_resp_filt = [];
                
                % Just for code clarity and to keep the consistency with
                % the previous version of the code
                blinks = Runs(rn).blinks; 
                fixations = Runs(rn).fixations; 
                saccades = Runs(rn).saccades;
                samps = all_samps{rn};
                
                for bk = 1: length(Runs(rn).block)
                    
                    
                    Runs(rn).block(bk).blinks = []; 
                    Runs(rn).block(bk).fixations = []; % % I need this as I appended this variable previously to the file on disk
                    Runs(rn).block(bk).saccades = []; 
                    
                    Runs(rn).block(bk).filtEyeData = []; 
                    Runs(rn).block(bk).response_500hz = [];                    
                    Runs(rn).block(bk).response_filt_500hz = [];   
                    Runs(rn).block(bk).response_times_500hz = [];                      
                    
                    
                    for tr = 1 : size(Runs(rn).block(bk).trial_evTimes, 1)
                        
                        % Filter raw signal for each trial
                        tr_times = Runs(rn).block(bk).trial_evTimes(tr, :);
                        rawData = samps(samps(:,1) >= tr_times(1) & samps(:,1) <= tr_times(2), :); 
                        
                        
                        % Resample behavioral responses to match the sample
                        % rate of the eye data (there are some minor discrepancies)
                        order = 0;
                        eye_sampleRate = 500;
                        response_sampleRate = 60;
                        response_500hz = resample(Runs(rn).block(bk).response(tr, :), ...
                            eye_sampleRate, response_sampleRate, order)'; 
                        response_filt_500hz = response_500hz;
                        
                        % Match the length of the response vector with the eye
                        % data vector
                        eyeLength = length(rawData);
                        respLength = length(response_500hz);
                        if respLength < eyeLength
                            % adjust eye data
                            rawData = rawData(1 : respLength, :);
                        elseif respLength > eyeLength
                            %adjust response data
                            response_500hz = response_500hz(1 : length(rawData)); 
                        end
                                             
                        
                        % Collect eye events                       
                        Runs(rn).block(bk).blinks{tr} = blinks(blinks(:,2) >= tr_times(1) & blinks(:,2) <= tr_times(2), :); %#ok
                        Runs(rn).block(bk).fixations{tr} = fixations(fixations(:,2) >= tr_times(1) & fixations(:,3) <= tr_times(2), :); %#ok
                        Runs(rn).block(bk).saccades{tr} = saccades(saccades(:,2) >= tr_times(1) & saccades(:,3) <= tr_times(2), :); %#ok
                        
                        % Filter the blinks and saccades from the data in each trial
                        filtEyeData = rawData;
                        response_times_500hz = (1: length(response_500hz) ) / 500;
                        evs2filt = cat(1, Runs(rn).block(bk).blinks{tr}(:,2:3), Runs(rn).block(bk).saccades{tr}(:,2:3) );
                        allIdxs = [];
                        
                        for ev = 1 : size(evs2filt, 1)
                            % I need the idxs to match with the response vector
                            idxs = find( filtEyeData(:,1) >= evs2filt(ev, 1) & filtEyeData(:,1) <= evs2filt(ev, 2));
                            allIdxs = cat(1, allIdxs, idxs);
                            
                            % Select data, find final point of the event and
                            % take the remaining of the signal to that baseline
                            idxs1 = find( filtEyeData(:,1) >= evs2filt(ev, 1), 1, 'first') - 1 ;
                            if idxs1 == 0, idxs1 = 1; end;
                            idxs2 = find( filtEyeData(:,1) >= evs2filt(ev, 2), 1, 'first')  ;
                            
                            % Here I eliminate the blinks and saccades form
                            % the signal for each trial
                            
                            % Time L_Dia_X	L_Dia_Y R_Dia_X  R_Dia_Y L_POR_X  L_POR_Y  R_POR_X R_POR_Y [all in pixels]
                            if sign( filtEyeData(idxs2, 6) - filtEyeData(idxs1, 6)) == 1
                                % Move all remaining signal to the left
                                difference = filtEyeData(idxs2, 6) - filtEyeData(idxs1, 6);
                                filtEyeData(idxs2:end, 6) = filtEyeData(idxs2:end, 6) - difference;
                                % Eliminate the chunk of event
                                filtEyeData = cat(1, filtEyeData(1:idxs1, :), filtEyeData(idxs2:end, :));
                                response_filt_500hz = cat(1, response_filt_500hz(1:idxs1, :), response_filt_500hz(idxs2:end, :));
                                
                            elseif sign( filtEyeData(idxs2, 6) - filtEyeData(idxs1, 6)) == -1
                                % Move all remaining signal to the right
                                difference = filtEyeData(idxs2, 6) - filtEyeData(idxs1, 6);
                                filtEyeData(idxs2:end, 6) = filtEyeData(idxs2:end, 6) + difference;
                                % Eliminate the chunk of event
                                filtEyeData = cat(1, filtEyeData(1:idxs1, :), filtEyeData(idxs2:end, :));
                                response_filt_500hz = cat(1, response_filt_500hz(1:idxs1, :), response_filt_500hz(idxs2:end, :));
                                
                            else
                                % This is the improbable case of a blink that retains position 
                                % Eliminate the chunk of event
                                filtEyeData = cat(1, filtEyeData(1:idxs1, :), filtEyeData(idxs2:end, :));
                                response_filt_500hz = cat(1, response_filt_500hz(1:idxs1, :), response_filt_500hz(idxs2:end, :));
                            end
                            
                        end
                       
                        % Sanity check: both eye data and responses must be
                        % the same size
                        if length(filtEyeData) ~= length(response_filt_500hz)
                            msg1= sprintf('Subject: %s, run: %2.0f, block: %2.0f', subjects{su}, rn, bk);
                            disp(msg1)
                            msg = sprintf('The filtered data and the response vector do not coincide')
                            disp(meg)
                        end
                        
                        aux_resp = cat(1, aux_resp, response_500hz);
                        aux_resp_filt = cat(1, aux_resp_filt,  response_filt_500hz);
                        aux = cat(1, aux, rawData);
                        aux_filt = cat(1, aux_filt, filtEyeData);
                        
                        % Save data into Run
                        Runs(rn).block(bk).rawEyeData{tr} = rawData;
                        Runs(rn).block(bk).filtEyeData{tr} = filtEyeData; 
                        Runs(rn).block(bk).response_500hz{tr} = response_500hz; 
                        Runs(rn).block(bk).response_filt_500hz{tr} = response_filt_500hz;
                        Runs(rn).block(bk).response_times_500hz{tr} = response_times_500hz';
                        Runs(rn).block(bk).response_times_500hz_filt{tr} = ( (1: length(response_filt_500hz) ) / 500 )';
                    end
                    
                end
                
%                 % Keep data from all block together
%                 Runs(rn).rawEyeDataCat = aux; %#ok % eye raw data for the whole block
%                 Runs(rn).filtEyeDataCat = aux_filt; %#ok % eye filtered data for the whole block
%                 Runs(rn).response_500hzCat = aux_resp; %#ok % responses at 500hz for the whole block
%                 Runs(rn).response_filt_500hzCat = aux_resp_filt; %#ok % filtered responses at 500hz for the whole block
            end
            
            % Save
            save([data_dir subjects{su} '_allruns_eye_beh_filt_resamp'], 'Exp','Runs', 'blinks', 'saccades', 'fixations')
            msg = sprintf('Done with Subject %s', subjects{su});
            disp(msg)
            
        end
        
        
    end
    
    
    %% plot x & y raw data across runs / blocks
    if plotRawXY
        for su = 1 : length(subjects)
            
            load ( [data_dir subjects{su} '_allruns_eye_beh_filt_resamp']);
            
            
            for rn = 1: length(Run)
                
                z = figure(1);
                set(gcf, 'Position', [0 0 1800 300], 'PaperPositionMode', 'auto', 'InvertHardcopy', 'off')
                
                for bk = 1: length(Runs(rn).block)
                    
                    % Avoid the zeros (blinks, loss of signal) in the data
                    % idxs = find (Runs(rn).block(bk).rawEyeDataCat(:,6) ~= 0 & Runs(rn).block(bk).rawEyeDataCat(:,7) ~= 0);
                    % y = Runs(rn).block(bk).rawEyeDataCat(idxs, 7);
                    
                    filtEyeDataCat = Runs(rn).block(bk).filtEyeDataCat;
                    xy = filtEyeDataCat(filtEyeDataCat(:,6) ~= 0 & filtEyeDataCat(:,7) ~= 0, 6:7);
                    
                    
                    % xy = Runs(rn).block(bk).rawEyeDataCat(Runs(rn).block(bk).rawEyeDataCat(:,6) ~= 0 & Runs(rn).block(bk).rawEyeDataCat(:,7) ~= 0, 6:7);
                    
                    subplot(1,length(Runs(rn).block), bk)
                    plot(xy(:,1), xy(:,2), 'r--')
                    set(gca,'xLim', [1 Exp.Cfg.width], 'yLim', [1 Exp.Cfg.height])
                    xlabel('X Pos [pixels]', 'FontSize', 16, 'FontWeight', 'bold')
                    ylabel('Y Pos [pixels]', 'FontSize', 16, 'FontWeight', 'bold')
                    tit = sprintf('Subject: %s, Run: %d, Blocks: %s', Exp.Gral.SubjectName, rn, Runs(rn).block(bk).id );
                    title(tit)
                    
                end
                
                figName = sprintf('%s_RawData_XY_Run_%d_Blocks_%s', Exp.Gral.SubjectName, rn, Runs(rn).block(bk).id );
                print(z, '-dtiff', '-loose', [figs_dir figName ])
            end
            
        end
    end
    close all
    
    %% Single trial plots (good and bad one)    
    % figure
    % plot(x, y, 'r--')
    % set(gca,'xLim', [1 Exp.Cfg.width], 'yLim', [1 Exp.Cfg.height])
     if plot_XAlone
         
        filtData = 1;
%         conds = {'4-3'    '60-0'    '2-3'    '0.5-3'    '1-1'    '2-1'    '1-3'    '4-1'    '0.5-1'}
        conds = {'60-0'};
        
        % CONCATENATE ALL BLOCKS TOGETHER FOR PLOTTING
         for su = 1 : length(subjects)
            
            load ( [data_dir subjects{su} '_allruns_eye_beh_filt_resamp']);
            all_blks = []
            all_resp = []
                  count = 1;      
            for rn = 1: length(Runs)
                
                for bk = 1: length(Runs(rn).block)
                    
                    if strcmpi(Runs(rn).block(bk).id, conds{1}) 
                        
                        
                        % Add trials here
                        for tr = 1 : size(Runs(rn).block(bk).trial_evTimes, 1)
                            all_filtEyeData{rn,1} = Runs(rn).block(bk).filtEyeData{tr}
                            all_resp{rn, 1} = Runs(rn).block(bk).response_filt_500hz{tr}
                        end
                    
                    end
                end
            end
         end
    
     end
    
    
    
        
    %% plot X data alone to show OKN patterns
    if plot_XAlone
        
        filtData = 1;
        conds = {'4-3'    '60-0'    '2-3'    '0.5-3'    '1-1'    '2-1'    '1-3'    '4-1'    '0.5-1'};
        
        for su = 1 : length(subjects)
            
            load ( [data_dir subjects{su} '_allruns_eye_beh_filt_resamp']);
            
            for rn = 1: length(Runs)
                
                z = figure(1);
                set(gcf, 'Position', [0 0 1800 300], 'PaperPositionMode', 'auto', 'InvertHardcopy', 'off')
                hold on
%                 time_bk = [];
%                 allBks_xy = [];
%                 allresp = [];
                
                if filtData
                    xy = Runs(rn).filtEyeDataCat(:, 6:7);
                    allresp = Runs(rn).response_filt_500hzCat;
                else
                    xy = Runs(rn).rawEyeDataCat(:, 6:7);
                    allresp = Runs(rn).response_500hzCat;
                end
                
                time_bk =  ( 1 : size(xy,1) ) / 500;
                
                
%                 for bk = 1: length(Runs(rn).block)
                    
%                     % Avoid the zeros (blinks, loss of signal) in the data
%                     if filtData
%                         data = Runs(rn).block(bk).filtEyeDataCat;
%                         %                         filtEyeDataCat = Runs(rn).block(bk).filtEyeDataCat;
%                         %                         idxs= find(filtEyeDataCat(:,6) ~= 0 & filtEyeDataCat(:,7) ~= 0);
%                         %                         xy = filtEyeDataCat(idxs, 6:7);
%                         %                         resp = Runs(rn).block(bk).response_filt_500hz(idxs);
%                         resp = Runs(rn).block(bk).response_filt_500hzCat;
%                         
%                     else
%                         data = Runs(rn).block(bk).rawEyeDataCat;
%                         %                         rawEyeDataCat = Runs(rn).block(bk).rawEyeDataCat;
%                         %                         idxs = find(rawEyeDataCat(:,6) ~= 0 & rawEyeDataCat(:,7) ~= 0);
%                         %                         xy = rawEyeDataCat(idxs, 6:7);
%                         %                         resp = Runs(rn).block(bk).response_500hz{1}(idxs); % CHECK THIS
%                         resp = Runs(rn).block(bk).response_500hzCat;
%                     end
%                     %                     filtEyeDataCat = Runs(rn).block(bk).filtEyeDataCat;
%                     
%                     xy = data(:, 6:7);
                    
%                     % Calculate the time for the whole block
%                     if bk == 1
%                         time_bk =  ( 1 : size(xy,1) ) / 500;
%                     else
%                         next_times = ( size(time_bk, 2) + 1 : size(time_bk, 2)  + size(xy,1) ) ./ 500;
%                         time_bk = cat(2, time_bk, next_times);
%                     end
%                     bk_end(bk) = time_bk(end); %#ok
% %                     allBks_xy = cat(1, allBks_xy, xy);
%                     allresp = cat(1, allresp, resp);
%                 end
                
%                 if su == 2 && rn ==2
%                     disp('yes')
%                 end

                idxs = ~isnan(allresp);
                xx = unique(allresp(idxs));
                if length(xx) > 2
                    disp(['Stopped at ' num2str(rn)])
                    return
                end
                
                % plot eye data
                plot(time_bk, xy(:,1), 'r-')
                
                % Plot behavioral responses
                allresp(allresp > 5 ) = 300; % right
                allresp(allresp == 0) = 300;
                allresp(allresp < 5 ) = 100; % left
                plot(time_bk, allresp, 'g.')
                
                set(gca,'yLim', [1 Exp.Cfg.height])
                xlabel('Time [secs]', 'FontSize', 22, 'FontWeight', 'bold')
                ylabel('X Pos [pixels]', 'FontSize', 22, 'FontWeight', 'bold')
                tit = sprintf('Subject: %s, Run: %d, Blocks: %s', Exp.Gral.SubjectName, rn, Runs(rn).block(1).id );
                title(tit, 'FontSize', 28, 'FontWeight', 'bold')
                % draw end of block lines
%                 line([ bk_end; bk_end], [1 1 1 1 1; repmat(Exp.Cfg.height, 1,length(bk_end))], 'LineWidth', 2, 'Color', 'b')
                
                if filtData
                    figName = sprintf('%s_XfiltData_Alone_Run_%d_Blocks_%s', Exp.Gral.SubjectName, rn, Runs(rn).block(1).id );
                else
                    figName = sprintf('%s_XrawData_Alone_Run_%d_Blocks_%s', Exp.Gral.SubjectName, rn, Runs(rn).block(1).id );
                end
                print(z, '-dtiff', '-loose', [figs_dir figName ])
                close(z)
            end
            
        end
        
        close all
    end
    
    
catch ME1
    rethrow(ME1)
end


%% notes


% Check all responses

% Cut and "align" epoch from previous fixations


%% Function definitions

function getRunsTogether

%% Put together the behavioral data for each subject across runs
%% Save data into file 'Subj_all_eye_beh'

data_dir = '../../dataRaw/final/Young/';

subjects = {'A' 'C' 'D' 'E' 'G' 'H' 'I' 'J' 'L' 'N' 'P' 'Q' 'R' 'T'};
subj_runs = 1:5; % {'C1' 'C2_eye_beh' 'C3_eye_beh' 'C4_eye_beh' 'C5_eye_beh'};


for su = 1 : length(subjects)
    
    Runs = [];
    
    sprintf('Subject: %s', subjects{su})
    for su_rn = subj_runs
        
        % Load each subject once at a time,if you don't specify any return
        % variable to 'load' you'll just get 'Exp' on the workspace
        load ( [data_dir subjects{su} num2str(su_rn) '_eye_beh' ]);
        
        % Keep everything inside Runs, even the raw data
        all_samps{su_rn} = samps;
        
        Runs = cat(1,Runs,Run);        
        
    end
    
    save([data_dir subjects{su} '_allruns_eye_beh'], 'Runs', 'all_samps', 'Exp')
    disp(Runs)
    clear all_samps Runs
end







