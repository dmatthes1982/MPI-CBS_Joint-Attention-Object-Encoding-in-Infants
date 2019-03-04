%% check if basic variables are defined
if ~exist('sessionStr', 'var')
  cfg           = [];
  cfg.subFolder = '01d_repaired/';
  cfg.filename  = 'JOEI_p01_01d_repaired';
  sessionStr    = sprintf('%03d', JOEI_getSessionNum( cfg ));               % estimate current session number
end

if ~exist('desPath', 'var')
  desPath = '/data/pt_01904/eegData/EEG_JOEI_processedDataOld/';            % destination path for processed data  
end

if ~exist('numOfPart', 'var')                                               % estimate number of participants in repaired data folder
  sourceList    = dir([strcat(desPath, '01d_repaired/'), ...
                       strcat('*_', sessionStr, '.mat')]);
  sourceList    = struct2cell(sourceList);
  sourceList    = sourceList(1,:);
  numOfSources  = length(sourceList);
  numOfPart     = zeros(1, numOfSources);

  for i=1:1:numOfSources
    numOfPart(i)  = sscanf(sourceList{i}, ...
                    strcat('JOEI_p%d_01d_repaired_', sessionStr, '.mat'));
  end
end

%% part 2
% preprocess the raw data
% export the preprocessed data into a *.mat file

cprintf([0,0.6,0], '<strong>[2] - Preprocessing, filtering, re-referencing</strong>\n');
fprintf('\n');

selection = false;
while selection == false
  cprintf([0,0.6,0], 'Please select sampling rate for preprocessing:\n');
  fprintf('[1] - 500 Hz (original sampling rate)\n');
  fprintf('[2] - 250 Hz (downsampling factor 2)\n');
  fprintf('[3] - 125 Hz (downsampling factor 4)\n');
  x = input('Option: ');

  switch x
    case 1
      selection = true;
      samplingRate = 500;
    case 2
      selection = true;
      samplingRate = 250;
    case 3
      selection = true;
      samplingRate = 125;
    otherwise
      cprintf([1,0.5,0], 'Wrong input!\n');
  end
end
fprintf('\n');

% determine available channels
fprintf('Determine available channels...\n');
cfg             = [];
cfg.srcFolder   = strcat(desPath, '01d_repaired/');
cfg.filename    = sprintf('JOEI_p%02d_01d_repaired', numOfPart(1));
cfg.sessionStr  = sessionStr;

JOEI_loadData( cfg );
mastoid = ismember('TP10', data_repaired.label);
clear data_repaired;

% select favoured reference
selection = false;
while selection == false
  cprintf([0,0.6,0], 'Please select favoured reference:\n');
  fprintf('[1] - Common average reference\n');
  if(mastoid == true)
    fprintf('[2] - Linked mastoid (''TP9'', ''TP10'')\n');
  end
  x = input('Option: ');

  if x == 1
     selection = true;
     refchannel = {'all', '-V1', '-V2'};
     reference = {'CAR'};
  elseif x == 2 && mastoid == true
     selection = true;
     refchannel = 'TP10';
     reference = {'LM'};
  else
    cprintf([1,0.5,0], 'Wrong input!\n\n');
  end
end
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
file_path = [desPath '00_settings/' sprintf('settings_%s', sessionStr) '.xls'];
if ~(exist(file_path, 'file') == 2)                                         % check if settings file already exist
  cfg = [];
  cfg.desFolder   = [desPath '00_settings/'];
  cfg.type        = 'settings';
  cfg.sessionStr  = sessionStr;
  
  JOEI_createTbl(cfg);                                                      % create settings file
end

T = readtable(file_path);                                                   % update settings table
warning off;
T.fsample(numOfPart) = samplingRate;
T.reference(numOfPart) = reference;
T.bandpass(numOfPart) = bandpass;
warning on;
delete(file_path);
writetable(T, file_path);

for i = numOfPart
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '01d_repaired/');
  cfg.filename    = sprintf('JOEI_p%02d_01d_repaired', i);
  cfg.sessionStr  = sessionStr;
  
  fprintf('<strong>Participant %d</strong>\n', i);
  fprintf('Load repaired raw data...\n');
  JOEI_loadData( cfg );
  
  cfg                   = [];
  cfg.bpfreq            = bpRange;
  cfg.bpfilttype        = 'but';
  cfg.bpinstabilityfix  = 'split';
  cfg.samplingRate      = samplingRate;
  cfg.refchannel        = refchannel;
  
  ft_info off;
  data_preproc = JOEI_preprocessing( cfg, data_repaired);
  ft_info on;
  
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '02_preproc/');
  cfg.filename    = sprintf('JOEI_p%02d_02_preproc', i);
  cfg.sessionStr  = sessionStr;
  
  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');

  fprintf('The preprocessed data of participant %d will be saved in:\n', i); 
  fprintf('%s ...\n', file_path);
  JOEI_saveData(cfg, 'data_preproc', data_preproc);
  fprintf('Data stored!\n\n');
  clear data_preproc data_repaired
end

%% clear workspace
clear file_path cfg sourceList numOfSources i selection samplingRate x ...
      refchannel reference T bandpass bpRange mastoid
