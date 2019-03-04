%% check if basic variables are defined
if ~exist('sessionStr', 'var')
  cfg           = [];
  cfg.subFolder = '01a_raw/';
  cfg.filename  = 'JOEI_p01_01a_raw';
  sessionStr    = sprintf('%03d', JOEI_getSessionNum( cfg ));               % estimate current session number
end

if ~exist('desPath', 'var')
  desPath = '/data/pt_01904/eegData/EEG_JOEI_processedData/';               % destination path for processed data
end

if ~exist('numOfPart', 'var')                                               % estimate number of participants in repaired data folder
  sourceList    = dir([strcat(desPath, '01a_raw/'), ...
                       strcat('*_', sessionStr, '.mat')]);
  sourceList    = struct2cell(sourceList);
  sourceList    = sourceList(1,:);
  numOfSources  = length(sourceList);
  numOfPart     = zeros(1, numOfSources);

  for i=1:1:numOfSources
    numOfPart(i)  = sscanf(sourceList{i}, ...
                    strcat('JOEI_p%d_01a_raw_', sessionStr, '.mat'));
  end
end

%% part 2
% 1. select bad/noisy channels
% 2. filter the good channels (basic bandpass filtering)

cprintf([0,0.6,0], '<strong>[2] - Preproc I: bad channel detection, filtering</strong>\n');
fprintf('\n');

selection = false;
while selection == false
  cprintf([0,0.6,0], 'Do want to use the default bandpass (1...48 Hz) for preprocessing?\n');
  x = input('Select [y/n]: ','s');
  if strcmp('y', x)
    selection = true;
    bpRange = [1 48];
    bandpass = {'[1 48]'};
  elseif strcmp('n', x)
    selection = true;
    bpRange = [];
  else
    selection = false;
  end
end

if isempty(bpRange)
  selection = false;
  while selection == false
    cprintf([0,0.6,0], '\nDefine your specific preprocessing bandpass.\n');
    cprintf([0,0.6,0], 'Put lower and upper cutoff frequencies in squared brackets (i.e. [1 48]).\n');
    cprintf([0,0.6,0], 'Supported range: 0.3 ... 48 Hz\n');
    x = input('Bandpass specification: ');

    if ~isnumeric(x)
      cprintf([1,0.5,0], 'Wrong input! It is not numeric.\n');
    else
      selection = true;
      if x(1) < 0.3                                                         % lower cutoff frequency < 0.3 Hz
        cprintf([1,0.5,0], 'Wrong input! Lower cutoff frequency is below 0.3 Hz.\n');
        selection = false;
      end

      if x(end) > 48                                                        % upper cutoff frequency > 48 Hz
        cprintf([1,0.5,0], 'Wrong input! Upper cutoff frequency is over 48 Hz.\n');
        selection = false;
      end

      if x(1) >= x(end)                                                     % lower cutoff frequency >= upper cutoff frequency
        cprintf([1,0.5,0], 'Wrong input! Upper cutoff frequency is smaller than the lower one.\n');
        selection = false;
      end

      if numel(x) ~= 2                                                      % more or less than two values specified
        cprintf([1,0.5,0], 'Wrong input! More or less than two values specified.\n');
        selection = false;
      end

      if selection == true
        bpRange = x;
        bandpass = {['[' num2str(bpRange) ']']};
      end
    end
  end
end
fprintf('\n');

% Write selected settings to settings file
settings_file = [desPath '00_settings/' sprintf('settings_%s', sessionStr) '.xls'];
if ~(exist(settings_file, 'file') == 2)                                     % check if settings file already exist
  cfg = [];
  cfg.desFolder   = [desPath '00_settings/'];
  cfg.type        = 'settings';
  cfg.sessionStr  = sessionStr;
  
  JOEI_createTbl(cfg);                                                      % create settings file
end

T = readtable(settings_file);                                               % update settings table
warning off;
T.bandpass(numOfPart) = bandpass;
warning on;
delete(settings_file);
writetable(T, settings_file);

for i = numOfPart
  fprintf('<strong>Participant %d</strong>\n\n', i);

  %% selection of corrupted channels %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  fprintf('<strong>Selection of corrupted channels</strong>\n\n');

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
  cfg.desFolder   = strcat(desPath, '02a_badchan/');
  cfg.filename    = sprintf('JOEI_p%02d_02a_badchan', i);
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

  % store settings table
  delete(settings_file);
  writetable(T, settings_file);

  %% basic bandpass filtering of good channels %%%%%%%%%%%%%%%%%%%%%%%%%%%%
  fprintf('<strong>Basic preprocessing of good channels</strong>\n');
  
  cfg                   = [];
  cfg.bpfreq            = bpRange;
  cfg.bpfilttype        = 'but';
  cfg.bpinstabilityfix  = 'split';
  cfg.badChan           = data_badchan.badChan';
  
  ft_info off;
  data_preproc1 = JOEI_preprocessing( cfg, data_raw);
  ft_info on;
  
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '02b_preproc1/');
  cfg.filename    = sprintf('JOEI_p%02d_02b_preproc1', i);
  cfg.sessionStr  = sessionStr;
  
  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');

  fprintf('The preprocessed data of participant %d will be saved in:\n', i); 
  fprintf('%s ...\n', file_path);
  JOEI_saveData(cfg, 'data_preproc1', data_preproc1);
  fprintf('Data stored!\n\n');
  clear data_preproc1 data_raw data_badchan
end

%% clear workspace
clear file_path cfg sourceList numOfSources i selection x T bandpass ...
      bpRange settings_file badChan
