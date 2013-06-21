function analysis_eyeData

% Analyze and plot behavioral and eye data

try
    
    %% Load data
    
    % Loop through subjects
    data_dir = '../../dataRaw/';
    figs_dir = '../../figures/';
    
    % Here we define all subjects that we are going to analyze
    subjects = {'MO' 'NS' 'TF'}; %
    
    putDataTogether = 1;
    plotRawXY = 0;
    plot_XAlone = 1;
    
    
    %% Put all data together
    %  Loop through subjectsF in XrawDataAlone has many blocks without response
    if putDataTogether
        
        for su = 1 : length(subjects)
            
            % Load each subject once at a time,if you don't specify any return
            % variable to 'loafigured' you'll just get 'Exp' on the workspace
            load ( [data_dir subjects{su} '_eye_beh']);
            
            % Add all the info about eye position for each trial: raw data, saccades, fix and
            % blinks into Run
            
            for rn = 1: length(Run)
                
                aux = [];
                aux_filt = [];
                aux_resp = [];
                aux_resp_filt = [];
                
                for bk = 1: length(Run(rn).block)
                    
                    
                    Run(rn).block(bk).blinks = []; %#ok
                    Run(rn).block(bk).fixations = []; %#ok % I need this as I appended this variable previously to the file on disk
                    Run(rn).block(bk).saccades = []; %#ok
                    
                    Run(rn).block(bk).filtEyeData = []; %#ok
                    Run(rn).block(bk).response_500hz = []; %#ok                   
                    Run(rn).block(bk).response_filt_500hz = [];
                    Run(rn).block(bk).response_times_500hz = [];                    
                    
%                     Run(rn).block(bk).rawEyeDataCat = [];
%                     Run(rn).block(bk).filtEyeDataCat = [];
%                     Run(rn).block(bk).response_500hzCat = [];
%                     Run(rn).block(bk).response_filt_500hzCat = []; %#ok
                    
                    for tr = 1 : size(Run(rn).block(bk).nTrials, 1)
                        
                        % Filter raw signal for each trial
                        tr_times = Run(rn).block(bk).trial_evTimes(tr, :);
                        rawData = samps(samps(:,1) >= tr_times(1) & samps(:,1) <= tr_times(2), :); %#ok
                        
                        
                        % Resample behavioral responses to match the sample
                        % rate of the eye data (there are some minor discrepancies)
                        order = 0;
                        eye_sampleRate = 500;
                        response_sampleRate = 60;
                        response_500hz = resample(Run(rn).block(bk).response(tr, :), ...
                            eye_sampleRate, response_sampleRate, order)'; %#ok
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
                            response_500hz = response_500hz(1 : length(rawData)); %#ok
                        end
                        
                      
                        
                        % Collect eye events
                        Run(rn).block(bk).blinks{tr} = blinks(blinks(:,2) >= tr_times(1) & blinks(:,2) <= tr_times(2), :); %#ok
                        Run(rn).block(bk).fixations{tr} = fixations(fixations(:,2) >= tr_times(1) & fixations(:,3) <= tr_times(2), :); %#ok
                        Run(rn).block(bk).saccades{tr} = saccades(saccades(:,2) >= tr_times(1) & saccades(:,3) <= tr_times(2), :); %#ok
                        
                        % Filter the blinks and saccades from the data in each trial
                        filtEyeData = rawData;
                        response_times_500hz = (1: length(response_500hz) ) / 500;
                        evs2filt = cat(1, Run(rn).block(bk).blinks{tr}(:,2:3), Run(rn).block(bk).saccades{tr}(:,2:3) );
                        allIdxs = [];
                        for ev = 1 : size(evs2filt, 1)
                            % I need the idxs to match with the response vector
                            idxs = find( filtEyeData(:,1) >= evs2filt(ev, 1) & filtEyeData(:,1) <= evs2filt(ev, 2));
                            allIdxs = cat(1, allIdxs, idxs);
                            
                            % Select data, find final point of the event and
                            % take the remaining of the signal to that baseline
                            idxs1 = find( filtEyeData(:,1) >= evs2filt(ev, 1), 1, 'first') - 1 ;
                            idxs2 = find( filtEyeData(:,1) >= evs2filt(ev, 2), 1, 'first')  ;
                            
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
                        
                        
%                         filtEyeData(allIdxs, :) = [];
%                         response_filt_500hz = response_500hz;  %#ok
%                         response_filt_500hz(allIdxs, :) = [];  %#ok
                        
                        
                        aux_resp = cat(1, aux_resp, response_500hz);
                        aux_resp_filt = cat(1, aux_resp_filt,  response_filt_500hz);
                        aux = cat(1, aux, rawData);
                        aux_filt = cat(1, aux_filt, filtEyeData);
                        
                        % Save data into Run
                        Run(rn).block(bk).rawEyeData{tr} = rawData;%#ok
                        Run(rn).block(bk).filtEyeData{tr} = filtEyeData; %#ok
                        Run(rn).block(bk).response_500hz{tr} = response_500hz; %#ok
                        Run(rn).block(bk).response_filt_500hz{tr} = response_filt_500hz;%#ok
                        Run(rn).block(bk).response_times_500hz{tr} = response_times_500hz';%#ok
                    end
                    
                end
                
                % Keep data from all block together
                Run(rn).rawEyeDataCat = aux; %#ok % eye raw data for the whole block
                Run(rn).filtEyeDataCat = aux_filt; %#ok % eye filtered data for the whole block
                Run(rn).response_500hzCat = aux_resp; %#ok % responses at 500hz for the whole block
                Run(rn).response_filt_500hzCat = aux_resp_filt; %#ok % filtered responses at 500hz for the whole block
            end
            
            % Save
            save([data_dir subjects{su} '_eye_beh_2'], 'Exp','Run', 'blinks', 'saccades', 'fixations')
        end
    end
    
    
    %% plot x & y raw data across runs / blocks
    if plotRawXY
        for su = 1 : length(subjects)
            
            load ( [data_dir subjects{su} '_eye_beh_2']);
            
            
            for rn = 1: length(Run)
                
                z = figure(1);
                set(gcf, 'Position', [0 0 1800 300], 'PaperPositionMode', 'auto', 'InvertHardcopy', 'off')
                
                for bk = 1: length(Run(rn).block)
                    
                    % Avoid the zeros (blinks, loss of signal) in the data
                    % idxs = find (Run(rn).block(bk).rawEyeDataCat(:,6) ~= 0 & Run(rn).block(bk).rawEyeDataCat(:,7) ~= 0);
                    % y = Run(rn).block(bk).rawEyeDataCat(idxs, 7);
                    
                    filtEyeDataCat = Run(rn).block(bk).filtEyeDataCat;
                    xy = filtEyeDataCat(filtEyeDataCat(:,6) ~= 0 & filtEyeDataCat(:,7) ~= 0, 6:7);
                    
                    
                    %                 xy = Run(rn).block(bk).rawEyeDataCat(Run(rn).block(bk).rawEyeDataCat(:,6) ~= 0 & Run(rn).block(bk).rawEyeDataCat(:,7) ~= 0, 6:7);
                    
                    subplot(1,length(Run(rn).block), bk)
                    plot(xy(:,1), xy(:,2), 'r--')
                    set(gca,'xLim', [1 Exp.Cfg.width], 'yLim', [1 Exp.Cfg.height])
                    xlabel('X Pos [pixels]', 'FontSize', 16, 'FontWeight', 'bold')
                    ylabel('Y Pos [pixels]', 'FontSize', 16, 'FontWeight', 'bold')
                    tit = sprintf('Subject: %s, Run: %d, Blocks: %s', Exp.Gral.SubjectName, rn, Run(rn).block(bk).id );
                    title(tit)
                    
                end
                
                figName = sprintf('%s_RawData_XY_Run_%d_Blocks_%s', Exp.Gral.SubjectName, rn, Run(rn).block(bk).id );
                print(z, '-dtiff', '-loose', [figs_dir figName ])
            end
            
        end
    end
    close all
    
    %% Single trial plots (good and bad one)    
    % figure
    % plot(x, y, 'r--')
    % set(gca,'xLim', [1 Exp.Cfg.width], 'yLim', [1 Exp.Cfg.height])
        
    %% plot X data alone to show OKN patterns
    if plot_XAlone
        
        filtData = 1;
        
        for su = 1 : length(subjects)
            
            load ( [data_dir subjects{su} '_eye_beh_2']);
            
            for rn = 1: length(Run)
                
                z = figure(1);
                set(gcf, 'Position', [0 0 1800 300], 'PaperPositionMode', 'auto', 'InvertHardcopy', 'off')
                hold on
%                 time_bk = [];
%                 allBks_xy = [];
%                 allresp = [];
                
                if filtData
                    xy = Run(rn).filtEyeDataCat(:, 6:7);
                    allresp = Run(rn).response_filt_500hzCat;
                else
                    xy = Run(rn).rawEyeDataCat(:, 6:7);
                    allresp = Run(rn).response_500hzCat;
                end
                
                time_bk =  ( 1 : size(xy,1) ) / 500;
                
                
%                 for bk = 1: length(Run(rn).block)
                    
%                     % Avoid the zeros (blinks, loss of signal) in the data
%                     if filtData
%                         data = Run(rn).block(bk).filtEyeDataCat;
%                         %                         filtEyeDataCat = Run(rn).block(bk).filtEyeDataCat;
%                         %                         idxs= find(filtEyeDataCat(:,6) ~= 0 & filtEyeDataCat(:,7) ~= 0);
%                         %                         xy = filtEyeDataCat(idxs, 6:7);
%                         %                         resp = Run(rn).block(bk).response_filt_500hz(idxs);
%                         resp = Run(rn).block(bk).response_filt_500hzCat;
%                         
%                     else
%                         data = Run(rn).block(bk).rawEyeDataCat;
%                         %                         rawEyeDataCat = Run(rn).block(bk).rawEyeDataCat;
%                         %                         idxs = find(rawEyeDataCat(:,6) ~= 0 & rawEyeDataCat(:,7) ~= 0);
%                         %                         xy = rawEyeDataCat(idxs, 6:7);
%                         %                         resp = Run(rn).block(bk).response_500hz{1}(idxs); % CHECK THIS
%                         resp = Run(rn).block(bk).response_500hzCat;
%                     end
%                     %                     filtEyeDataCat = Run(rn).block(bk).filtEyeDataCat;
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
                tit = sprintf('Subject: %s, Run: %d, Blocks: %s', Exp.Gral.SubjectName, rn, Run(rn).block(1).id );
                title(tit, 'FontSize', 28, 'FontWeight', 'bold')
                % draw end of block lines
%                 line([ bk_end; bk_end], [1 1 1 1 1; repmat(Exp.Cfg.height, 1,length(bk_end))], 'LineWidth', 2, 'Color', 'b')
                
                if filtData
                    figName = sprintf('%s_XfiltData_Alone_Run_%d_Blocks_%s', Exp.Gral.SubjectName, rn, Run(rn).block(1).id );
                else
                    figName = sprintf('%s_XrawData_Alone_Run_%d_Blocks_%s', Exp.Gral.SubjectName, rn, Run(rn).block(1).id );
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


%% Function definitions

% Check all responses
% TF in XrawDataAlone has many blocks without response

% Cut and "align" epoch from previous fixations








