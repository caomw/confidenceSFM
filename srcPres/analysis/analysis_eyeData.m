function analysis_eyeData

% Loop through subjects
data_dir = '../../dataRaw/';

% Here we define all subjects that we are going to analyze
subjects = {'MO' 'NS' 'TF'};


% Loop through subjects
for su = 1 : length(subjects)
    
    % Load each subject once at a time,if you don't specify any return
    % variable to 'load' you'll just get 'Exp' on the workspace
    load ( [data_dir subjects{su}]);
    
    
    % Load eye event times
    
    
end

