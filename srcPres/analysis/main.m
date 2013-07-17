function TotalMatrix = main

% Returns a matrix with columns Subject number, Type of run, number of 9s, number
% of 8s, number of switches and the run number
% Run 1x9 | Block 1x5 | Trial nxm

% Load data file
% I've added a new folder called 'analysis' inside scrPres. We'll put this 
% code (and other analysis codes) there. You should create the folder and
% move this script there for the function main to work
data_dir = '../../dataRaw/final/Young'; 

 % Here we define all subjects that we are going to analyze
subjects = {'MO.mat' 'NS.mat' 'TF.mat'};

% Loop through subjects
for su = 1 : length(subjects)
    
    % Load each subject once at a time,if you don't specify any return
    % variable to 'load' you'll just get 'Exp' on the workspace
    load ( [data_dir subjects{su}]);
    
    % Now here you just need to collect some data. It is fine how you
    % code as a final product the variable TotalMatrix 
    
    % For each subject we loop through each Run ...
    for run = 1: length(Exp.Run) % Give your indexes meaningful names, it helps understand the code
        
        % ... and for each run through each Block
        for blk = 1:5
            
            %Now here we are at each Run/Block, this is where you need to
            %collect or calculate everything.  
            % Stop the script at this point and execute this in the command
            % line: Exp.Run(run).block(blk)
            % This is where all the information you need is stored. See
            % carefully the indexes and how we retrieve the info from each
            % RUn / Block
            
            % Set subject number: for example, you don't need to calculate
            %this value, it's already in Exp.Gral
            TotalMatrix(CurrentRow,1) = Exp.Gral.SubjectNumber;
            
            %Set Type: Careful here. Exp.Run(run).block(blk).id is a string
            % You cannot store strings inside a matrix as matrixes only
            % accept numbers in their cells. You should create a code
            % number for each id and store the number in the matrix (and
            % keep the codes in your notebook or even better, as a comment
            % in this code)
            TotalMatrix(CurrentRow,2) = Exp.Run(run).block(blk).id ;
            
            %Sets the number of 9s. Here you need to loop through the
            %vector Exp.Run(run).block(blk).respType and count how many
            %times a 9 appeared after a nan or after an 8. Only the first 9
            %matters, not the whole row. In the same way you need to count
            %how many 8s appeared after a 9 or after a nan. This two counts
            %will tell us how many switches there were in the block
            
            TotalMatrix(CurrentRow,3) = CountNines;
            
            TotalMatrix(CurrentRow,4) = CountEights;
            
            TotalMatrix(CurrentRow,5) = NumSwitches;
                        
            %Sets run number. This is simply... run
            TotalMatrix(CurrentRow,6) = run;
            
        end
    end
end



%% You don't need this
%
% %Set dimensions
% Rows = 780;
% Columns = 6;
%
% TotalMatrix = rand(Rows,Columns);
%
% CurrentRow = 1;
%
% %Enter subject number
% SubNum = input('Subject number: ');

%%

% 
% %Selects a Run
% for j=1:9
%     %Selects a Block
%     for k = 1:5
%         Dimensions = size(Exp.Run(1,j).block(1,k).respType);
%         %Selects a Row
%         for i=1:Dimensions(1)
%             CountNines = 0;
%             CountEights = 0;
%             NumSwitches = 0;
%             %Selects a Column/Trial
%             for l=1:Dimensions(2)
%                 %Count the number of 9s
%                 if Exp.Run(1,j).block(1,k).respType(i,l) == 9
%                     CountNines = CountNines + 1;
%                     %Don't run on the last column
%                     if l~=Dimensions(2)
%                         %Count switches from 9 to 8
%                         if Exp.Run(1,j).block(1,k).respType(i,l+1) == 8
%                             NumSwitches = NumSwitches + 1;
%                         end
%                     end
%                 end
%                 
%                 %Count the number of 8s
%                 if Exp.Run(1,j).block(1,k).respType(i,l) == 8
%                     CountEights = CountEights + 1;
%                     %Don't run on the last column
%                     if l ~= Dimensions(2)
%                         %Count switches from 8 to 9
%                         if Exp.Run(1,j).block(1,k).respType(i,l+1) == 9
%                             NumSwitches = NumSwitches + 1;
%                         end
%                     end
%                 end
%             end
%             
%             %Set subject number
%             TotalMatrix(CurrentRow,1) = SubNum;
%             
%             %Set Type
%             TotalMatrix(CurrentRow,2) = sym(Exp.Run(1,j).block(1,k).id(1,1));
%             
%             %Sets the number of 9s
%             TotalMatrix(CurrentRow,3) = CountNines;
%             
%             %Sets the number of 8s
%             TotalMatrix(CurrentRow,4) = CountEights;
%             
%             %Sets the number of switches
%             TotalMatrix(CurrentRow,5) = NumSwitches;
%             
%             %Sets run number
%             TotalMatrix(CurrentRow,6) = j;
%             
%             %Increment row
%             CurrentRow = CurrentRow + 1;
%         end
%     end
% end
% 
% 
% 
% 
% %Display matrix and headers
% disp('       Sub no.       Type     No. of 9s   No. of 8s    Switches  Position of run');
% 
% %Display results
% disp(TotalMatrix);

