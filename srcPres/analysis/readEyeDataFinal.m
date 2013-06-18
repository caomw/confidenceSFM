function [SaccInfo, coordinates]= readEyeDataFinal (inFileName, inDir)

% Input: txt data file  from eyelink system; data structure from ASF behavioural
% experiment (ExpInfo)
% Reads a txt file that contains the information about the saccades done by
% a subject during the experiment

% The function extracts from each trial the following information:
% -Number of saccades performed inside each trial.
% -For every saccade: Onset time; Initial coordinates of the saccade;
%  Velocity of the saccade;  Final coordinates of the saccade.
% -Output: SaccInfo matrix with the information specified above about eye
% movements.
% SaccInfo= [trialNumber, trialStartTime, requestSaccTime, saccDirection, saccStartT, saccEndT, ...
% saccInitXPos, saccInitYPos, saccEndXPos, saccEndYPos, saccOnsetT, avgVelocity, peakVelocity,  ...
% primeTime, maskTime ];

% Coordinates: it's a cell array containing the position coordinates
% of each saccade. For every cell it contains a 3xn matrix, where the first row
% corresponds to the x positions, the second row to the y positions and the
% third row to the time in milliseconds. Each cell corresponds to the
% saccades perfomed in each trial.

% This matrix can be appended later to ExpInfo structure

% EXAMPLE CALL: [SaccInfo, coordinates]= readEyeDataFinal (inFileName,inDir)


%% START

try

    % PREALLOCATE THE VARIABLES
    % nTrials = length(ExpInfo.TrialInfo);
    trialNumber= []; trialStartTime=[]; requestSaccTime= 0; saccStartT=[];saccDirection=[]; saccInitXPos=[]; %#ok
    saccInitYPos=[];saccEndT=[]; saccEndXPos=[]; saccEndYPos=[]; saccOnsetT=[]; avgVelocity=[]; peakVelocity=[]; %#ok
    primeTime=0; maskTime=0; %#ok

    % Note:
    % saccDirection is coded in the following manner inside the matrix: R -right- is coded with
    % number 4 and 'L' -left is coded with number 3 FOLLOWING THE
    % TRDgeneratorBlock1 file.
    % 3: CROSS TO THE LEFT
    % 4: CROSS TO THE RIGHT

    % Saccades Matrix
    SaccInfo(1, 1:15)= 1;
    lineCounter=0;
    trialStartCounter= 0;
    m=1; %matrix counter
    %Coordinates is the matrix that holds all the positions of the saccades
    %across time. 1 row= x position; 2 row= y position; 3 row= time in ms
    coordinates{1}=zeros(3,1);
    % OPEN FILE
    fid=fopen([inDir inFileName]); %flag to control that only the first ESACC after REQSACC is recorded


    %% EYELINK DATA NOTATIONS

    % <eye> which eye caused event ("L" or "R")
    % <time> timestamp in milliseconds
    % <stime> timestamp of first sample in milliseconds
    % <etime> timestamp of last sample in milliseconds
    % <dur> duration in milliseconds
    % <axp>, <ayp> average X and Y position
    % <sxp>, <syp> start X and Y position data
    % <exp>, <eyp> end X and Y position data
    % <aps> average pupil size (area or diameter)
    % <av>, <pv> average, peak velocity (degrees/sec)
    % <ampl> saccadic amplitude (degrees)
    % <xr>, <yr> X and Y resolution (position units/degree)

    %%
    %LOOP THROUGH THE TEXT FILE
    while (1)

        %GET LINE BY LINE OF TEXT FILE
        tline = fgetl(fid);
        lineCounter=lineCounter+1;
        %Check whether we've reached the end of the file
        if ~ischar(tline), sprintf('End of Trials'), break, end;
        %Skip line if it's an empty one.
        if isempty(tline), continue, end;

        %SCAN FOR THE START TIME OF EXPERIMENT
        K= textscan(tline, '%s %n %s %s %s');
        if (strcmp(K{1},'START'))  %  findstr(tline, 'START')
            expStartTime= K{2}; % timestamp in milliseconds
        end

        %SCAN LINE AND SEARCH FOR THE BEGINING OF TRIALS
        if ( ~isempty(findstr(tline, 'MSG')) && ~isempty(regexp(tline, 'TRIALSTART', 'once')));
            trialStartCounter= trialStartCounter + 1;

            %Skip the first TRIALSTART BECAUSE IT IS NOT A TRIAL. It's just
            %an initial mark left by Eyelink.
            if (trialStartCounter==1)
                continue;
            end

            %New codeTRIALSTART
            trialNumber= trialStartCounter -1 ; %As the first TrialStart is not a trial.

            %Code trial start time from Eyelink
            A= textscan(tline, '%s %n %s');
            %Get trial start time
            trialStartTime= A{2}- expStartTime; % timestamp in milliseconds

            %CONTINUE SEARCHING FOR LINES TO READ ALL THE SACCADES FOR THIS
            %PARTICULAR TRIAL
            flag= 0; %flag to control that only the first ESACC after REQSACC is recorded
            counter=1; %counter for the number of positions we've got to collect for each saccade

            while (1)

                %GET LINE BY LINE
                tline = fgetl(fid);
                lineCounter=lineCounter+1;

                % LOOK FOR THE TIME AT WHICH THE SACCADE WAS REQUESTED
                % Take the initial time of the REQSACC
                if (~isempty(findstr(tline, 'MSG')) && ~isempty(regexp(tline, 'REQSACC','once')))
                    %Extract time on requested saccade
                    Z= textscan(tline, '%s %n %s');
                    absRequestedTime= Z{2}-expStartTime;
                    requestSaccTime = absRequestedTime - trialStartTime;
                    saccadeStartTime= Z{2}; 
                    flag=1;
                    continue; %Jump to the next line
                end

                % TAKE THE TIME OF APPEARANCE OF THE PRIME AND THE MASK
                if (~isempty(findstr(tline, 'MSG')) && ~isempty(regexp(tline, 'PRIME','once')))
                    X= textscan(tline, '%s %n %s');
                    primeTime= X{2}- expStartTime - trialStartTime;
                    continue; % jumpl to next line
                end
                if (~isempty(findstr(tline, 'MSG')) && ~isempty(regexp(tline, 'MASK','once')))
                    Y= textscan(tline, '%s %n %s');
                    maskTime= Y{2}- expStartTime - trialStartTime; 
                    continue; %jump to next line
                end
                %In case we encounter the line for a fixation or the
                %starting line for a saccade just go to the next line
                if ~isempty(findstr(tline, 'SFIX')) || ~isempty(findstr(tline, 'EFIX')) || ...
                        ~isempty(findstr(tline, 'SBLINK')) || ~isempty(findstr(tline, 'EBLINK')) || ...
                        ~isempty(findstr(tline, 'SSACC'))
                    continue; %jumpl to next line
                end
                %REGISTER THE POSITIONS IN X AND Y UNTIL THE END OF THIS SACCADE.
                %THESE ARE THE COORDINATES OF THE SACCADE FROM THE REQUESTED
                %TIME
                %The line must NOT contain and ESACC, to avoid the problem
                %of the data types returned by 'textscan'
                
                %Check that: 'reqsacc' has happened, that the line has no
                %'esacc' and that the line is not a line
                if (flag==1 && isempty(findstr(tline, 'ESACC')) && isempty(regexp(tline, 'TRIALEND', 'once')) )                    %If we are already recording the saccade take all
                    % coordinates of this saccade. REQSACC has just appeared.
                    T= textscan(tline, '%f %f %f %f');
                    %COLLECT THE COORDINATES DATA
                    %Check that there are no empty '.' in the line
                    %-corresponding to the blinks-
                    if ~isempty(T{2}) && ~isempty(T{3})
                        coordinates{trialNumber}(1,counter) = T{2}; %#ok Position in X
                        coordinates{trialNumber}(2,counter) = T{3}; %#ok Position in Y
                        coordinates{trialNumber}(3,counter) = T{1}-saccadeStartTime; %#ok Time in ms
                        counter= counter+1;
                    elseif isempty(T{2}) && isempty(T{3}) && counter==1
                        coordinates{trialNumber}(1,counter) = 0; %#ok
                        coordinates{trialNumber}(2,counter) = 0; %#ok
                        coordinates{trialNumber}(3,counter) = T{1}-saccadeStartTime; %#ok Time in ms
                        counter= counter+1;
                    else
                        coordinates{trialNumber}(1,counter) = coordinates{trialNumber}(1,counter-1); %#ok
                        coordinates{trialNumber}(2,counter) = coordinates{trialNumber}(2,counter-1); %#ok
                        coordinates{trialNumber}(3,counter) = T{1}-saccadeStartTime; %#ok Time in ms
                        counter= counter+1;
                    end
                    
                    continue; %jump to next line

                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % IF WE REACH TO THE END OF THE SACCADE THEN LOOK FOR ALL
                % INFORMATION ABOUT IT
                %In every line starting with ESACC there is all
                %information:
                %ESACC <eye> <stime> <etime> <dur> <sxp> <syp> <exp> <eyp>
                % <ampl> <pv>
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if (~isempty(findstr(tline, 'ESACC')) && flag==1)
                    %Scan the line
                    C= textscan(tline, '%s %s %n %n %n %n %n %n %n %n %n');
                    %Extract info on saccade start time
                    saccStartT= C{3}-expStartTime; %<stime> timestamp of first sample in milliseconds
                    %Extract info on saccade end time
                    saccEndT= C{4}-expStartTime; % <etime> timestamp of last sample in milliseconds
                    %Calculate the saccade onset time for each trial
                    saccOnsetT= (saccStartT-trialStartTime)- requestSaccTime;
                    %Extract info on saccade Initial Positions
                    saccInitXPos= C{6}; %<sxp>
                    saccInitYPos= C{7}; %<syp>
                    %Extract info on saccade Final Positions
                    saccEndXPos= C{8}; %<exp>
                    saccEndYPos= C{9}; %<eyp>
                    %Extract info on saccade direction: rightward  or leftward saccade
                    if(saccInitXPos > saccEndXPos)
                        saccDirection= 3; %Left Saccade
                    elseif (saccInitXPos < saccEndXPos)
                        saccDirection= 4; %Rigth Saccade
                    end
                    %Extract info on saccade average velocity;
                    % The total visual angle
                    %covered in the saccade is reported by <ampl>, which
                    %can be divided by (<dur>/1000) to obtain the average
                    %velocity.
                    avgVelocity= C{10}/ (C{5}/1000);
                    %Extract info on saccade peak Velocity
                    peakVelocity= C{11}; %

                    % FILL THE MATRIX...
                    SaccInfo(m,:)= [trialNumber, trialStartTime, requestSaccTime, saccDirection, saccStartT, saccEndT, ...
                        saccInitXPos, saccInitYPos, saccEndXPos, saccEndYPos, saccOnsetT, avgVelocity, peakVelocity,  ...
                        primeTime, maskTime ];
                    % AND MOVE TO THE NEXT TRIAL
                    m=m+1;
                    flag=0; %#ok
                    break;

                    %CHECK END OF TRIAL: if reached without recording any saccade then move to the begining of
                    %the next trial
                elseif ( ~isempty(findstr(tline, 'MSG')) && ~isempty(regexp(tline, 'TRIALEND', 'once')) && flag==1);
                    % FILL THE MATRIX WITH ZEROS -NO SACCADE FOR THIS
                    % TRIAL-
                    SaccInfo(m,:)= [trialNumber, trialStartTime, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 0, 0, 0, 0];

                    %DO THE SAME FOR THE STRUCTURE WITH THE COORDINATES: in
                    %this case there will be no error later on the
                    %consistency check between the two matrixes.
                    coordinates{trialNumber}(1,counter) = 0; %#ok
                    coordinates{trialNumber}(2,counter) = 0; %#ok
                    coordinates{trialNumber}(3,counter)= 0; %#ok

                    % AND MOVE TO THE NEXT TRIAL
                    m=m+1;
                    flag=0; %#ok
                    break;

                end %end of 'ESACC' condition
            end % end of while for saccades inside a trial
        end %end of loop for trial start
    end %end of loop for trials

catch ME1
    sprintf('Error at line: \t %d', lineCounter);
    rethrow(ME1)
end

% Close file
fclose(fid);
%%
%% THE END
%%

%% Todo

%Correct the flow of the script. First discard every message that is of no
%interest: fixations, blinks, trialends, startsaccades.
%After this collect the relevant data: coordinates and saccade endings

