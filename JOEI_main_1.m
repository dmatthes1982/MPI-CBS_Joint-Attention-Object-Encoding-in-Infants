%% check if basic variables are defined
if ~exist('sessionStr', 'var')
  cfg           = [];
  cfg.subFolder = '01a_raw/';
  cfg.filename  = 'JOEI_p01_01a_raw';
  sessionNum    = JOEI_getSessionNum( cfg );
  if sessionNum == 0
    sessionNum = 1;
  end
  sessionStr    = sprintf('%03d', sessionNum);                              % estimate current session number
end

if ~exist('srcPath', 'var')
  srcPath = '/data/pt_01904/eegData/EEG_JOEI_rawData/';                     % source path to raw data
end

if ~exist('desPath', 'var')
  desPath = '/data/pt_01904/eegData/EEG_JOEI_processedData/';               % destination path for processed data
end

if ~exist('numOfPart', 'var')                                               % estimate number of participants in raw data folder
  sourceList    = dir([srcPath, '/*.vhdr']);
  sourceList    = struct2cell(sourceList);
  sourceList    = sourceList(1,:);
  numOfSources  = length(sourceList);
  numOfPart     = zeros(1, numOfSources);

  for i=1:1:numOfSources
    numOfPart(i)  = sscanf(sourceList{i}, 'JOEI_%d.vhdr');
  end
end

%% part 1
% 1. import data from brain vision eeg files and bring it into an order
% 2. select corrupted channels 
% 3. repair corrupted channels

cprintf([0,0.6,0], '<strong>[1] - Data import and repairing of bad channels</strong>\n');
fprintf('\n');

selection = false;
while selection == false
  cprintf([0,0.6,0], 'Do you want to import the data without a pre-stimulus offset? (DEFAULT)\n');
  x = input('Select [y/n]: ','s');
  if strcmp('y', x)
    selection = true;
    prestim = 0;
  elseif strcmp('n', x)
    selection = true;
    prestim = [];
  else
    selection = false;
  end
end
fprintf('\n');

if isempty(prestim)
  selection = false;                                                        % specify a pre-stimulus offset
  while selection == false
    cprintf([0,0.6,0], 'Specify a pre-stimulus offset between 0 and 30 seconds!\n', i);
    x = input('Value: ');
    if isnumeric(x)
      if (x < 0 || x > 30)
        cprintf([1,0.5,0], 'Wrong input!\n');
        selection = false;
      else
        prestim = x;
        selection = true;
      end
    else
      cprintf([1,0.5,0], 'Wrong input!\n');
      selection = false;
    end
  end
fprintf('\n');
end

selection = false;
while selection == false
  cprintf([0,0.6,0], 'Select channels, which are NOT of interest?\n');
  fprintf('[1] - import all channels\n');
  fprintf('[2] - reject T7, T8, PO9, PO10, P7, P8, TP10\n');
  fprintf('[3] - reject specific selection\n');
  x = input('Option: ');

  switch x
    case 1
      selection = true;
      noichan = [];
      noichanStr = {'---'};
    case 2
      selection = true;
      noichan = {'T7', 'T8', 'PO9', 'PO10', 'P7', 'P8', 'TP10'};
      noichanStr = {'-T7,-T8,-PO9,-PO10,-P7,-P8,-TP10'};
    case 3
      selection = true;
      cprintf([0,0.6,0], '\nAvailable channels will be determined. Please wait...\n');

      load('layouts/mpi_customized_acticap32.mat', 'lay')
      label = lay.label(1:end-2);
      loc   = ~ismember(label, {'V1', 'V2', 'F9', 'F10'});                  % remove EOG-related electrodes from options to avoid errors
      label = label(loc);

      sel = listdlg('PromptString', ...                                     % open the dialog window --> the user can select the channels wich are not of interest
              'Which channels are NOT of interest...', ...
              'ListString', label, ...
              'ListSize', [220, 300] );

      noichan = label(sel)';
      channels = {strjoin(noichan,',')};

      fprintf('You have unselected the following channels:\n');
      fprintf('%s\n', channels{1});

      noichanStr = cellfun(@(x) strcat('-', x), noichan, ...
                          'UniformOutput', false);
      noichanStr = {strjoin(noichanStr,',')};
      clear channels label loc sel
    otherwise
      cprintf([1,0.5,0], 'Wrong input!\n');
  end
end
fprintf('\n');

% Create settings file if not existing
settings_file = [desPath '00_settings/' ...
                  sprintf('settings_%s', sessionStr) '.xls'];
if ~(exist(settings_file, 'file') == 2)                                     % check if settings file already exist
  cfg = [];
  cfg.desFolder   = [desPath '00_settings/'];
  cfg.type        = 'settings';
  cfg.sessionStr  = sessionStr;

  JOEI_createTbl(cfg);                                                       % create settings file
end

% Load settings file
T = readtable(settings_file);
warning off;
T.participant(numOfPart)  = numOfPart;
T.prestim(numOfPart)      = prestim;
T.noiChan(numOfPart)      = noichanStr;
warning on;

%% import data from brain vision eeg files %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = numOfPart
  cfg               = [];
  cfg.path          = srcPath;
  cfg.part          = i;
  cfg.noichan       = noichan;
  cfg.continuous    = 'no';
  cfg.prestim       = prestim;
  cfg.rejectoverlap = 'yes';
  
  fprintf('<strong>Import data of participant %d</strong> from: %s ...\n', i, cfg.path);
  ft_info off;
  [data_raw, cfg_events] = JOEI_importDataset( cfg );
  ft_info on;

  % export the raw data in a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '01a_raw/');
  cfg.filename    = sprintf('JOEI_p%02d_01a_raw', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');

  fprintf('The RAW data of participant %d will be saved in:\n', i);
  fprintf('%s ...\n', file_path);
  JOEI_saveData(cfg, 'data_raw', data_raw);
  fprintf('Data stored!\n');
  clear data_raw

  % export the look events in a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '01b_events/');
  cfg.filename    = sprintf('JOEI_p%02d_01b_events', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');

  fprintf('The look events of participant %d will be saved in:\n', i);
  fprintf('%s ...\n', file_path);
  JOEI_saveData(cfg, 'cfg_events', cfg_events);
  fprintf('Data stored!\n\n');
  clear cfg_events
end

fprintf('<strong>Repairing of corrupted channels</strong>\n\n');

%% repairing of corrupted channels %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = numOfPart
  fprintf('<strong>Participant %d</strong>\n\n', i);
  
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '01a_raw/');
  cfg.filename    = sprintf('JOEI_p%02d_01a_raw', i);
  cfg.sessionStr  = sessionStr;
    
  fprintf('Load raw data...\n');
  JOEI_loadData( cfg );
  
  % concatenated raw trials to a continuous stream
  data_continuous = JOEI_concatData( data_raw );

  fprintf('\n');

  % detect noisy channels automatically
  data_noisy = JOEI_estNoisyChan( data_continuous );

  fprintf('\n');

  % select corrupted channels
  data_badchan = JOEI_selectBadChan( data_continuous, data_noisy );
  clear data_noisy

  % export the bad channels in a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '01c_badchan/');
  cfg.filename    = sprintf('JOEI_p%02d_01c_badchan', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');

  fprintf('Bad channels of participant %d will be saved in:\n', i); 
  fprintf('%s ...\n', file_path);
  JOEI_saveData(cfg, 'data_badchan', data_badchan);
  fprintf('Data stored!\n\n');
  clear data_continuous
  
  % add bad labels of bad channels to the settings file
  if isempty(data_badchan.badChan)
    badChan = {'---'};
  else
    badChan = {strjoin(data_badchan.badChan,',')};
  end
  warning off;
  T.badChan(i) = badChan;
  warning on;
  
  % repair corrupted channels
  data_repaired = JOEI_repairBadChan( data_badchan, data_raw );
  
  % export the bad channels in a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '01d_repaired/');
  cfg.filename    = sprintf('JOEI_p%02d_01d_repaired', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');

  fprintf('Repaired raw data of participant %d will be saved in:\n', i); 
  fprintf('%s ...\n', file_path);
  JOEI_saveData(cfg, 'data_repaired', data_repaired);
  fprintf('Data stored!\n\n');
  clear data_repaired data_raw data_badchan 
end

% store settings table
delete(settings_file);
writetable(T, settings_file);

%% clear workspace
clear file_path cfg sourceList numOfSources i T badChan prestim ...
      settings_file lay noichan noichanStr
