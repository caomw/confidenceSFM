function analysis_eyeData

% Analyze and plot behavioral and eye data


%% Load data

% Loop through subjects
data_dir = '../../dataRaw/';
figs_dir = '../../figures/';

% Here we define all subjects that we are going to analyze
subjects = {'MO' 'NS' 'TF'};

putDataTogether = 0;
plotRaxXY = 0;

%% Put all data together
% Loop through subjects
if putDataTogether
    
    for su = 1 : length(subjects)
        
        % Load each subject once at a time,if you don't specify any return
        % variable to 'loafigured' you'll just get 'Exp' on the workspace
        load ( [data_dir subjects{su} '_eye_beh']);
        
        % Add all the info about eye position for each trial: raw data, saccades, fix and
        % blinks into Run
        
        for rn = 1: length(Run)
            for bk = 1: length(Run(rn).block)
                aux = [];
                for tr = 1figure : size(Run(rn).block(bk).trial_evTimes, 1)
                    
                    % raw signal
                    tr_times = Run(rn).block(bk).trial_evTimes(tr, :);
                    rawData = samps(samps(:,1) >= tr_times(1) & samps(:,1) <= tr_times(2), :); %#ok
                    Run(rn).block(bk).rawEyeData{1, tr} = rawData; %#ok
                    aux = cat(1, aux, rawData);
                    % eye events
                    Run(rn).block(bk).blinks = blinks(blinks(:,2) >= tr_times(1) & blinks(:,2) <= tr_times(2), :); %#ok
                    Run(rn).block(bk).fixations = fixations(fixations(:,2) >= tr_times(1) & fixations(:,3) <= tr_times(2), :); %#ok
                    Run(rn).block(bk).saccades = saccades(saccades(:,2) >= tr_times(1) & saccades(:,3) <= tr_times(2), :); %#ok
                    
                end
                Run(rn).block(bk).rawEyeDataCat = aux; %#ok
            end
            
        end
        
        % Save
        save([data_dir subjects{su} '_eye_beh'], 'Run', '-append');
    end
end

%% plot x & y raw data across runs / blocks
if plotRaxXY
    for su = 1 : length(subjects)
        
        load ( [data_dir subjects{su} '_eye_beh']);
        
        
        for rn = 1: length(Run) %#ok
            
            z = figure(1);
            set(gcf, 'Position', [0 0 1800 300], 'PaperPositionMode', 'auto', 'InvertHardcopy', 'off')
            
            for bk = 1: length(Run(rn).block)
                
                % Avoid the zeros (blinks, loss of signal) in the data
                % idxs = find (Run(rn).block(bk).rawEyeDataCat(:,6) ~= 0 & Run(rn).block(bk).rawEyeDataCat(:,7) ~= 0);
                % y = Run(rn).block(bk).rawEyeDataCat(idxs, 7);
                
                xy = Run(rn).block(bk).rawEyeDataCat(Run(rn).block(bk).rawEyeDataCat(:,6) ~= 0 & Run(rn).block(bk).rawEyeDataCat(:,7) ~= 0, 6:7);
                
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
%% Single trial plots (good and bad one)
%
% tr = 2;
% x = Run(rn).block(bk).rawEyeData{tr}(:,6);
% y = Run(rn).block(bk).rawEyeData{tr}(:,7);
% figure
% plot(x, y, 'r--')
% set(gca,'xLim', [1 Exp.Cfg.width], 'yLim', [1 Exp.Cfg.height])


%% plot X data alone to show OKN patterns
%
% tms = (1:120) ./ 60;
x = round(rand(1,120));
y = interp(x, 8)
% Y = resample(X,500,120)
% xi = (1:1000) ./ 500;
% yi = interp1(tms,y,xi);

for su = 1 : length(subjects)
    
    load ( [data_dir subjects{su} '_eye_beh']);
    
    for rn = 1: length(Run) %#ok
        
        z = figure(1);
        set(gcf, 'Position', [0 0 1800 300], 'PaperPositionMode', 'auto', 'InvertHardcopy', 'off')
        time_bk = [];
        allBks_xy = [];
        for bk = 1: length(Run(rn).block)
            
            % Avoid the zeros (blinks, loss of signal) in the data
            xy = Run(rn).block(bk).rawEyeDataCat(Run(rn).block(bk).rawEyeDataCat(:,6) ~= 0 & Run(rn).block(bk).rawEyeDataCat(:,7) ~= 0, 6:7);
            
            if bk == 1
                time_bk =  ( 1 : size(xy,1) ) / 500;
            else
                
                next_times = ( size(time_bk, 2) + 1 : size(time_bk, 2)  + size(xy,1) ) ./ 500;
                time_bk = cat(2, time_bk, next_times);
            end
            bk_end(bk) = time_bk(end); %#ok
            
            allBks_xy = cat(1, allBks_xy, xy);
            
        end
        
        plot(time_bk, allBks_xy(:,1), 'r-')
        set(gca,'yLim', [1 Exp.Cfg.height])
        xlabel('Time [secs]', 'FontSize', 22, 'FontWeight', 'bold')
        ylabel('X Pos [pixels]', 'FontSize', 22, 'FontWeight', 'bold')
        tit = sprintf('Subject: %s, Run: %d, Blocks: %s', Exp.Gral.SubjectName, rn, Run(rn).block(bk).id );
        title(tit, 'FontSize', 28, 'FontWeight', 'bold')        
        
        figName = sprintf('%s_XData_Alone_Run_%d_Blocks_%s', Exp.Gral.SubjectName, rn, Run(rn).block(bk).id );
        print(z, '-dtiff', '-loose', [figs_dir figName ])
        
    end
    
end

close all













