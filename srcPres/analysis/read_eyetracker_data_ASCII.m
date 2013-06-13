function [all a]  =  read_eyetracker_data_ASCII(varargin)
% modified 29/5/2012 MJI: Changed from 'mode' to 'eye' to select tracking
% mode because there were cases with mode BTABLER where only one eye was
% tracked.
% modified 21/10/09. Remove artificial saccades right before each blink
% the field with the "correct" saccades is all.lesacc

if isempty(varargin)  ==  1
    file   =  uigetfile({'*.edf; *.asc', 'EyeLink data(*.edf, *.asc)'; ...
        '*.*', 'All files(*.*)'}, 'File open');
else
    file  =  varargin{1};
end

% bgn_fulltrial  =  varargin{2}; % modified 07/06/11. To be used by other experiments


file_name  =  file(1:end-4); %Filename without extension
extension_type  =  strcmp(file(end-2:end),'asc');

%convert edf file only if requested
if (~extension_type)
    [str, maxsize, endian] = computer;
    switch str
        case {'PCWIN','PCWIN64'}
            if exist([pwd '\edf2asc.exe'],'file') == 0
                directory  =  which('edf2asc.exe');
                copyfile(directory,pwd);
            end
            dos(['edf2asc.exe ',file]);
        case {'MACI','MACI64'}
            run_maci  =  sprintf(['/Applications/Eyelink/EDF_Access_API/Example/edf2asc ',file_name]);
            unix(run_maci);
        otherwise
            disp('Problem converting data with edf2asc')
    end
end
disp(['File: ' file])

%start processing of ascii file
file  =  [file_name '.asc'];

mode  =  mode_eyelink(file);
disp(['mode: ' mode]);

eye  =  identify_eye(file);
disp(['eye: ' eye]);

srate  =  search_samplingrate(file);
disp(['Sampling Rate: ' num2str(srate)]);

%look for starting tag "SAMPLES\tGAZE" or "EVENTS\tGAZE" or "SYNCTIME"
line  =  search_text(file, {'SAMPLES	GAZE' 'EVENTS	GAZE' 'SYNCTIME'}, 1000);
if isempty(line)
    disp('no text found before EOF!!')
    disp('Start line guess: 200')
    S = 200;
else
    S = line+5;
    disp(['Start line: ' num2str(S)])
end

%open file "filename" and stores everything in cell C
filename  =  file;
fid  =  fopen(filename);
C  =  textscan(fid, '%s','HeaderLines',S,'delimiter', '\n');
fclose(fid);
a  =  C{1};
clear C;

%search samples
%all.samples  =  search_samples(a,mode);
all.samples  =  search_samples(a,eye);
%search all event types
all.resac  =  search_events(a,'ESACC R');
all.lesac  =  search_events(a,'ESACC L');
all.refix  =  search_events(a,'EFIX R');
all.lefix  =  search_events(a,'EFIX L');
all.rebli  =  search_events(a,'EBLINK R');
all.lebli  =  search_events(a,'EBLINK L');
[all.msgtime all.msgline]  =  search_events(a,'MSG');
all.msg  =  a(all.msgline);
all.mode  =  mode;
all.eye  =  eye;
all.srate  =  srate;

all.headerlines  =  S;

%Remove artificial saccades right before each blink
slebli = all.lebli(:,1); slesac = all.lesac(:,1);
elebli = all.lebli(:,2); elesac = all.lesac(:,2);
ind_lesac = [];
ind_lebli = [];
for ii = 1:size(slesac,1)
    for jj = 1:size(slebli,1)
        if(slebli(jj)>slesac(ii) && elebli(jj)<elesac(ii))
            ind_lesac = [ind_lesac ii];
            ind_lebli = [ind_lebli jj];
        end
    end
end

all.lesacc = all.lesac;
all.lesacc(ind_lesac,:) = [];

srebli = all.rebli(:,1); sresac = all.resac(:,1);
erebli = all.rebli(:,2); eresac = all.resac(:,2);
ind_resac = [];
ind_rebli = [];
for ii = 1:size(sresac,1)
    for jj = 1:size(srebli,1)
        if(srebli(jj)>sresac(ii) && erebli(jj)<eresac(ii))
            ind_resac = [ind_resac ii];
            ind_rebli = [ind_rebli jj];
        end
    end
end

all.resacc = all.resac;
all.resacc(ind_resac,:) = [];

%To delete the timestamp before the message in all.msg
for i = 1:length(all.msg)
    [A, count, errmsg, nextindex] = sscanf(all.msg{i},'MSG%f');
    %nextindex is the index following MSG + float
    all.msg{i} = all.msg{i}(nextindex+1:end);
end

[all.driftcorrect all.driftcorrecttime] = search_driftcorrect(all); % needs all.msg

%look for trial number
% all.TRIAL_number = search_patterninmessage('bgn_fixdot: ',all,'number');
% all.TRIAL_number = search_patterninmessage(bgn_fulltrial,all,'number'); % modified 07/06/11. To be used by other experiments

% %look for data viewer messages
% all.DViewer_image = search_patterninmessage('!V IMGLOAD FILL ',all,'string');
%look for trial number
% all.TRIAL_number = search_patterninmessage('!V TRIAL_VAR trial ',all,'number');
% %look for trial result (2 = positive response, -1 = no response, 0 = null)
% all.TRIAL_result = search_patterninmessage('!V TRIAL_RESULT ',all,'number');

% save all all

end






%% Function definitions

function matrix = search_samples(data,eye)
tic
if strcmp(eye,'RIGHT') || strcmp(eye,'LEFT') %remote or monocular mode
    %binocular mode is much slower.
    matrix = nan(length(data),4);
    for i = 1:length(data);
        temp = sscanf(char(data(i)),'%f');
        %the trick is that sscanf will only read the 4 numbers and skip the
        %rest:
        %27713756          513.1   396.6   651.0 ...      4190.0  2688.0   617.6 .............
        if length(temp) == 4
            matrix(i,:) = temp;
        elseif length(temp) == 1
            matrix(i,:) = nan;
            matrix(i,1) = temp;
        end
    end
elseif strcmp(eye,'BOTH') %binocular
    %is more difficult and takes longer to avoid problems coming from only one
    %blinked eye
    DATAPERSAMPLE = 8;
    matrix = nan(length(data),DATAPERSAMPLE);
    for i = 1:length(data);
        if mod(i,10000) == 0;fprintf(1,'%d0k \ns',i/10000);end
        
        str  =  char(data(i));
        C    =  textscan(str, '%s','delimiter', '\t');
        C    =  str2double(C{1});
        % Excluye NaNs (creo)
        %         if (length(C) == DATAPERSAMPLE+1)
        if (length(C) == DATAPERSAMPLE)   % No se por que estaba
            %  == DATASAMPLE+1, pero para el
            % experimento de Aritmetica no
            % funciona, lo puse  == DATASAMPLE y
            % eventualmente (si genera un error
            % mas adelante) habra que revisarlo
            matrix(i,:)  =  C(1:DATAPERSAMPLE);
        end
    end
    matrix(find(isnan(matrix(:,5))),7) = nan;
else
    disp('unknown eye')
    matrix = [];
    return
end


Index = find(isnan(matrix(:,1)));
matrix(Index,:) = [];


elapsed_time = toc;
disp([num2str(length(matrix)) ' samples found in ' num2str(elapsed_time) ' secs'])
disp(['Samples processed/sec  =  ' num2str(length(matrix)/elapsed_time)])


end

function [matrix indexes]  =  search_events(data,event_name)


switch event_name
    case {'EFIX L','EFIX R' }
        elem_to_read = 6;
    case {'ESACC L','ESACC R'}
        elem_to_read = 9;
    case {'EBLINK L','EBLINK R'}
        elem_to_read = 3;
    case 'MSG'
        elem_to_read = 1;
    otherwise
        disp('Unknown event name found')
end


indexes = mystrmatch(event_name,data);
matrix = nan(length(indexes),elem_to_read);
for i = 1:length(indexes);
    temp = sscanf(data{indexes(i)},[event_name ' %f %f %f %f %f %f %f %f %f']);
    matrix(i,1:length(temp)) = temp;
end
disp([num2str(length(indexes)) ' events ' event_name ' found.'])

end

function [coincidences] = mystrmatch(string,data)
coincidences = [];
block_size = 200000;
pos = 0;
icount = 0;
while pos<length(data);
    if (pos+block_size)>length(data)
        indexes = (pos+1):length(data);
    else
        indexes = pos+(1:block_size);
    end
    to_add = pos+strmatch(string,data(indexes));
    coincidences = [coincidences; to_add];
    pos = pos+block_size;
    icount = icount+1;
    %        fprintf(1,'%d %d %d %d\n',icount,indexes(1),indexes(end),length(to_add))
end
end

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
end

function mode = mode_eyelink(file)
% looks for mode (M)onocular, (B)inocular (R)emote
mode = [];
[line textline] = search_text(file, {'ELCLCFG'}, 1000);
if strfind(textline,'RTABLE')>0
    mode = 'RTABLE';%remote
elseif  strfind(textline,'BTABLE')>0
    mode = 'BTABLE';%binocular
elseif strfind(textline,'MTABLE')>0
    mode = 'MTABLE';%monocular
end
end

function eye = identify_eye(file)
% looks for eye(s)
[line textline] = search_text(file,{'START'},1000);
%eye = [];
if isempty(line)
    eye = nan;
else
    right = strfind(textline,'RIGHT');
    left = strfind(textline,'LEFT');
    if ~isempty(right) && ~isempty(left)
        eye = 'BOTH';
    elseif ~isempty(right) && isempty(left)
        eye = 'RIGHT';
    elseif isempty(right) && ~isempty(left)
        eye = 'LEFT';
    else
        eye = '??';
        disp('Eye(s) not recognized')
    end
end
end

function srate = search_samplingrate(file)
[line textline] = search_text(file,{'RATE'},1000);
if isempty(line)
    srate = [];
else
    position = strfind(textline,'RATE');
    srate = sscanf(textline(position+4:end),'%f');
end

end

function [driftcorrect driftcorrecttime] = search_driftcorrect(all)
%gives all the drift corrections
%[[dcxl dcyl]
% [dcxr dcyr]]
driftcorrects = strmatch('DRIFTCORRECT', all.msg);
if ~isempty(driftcorrects)
    times  =  all.msgtime(driftcorrects);
    j  =  1;
    for i = 1:length(driftcorrects)
        driftline = driftcorrects(i);
        textline = all.msg(driftline);
        isleft = cell2mat(strfind(textline,'LEFT'))>0;
        isright = cell2mat(strfind(textline,'RIGHT'))>0;
        foo  =  1;
        if isleft %~isempty(isleft)
            position = strfind(textline,'deg.');
            driftcorrectleft = sscanf(textline{1}(position{1}+4:end),'%f,%f');
            driftcorrectright = [nan; nan];
        elseif isright %~isempty(isright)
            position = strfind(textline,'deg.');
            driftcorrectright = sscanf(textline{1}(position{1}+4:end),'%f,%f');
            driftcorrectleft = [nan; nan];
        else
            disp('Check drift corrections!!!')
            foo  =  0;
        end
        if foo  ==  1
            driftcorrect{j} = [driftcorrectleft driftcorrectright]';
            driftcorrecttime(j)  =  times(i);
            j  =  j+1;
        elseif foo  ==  0
            driftcorrect      =  [];
            driftcorrecttime  =  [];
        end
    end
else
    driftcorrect      =  [];
    driftcorrecttime  =  [];
end
end

function [message] = search_patterninmessage(pattern,all,type)
%look for pattern in message
skip_length = length(pattern);
icount = 0;
for i = 1:length(all.msg)
    strfound = strmatch(pattern,all.msg{i});
    if(~isempty(strfound))
        icount = icount+1;
        space_location = strfind(all.msg{i}(skip_length+1:end),' ');
        if(~isempty(space_location))
            message{icount} = all.msg{i}(skip_length+1:skip_length+space_location(1)-1);
        else
            message{icount} = all.msg{i}(skip_length+1:end);
        end
        if(strmatch(type,'number'))
            message{icount} = str2num(message{icount});
        elseif(~strmatch(type,'string'))
            disp('Message type not defined')
        end
        
    end
end


end
