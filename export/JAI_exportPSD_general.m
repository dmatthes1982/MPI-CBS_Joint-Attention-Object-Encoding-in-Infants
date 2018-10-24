% -------------------------------------------------------------------------
% Add directory and subfolders to path
% -------------------------------------------------------------------------
clc;
filepath = fileparts(mfilename('fullpath'));
run([filepath '/../JOEI_init.m']);

cprintf([0,0.6,0], '<strong>------------------------------------------------</strong>\n');
cprintf([0,0.6,0], '<strong>Joint attention object encoding in infants</strong>\n');
cprintf([0,0.6,0], '<strong>Export of PSD results (general script)</strong>\n');
cprintf([0,0.6,0], 'Copyright (C) 2018, Daniel Matthes, MPI CBS\n');
cprintf([0,0.6,0], '<strong>------------------------------------------------</strong>\n');

% -------------------------------------------------------------------------
% Path settings
% -------------------------------------------------------------------------
path = '/data/pt_01904/eegData/';                                           % root path to eeg data

fprintf('\nThe default path is: %s\n', path);

selection = false;
while selection == false
  fprintf('\nDo you want to use the default path?\n');
  x = input('Select [y/n]: ','s');
  if strcmp('y', x)
    selection = true;
    newPaths = false;
  elseif strcmp('n', x)
    selection = true;
    newPaths = true;
  else
    selection = false;
  end
end

if newPaths == true
  path = uigetdir(pwd, 'Select folder...');
  path = strcat(path, '/');
end

clear newPaths

% -------------------------------------------------------------------------
% Session selection
% -------------------------------------------------------------------------
fprintf('\n<strong>Session selection...</strong>\n');
srcPath = [path 'EEG_JOEI_processedData/'];
srcPath = [srcPath  '06a_pwelch/'];

fileList     = dir([srcPath, 'JOEI_p*_06a_pwelch_*.mat']);                  % determine all avaible sessions
fileList     = struct2cell(fileList);
fileList     = fileList(1,:);
numOfFiles   = length(fileList);

sessionNum   = zeros(1, numOfFiles);
fileListCopy = fileList;

for part=1:1:numOfFiles
  fileListCopy{part} = strsplit(fileList{part}, '06a_pwelch_');
  fileListCopy{part} = fileListCopy{part}{end};
  sessionNum(part) = sscanf(fileListCopy{part}, '%d.mat');
end

sessionNum = unique(sessionNum);                                    
y = sprintf('%d ', sessionNum);

userList = cell(1, length(sessionNum));                                     % determine session owners

for part = sessionNum
  match = find(strcmp(fileListCopy, sprintf('%03d.mat', part)), 1, 'first');
  filePath = [srcPath, fileList{match}];
  [~, cmdout] = system(['ls -l ' filePath '']);
  attrib = strsplit(cmdout);
  userList{part} = attrib{3};
end

selection = false;                                                          % session selection
while selection == false
  fprintf('The following sessions are available: %s\n', y);
  fprintf('The session owners are:\n');
  for part = sessionNum
    fprintf('%d - %s\n', part, userList{part});
  end
  fprintf('\n');
  fprintf('Please select one session:\n');
  fprintf('[num] - Select session\n\n');
  x = input('Session: ');

  if length(x) > 1
    cprintf([1,0.5,0], 'Wrong input, select only one session!\n');
  else
    if ismember(x, sessionNum)
      selection = true;
      sessionStr = sprintf('%03d', x);
    else
      cprintf([1,0.5,0], 'Wrong input, session does not exist!\n');
    end
  end
end

fprintf('\n');

clear sessionNum fileListCopy y userList match filePath cmdout attrib ...
      fileList numOfFiles x selection part

% -------------------------------------------------------------------------
% Participant selection
% -------------------------------------------------------------------------
fprintf('<strong>Participant selection...</strong>\n');
fileList     = dir([srcPath 'JOEI_p*_06a_pwelch_' sessionStr '.mat']);
fileList     = struct2cell(fileList);
fileList     = fileList(1,:);                                               % generate list with filenames of all existing participants
numOfFiles   = length(fileList);

listOfPart = zeros(numOfFiles, 1);

for i = 1:1:numOfFiles
  listOfPart(i) = sscanf(fileList{i}, ['JOEI_p%d_06a_pwelch_'  ...          % generate a list of all available numbers of participants
                                        sessionStr '.mat']);
end

listOfPartStr = cellfun(@(x) sprintf('%d', x), ...                          % prepare a cell array with all possible options for the following list dialog
                        num2cell(listOfPart), 'UniformOutput', false);

sel = listdlg('PromptString',' Select participants...', ...                 % open the dialog window --> the user can select the participants of interest
                'ListString', listOfPartStr, ...
                'ListSize', [220, 300] );

listOfPartBool = ismember(1:1:numOfFiles, sel);                             % transform the user's choise into a binary representation for further use

participants = listOfPartStr(listOfPartBool);                               % generate a cell vector with identifiers of all selected participants

fprintf('You have selected the following participants:\n');
cellfun(@(x) fprintf('%s, ', x), participants, 'UniformOutput', false);     % show the identifiers of the selected participants in the command window
fprintf('\b\b.\n\n');

participants  = listOfPart(listOfPartBool);                                 % generate participant vector for further use
fileList      = fileList(listOfPartBool);
numOfFiles    = length(fileList);

clear listOfPart listOfPartStr listOfPartBool i

% -------------------------------------------------------------------------
% Conditions selection
% -------------------------------------------------------------------------
fprintf('<strong>Conditions selection...</strong>\n');
filepath = fileparts(mfilename('fullpath'));
load(sprintf('%s/../general/JOEI_generalDefinitions.mat', filepath), ...    % load general definitions
     'generalDefinitions');

condMark  = generalDefinitions.condMark(1, :);                              % extract condition identifiers
condNum   = generalDefinitions.condNum;

sel = listdlg('PromptString',' Select conditions...', ...                   % open the dialog window --> the user can select the conditions of interest
                'ListString', condMark, ...
                'ListSize', [220, 300] );

condMark  = condMark(sel);                                                  % keep selected condtitions for further use
condNum   = condNum(sel);

fprintf('You have selected the following conditions:\n');
cellfun(@(x) fprintf('%s, ', x), condMark, 'UniformOutput', false);         % show the identifiers of the selected conditions in the command window
fprintf('\b\b.\n\n');

clear generalDefinitions filepath

% -------------------------------------------------------------------------
% Frequency selection
% -------------------------------------------------------------------------
mode = 0;                                                                   % the mode variable shows which frequency and channel mode was selected.

fprintf('<strong>Frequency selection...</strong>\n');
selection = false;
while selection == false
  fprintf('Available options:\n');
  fprintf('[1] - Export the average over the selected frequencies\n');
  fprintf('[2] - Export the a single values for every selected frequency\n');
  x = input('Option: ');
  switch x
    case 1
      selection = true;
      fmode = 'average';
    case 2
      selection = true;
      fmode = 'singleFreq';
      mode  = mode + 1;
    otherwise
      selection = false;
      cprintf([1,0.5,0], 'Wrong input!\n');
  end
end

load([srcPath fileList{1}]);                                                % load data of first participant

freqNum   = data_pwelch.freq;
freqStr   = cellfun(@(x) sprintf('%.1fHz', x), ...                          % prepare cell array with all possible frequencies
                    num2cell(freqNum), 'UniformOutput', false);

sel = listdlg('PromptString',' Select frequencies of interest...', ...      % open the dialog window --> the user can select the frequencies of interest
                'ListString', freqStr, ...
                'ListSize', [220, 300] );

freqNum = freqNum(sel);                                                     % keep selected frequencies for further user
freqStr = freqStr(sel);

fprintf('\nYou have selected the following frequencies:\n');
cellfun(@(x) fprintf('%s, ', x), freqStr, 'UniformOutput', false);          % show the selected frequencies in the command window
fprintf('\b\b.\n\n');

clear x selection

% -------------------------------------------------------------------------
% Cluster specification
% -------------------------------------------------------------------------
fprintf('<strong>Cluster specification...</strong>\n');
selection = false;
while selection == false
  fprintf('Available options:\n');
  fprintf('[1] - Export the cluster average\n');
  fprintf('[2] - Export the values of single channels\n');
  x = input('Option: ');
  switch x
    case 1
      selection = true;
      cmode = 'cluster';
    case 2
      selection = true;
      cmode = 'singleChan';
      mode  = mode + 2;
    otherwise
      selection = false;
      cprintf([1,0.5,0], 'Wrong input!\n');
  end
end

labelOrig = data_pwelch.label;                                              % extract channel names

if strcmp(cmode, 'cluster')
  prompt_string = 'Select cluster members...';
elseif strcmp(cmode, 'singleChan')
  prompt_string = 'Select channels of interest...';
end

sel = listdlg('PromptString', prompt_string, ...                            % open the dialog window --> the user can select the channels of interest
                'ListString', labelOrig, ...
                'ListSize', [220, 300] );

label = labelOrig(sel);

fprintf('\nYou have selected the following channels:\n');
cellfun(@(x) fprintf('%s, ', x), label, 'UniformOutput', false);            % show the selected channels in the command window
fprintf('\b\b.\n\n');
              
clear data_pwelch numOfChan part selection x prompt_string sel

% -------------------------------------------------------------------------
% Identifier specification
% Generate xls file
% -------------------------------------------------------------------------
fprintf('<strong>Identifier specification...</strong>\n');
desPath = [path 'EEG_JOEI_results/PSD_export/general/' sessionStr '/'];     % destination path

if ~exist(desPath, 'dir')                                                   % generate session dir, if not exist
  mkdir(desPath);
end

template_file = [path 'EEG_JOEI_templates/' ...                             % template file
                  'general/Export_template.xls'];

selection = false;
while selection == false
  identifier = inputdlg(['Specify file identifier (use only letters '...
                         'and/or numbers):'], 'Identifier specification');
  if ~all(isstrprop(identifier{1}, 'alphanum'))                             % check if identifier is valid
    cprintf([1,0.5,0], ['Use only letters and or numbers for the file '...
                        'identifier\n']);
  else
    xlsFile = [desPath 'PSD_general_export_' identifier{1} '_' ...          % build filename
              sessionStr '.xls'];
    if exist(xlsFile, 'file')                                               % check if file already exists
      cprintf([1,0.5,0], 'A file with this identifier exists!');
      selection2 = false;
      while selection2 == false
        fprintf('\nDo you want to overwrite this existing file?\n');        % ask if existing file should be overwritten
        x = input('Select [y/n]: ','s');
        if strcmp('y', x)
          selection2 = true;
          selection = true;
          [~] = copyfile(template_file, xlsFile);                           % copy template to destination
          fprintf('\n');
        elseif strcmp('n', x)
          selection2 = true;
          fprintf('\n');
        else
          cprintf([1,0.5,0], 'Wrong input!\n');
          selection2 = false;
        end
      end
    else
      selection = true;
      [~] = copyfile(template_file, xlsFile);                               % copy template to destination
    end
  end
end

fprintf('Your destination file is:\n');
fprintf('%s\n\n', xlsFile);

clear desPath template_file path identifier selection selection2 x ...
      sessionStr

% -------------------------------------------------------------------------
% Generate table templates
% -------------------------------------------------------------------------
numOfTrials = length(condNum);
condMark    = cellfun(@(x) erase(x, ' '), condMark, 'UniformOutput', false);
numOfChan   = length(label);
numOfFreq   = length(freqNum);
tableLength = max([numOfChan, numOfFreq]);

cell_array      = cell(tableLength, 4);                                     % create info template                                 
cell_array(1:numOfChan,1) = label;
cell_array(1:numOfFreq,2) = freqStr;
cell_array{1,3} = cmode;
cell_array{1,4} = fmode;
Tinfo    = cell2table(cell_array);
if strcmp(cmode, 'cluster')
  Tinfo.Properties.VariableNames = {'cluster', 'frequencies', 'chanMode', 'freqMode'};
elseif strcmp(cmode, 'singleChan')
  Tinfo.Properties.VariableNames = {'channels', 'frequencies', 'chanMode', 'freqMode'};
end

switch mode                                                                 % generate data template
  case 0 % average & cluster                                                                   
    cell_array      = num2cell(NaN(numOfFiles, numOfTrials + 1));
    cell_array(:,1) = num2cell(participants);
    Tdata           = cell2table(cell_array);
    Tdata.Properties.VariableNames = ['participant' condMark];              % generate the headline
  case 1 % singleFreq & cluster
    cell_array      = num2cell(NaN(numOfFiles, numOfTrials * numOfFreq + 1));
    cell_array(:,1) = num2cell(participants);
    Tdata           = cell2table(cell_array);
    condMark        = repmat(condMark, numOfFreq, 1);                       % generate the headline
    condMark        = reshape(condMark,1,[]);
    freqStr         = repmat(freqStr, 1, numOfTrials);
    freqStr         = cellfun(@(x) strrep(x,'.','_'), freqStr, ...
                            'UniformOutput', false);
    headline        = cellfun(@(x,y) [x '_' y], condMark, freqStr, ...
                            'UniformOutput', false);
    Tdata.Properties.VariableNames = ['participant' headline];
  case 2 % average & singleChan
    cell_array      = num2cell(NaN(numOfFiles, numOfTrials * numOfChan + 1));
    cell_array(:,1) = num2cell(participants);
    Tdata           = cell2table(cell_array);
    condMark        = repmat(condMark, numOfChan, 1);                       % generate the headline
    condMark        = reshape(condMark,1,[]);
    label           = repmat(label, numOfTrials, 1)';
    headline        = cellfun(@(x,y) [x '_' y], condMark, label, ...
                            'UniformOutput', false);
    Tdata.Properties.VariableNames = ['participant' headline];
  case 3 % singelFreq & singleChan
    cell_array      = num2cell(NaN(numOfFiles, numOfTrials * numOfChan * numOfFreq + 1));
    cell_array(:,1) = num2cell(participants);
    Tdata           = cell2table(cell_array);
    condMark        = repmat(condMark, numOfChan * numOfFreq, 1);           % generate the headline
    condMark        = reshape(condMark,1,[]);
    label           = repmat(label', numOfFreq, 1);
    label           = reshape(label,1,[]);
    label           = repmat(label, 1, numOfTrials);
    freqStr         = repmat(freqStr, 1, numOfTrials * numOfChan);
    freqStr         = cellfun(@(x) strrep(x,'.','_'), freqStr, ...
                            'UniformOutput', false);
    headline        = cellfun(@(x,y,z) [x '_' y '_' z], condMark, ...
                            label, freqStr, 'UniformOutput', false);
    Tdata.Properties.VariableNames = ['participant' headline];
  otherwise
    error('Something weird happend! The mode variable has an unsupported value.\n'); 
end

clear cell_array passband condMark headline freqStr cmode fmode ...
      part_suffix part_prefix tableLength numOfPart

% -------------------------------------------------------------------------
% Import psd values into tables
% -------------------------------------------------------------------------
fprintf('<strong>Import of PSD values...</strong>\n\n');
f = waitbar(0,'Please wait...');

for part = 1:1:numOfFiles
  load([srcPath fileList{part}]);                                           % load data
  
  if any(~strcmp(data_pwelch.label, labelOrig))
    error(['Error with participant %d. The channels are not in the ' ...
            'correct order!\n'], participants(part));
  end

  for trl=1:1:numOfTrials
    waitbar(((part-1)*numOfTrials + trl)/(numOfFiles * numOfTrials), ...
                  f, 'Please wait...');
    loc_trl = ismember(data_pwelch.trialinfo, condNum(trl));
    if any(loc_trl)
      psdPart   = squeeze(data_pwelch.powspctrm(loc_trl, :, :));
      loc_freq  = ismember(data_pwelch.freq, freqNum);
      loc_chan  = ismember(data_pwelch.label, label);
      psdPart   = psdPart(loc_chan, loc_freq);
      
      switch mode
        case 0 % average & cluster
          psdPart = reshape(psdPart, [], 1);
          Tdata(part, trl + 1) = {nanmean(psdPart)};
        case 1 % singleFreq & cluster
          start = (trl - 1) * numOfFreq + 2;
          stop  = start + numOfFreq - 1;
          Tdata(part ,start:stop) = num2cell(nanmean(psdPart, 1));
        case 2 % average & singleChan
          start = (trl - 1) * numOfChan + 2;
          stop  = start + numOfChan - 1;
          Tdata(part ,start:stop) = num2cell(transpose(...
                                            nanmean(psdPart, 2)));
        case 3 % singelFreq & singleChan
          start = (trl - 1) * (numOfChan * numOfFreq) + 2;
          stop  = start + (numOfChan * numOfFreq) - 1;
          psdPart = transpose(psdPart);
          psdPart = reshape(psdPart,[],1);
          psdPart = transpose(psdPart);
          Tdata(part ,start:stop) = num2cell(psdPart);
      end
    end
  end

  clear data_pwelch
end

close(f);
clear f part numOfFiles srcPath fileList labelOrig participants trl ...
      loc_chan numOfTrials loc_trl condNum data_pwelch loc_freq start ...
      stop mode freqNum psdPart label row numOfChan numOfFreq

% -------------------------------------------------------------------------
% Export psd table into spreadsheet
% -------------------------------------------------------------------------
fprintf('<strong>Export of PSD table into a xls spreadsheet...</strong>\n');

writetable(Tinfo, xlsFile, 'Sheet', 'info');
writetable(Tdata, xlsFile, 'Sheet', 'data');

% -------------------------------------------------------------------------
% Clear workspace
% -------------------------------------------------------------------------
clear xlsFile Tdata Tinfo
