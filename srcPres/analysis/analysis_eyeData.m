function Run = analysis_eyeData

% Collect all behavioral data and eye data into 'Run' structure for all
% subjects

% Loop through subjects
data_dir = '../../dataRaw/';

% Here we define all subjects that we are going to analyze
subjects = {'MO' 'NS' 'TF'};


% Loop through subjects
for su = 1 : length(subjects)
    
    % Load each subject once at a time,if you don't specify any return
    % variable to 'load' you'll just get 'Exp' on the workspace
    load ( [data_dir subjects{su} ]);
        
    % Load eye event times
    % OPEN FILE
    fid_samps = fopen([data_dir subjects{su} '_Samples.txt']);
    fid_evs = fopen([data_dir subjects{su} '_Events.txt']);
   
    % Collect data from each trial
    for rn = 1: length(Exp.Run)
       for bk = 1: length(Exp.Run(rn).block)
          for tr = 1 : length(Exp.Run(rn).block(bk))
              
              % Behavior
              Run(rn).block(bk).id =  Exp.Run(rn).block(bk).id;
              Run(rn).block(bk).idx = Exp.rnd_idxs(rn);
              Run(rn).block(bk).nTrials =  Exp.Run(rn).block(bk).nTrials;
              Run(rn).block(bk).stimFrames =  Exp.Run(rn).block(bk).stimFrames;
              Run(rn).block(bk).interStimInterval =  Exp.Run(rn).block(bk).interStimInterval;
              Run(rn).block(bk).response = Exp.Run(rn).block(bk).respType;
              Run(rn).block(bk).response_times = (1: Exp.Run(rn).block(bk).stimFrames) / 60; % In Secs
              
              % Eye data
              
              % Find next corresponding start of run (they are indexed)
              % collect trials
              % find the next end of run and move to the next run
              
              
          end
       end
    end
    
    
    %% As the events are at the end of the .txt we need to search for them
    %% here separately and add them to the structure
    
    
    
    
    %% Finally, add the continuous data to the structure (this data is on a
    %% separate file
    
    % OPEN FILE
    fid_samps = fopen([data_dir subjects{su} '_Samples.txt']);

    
    
    %%    
    fclose('all'); % clean fids
     
end


%% FUnction definitions

function [line tline] = search_text(filename,texts,maxlines)
%search for texts in the first maxlines and gives both the line number and the
%text
line = [];
tline = [];
fid = fopen(filename);
icount = 0;
while (isempty(ferror(fid)) && icount<maxlines)
    icount = icount+1;
    tline  =  fgetl(fid);    %read one line
    for i = 1:length(texts)  %for all searched texts
        if ~isempty(strfind(tline,texts{i}))
            line = icount;
            fclose(fid);
            return
        end
    end
end
fclose(fid);
if isempty(line)
    tline = [];
end

