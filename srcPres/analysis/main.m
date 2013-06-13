function data = main 
%Returns a matrix with columns Subject number, Type, number of 9s, number
%of 8s, number of switches and the run number
%Run 1x9 | Block 1x5 | Trial nxm
%total matrix has dimension 780x6

%Load data file
scripts_dir = '../data/';

Data = load ( [scripts_dir 'MO.mat'] )

%Set dimensions
Rows = 780;
Columns = 6;

TotalMatrix = rand(Rows,Columns);

CurrentRow = 1;

%Enter subject number
SubNum = input('Subject number: ');

%Selects a Run
for j=1:9,
    %Selects a Block
    for k=1:5,
       Dimensions = size(Data.Exp.Run(1,j).block(1,k).respType);
       %Selects a Row
       for i=1:Dimensions(1),
           CountNines = 0;
           CountEights = 0;
           NumSwitches = 0;
           %Selects a Column/Trial
           for l=1:Dimensions(2),
               %Count the number of 9s
               if Data.Exp.Run(1,j).block(1,k).respType(i,l) == 9
                   CountNines = CountNines + 1;
                   %Don't run on the last column
                   if l~=Dimensions(2)
                       %Count switches from 9 to 8
                       if Data.Exp.Run(1,j).block(1,k).respType(i,l+1) == 8                   
                        NumSwitches = NumSwitches + 1;
                       end
                   end
               end
               
               %Count the number of 8s
               if Data.Exp.Run(1,j).block(1,k).respType(i,l) == 8
                   CountEights = CountEights + 1;
                   %Don't run on the last column
                   if l~=Dimensions(2)
                       %Count switches from 8 to 9
                       if Data.Exp.Run(1,j).block(1,k).respType(i,l+1) == 9                   
                        NumSwitches = NumSwitches + 1;
                       end                     
                   end
               end                         
           end
           
           %Set subject number
           TotalMatrix(CurrentRow,1) = SubNum;

           %Set Type
           TotalMatrix(CurrentRow,2) = sym(Data.Exp.Run(1,j).block(1,k).id(1,1)); 
           
           %Sets the number of 9s
           TotalMatrix(CurrentRow,3) = CountNines; 
    
           %Sets the number of 8s
           TotalMatrix(CurrentRow,4) = CountEights;           

           %Sets the number of switches
           TotalMatrix(CurrentRow,5) = NumSwitches; 
         
           %Sets run number
           TotalMatrix(CurrentRow,6) = j; 
           
           %Increment row
           CurrentRow = CurrentRow + 1;       
       end
   end
end

%Display matrix and headers
disp('       Sub no.       Type     No. of 9s   No. of 8s    Switches  Position of run');

%Display results
disp(TotalMatrix);

