%% check if basic variables are defined
if ~exist('sessionStr', 'var')
  cfg           = [];
  cfg.subFolder = '02b_preproc1/';
  cfg.filename  = 'JOEI_p01_02b_preproc1';
  sessionStr    = sprintf('%03d', JOEI_getSessionNum( cfg ));               % estimate current session number
end

if ~exist('desPath', 'var')
  desPath = '/data/pt_01904/eegData/EEG_JOEI_processedData/';               % destination path for processed data
end

if ~exist('numOfPart', 'var')                                               % estimate number of participants in eyecor data folder
  sourceList    = dir([strcat(desPath, '02b_preproc1/'), ...
                       strcat('*_', sessionStr, '.mat')]);
  sourceList    = struct2cell(sourceList);
  sourceList    = sourceList(1,:);
  numOfSources  = length(sourceList);
  numOfPart     = zeros(1, numOfSources);

  for i=1:1:numOfSources
    numOfPart(i)  = sscanf(sourceList{i}, ...
                    strcat('JOEI_p%d_02b_preproc1_', sessionStr, '.mat'));
  end
end

%% part 4
% 1. Select bad ICA components by using the ft_icabrowser function
% 2. Clean data
% 3. Recovery of bad channels
% 4. Re-referencing

cprintf([0,0.6,0], '<strong>Preproc II: ICA based data correction, bad channel recovery, re-referencing</strong>\n');
fprintf('\n');

% determine available channels
fprintf('Determine available channels...\n');
cfg             = [];
cfg.srcFolder   = strcat(desPath, '02b_preproc1/');
cfg.filename    = sprintf('JOEI_p%02d_02b_preproc1', numOfPart(1));
cfg.sessionStr  = sessionStr;

JOEI_loadData( cfg );
mastoid = ismember('TP10', data_preproc1.label);
clear data_preproc1;

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

% Create settings if not existing
settings_file = [desPath '00_settings/' ...
                  sprintf('settings_%s', sessionStr) '.xls'];
if ~(exist(settings_file, 'file') == 2)                                     % check if settings file already exist
  cfg = [];
  cfg.desFolder   = [desPath '00_settings/'];
  cfg.type        = 'settings';
  cfg.sessionStr  = sessionStr;

  JOEI_createTbl(cfg);                                                      % create settings file
end

T = readtable(settings_file);                                               % update settings table
warning off;
T.reference(numOfPart)    = reference;
warning on;

for i = numOfPart
  fprintf('<strong>Participant %d</strong>\n\n', i);

  % store settings table
  delete(settings_file);
  writetable(T, settings_file);

  % load basic bandpass filtered data
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '02b_preproc1/');
  cfg.filename    = sprintf('JOEI_p%02d_02b_preproc1', i);
  cfg.sessionStr  = sessionStr;

  fprintf('Load bandpass filtered data...\n');
  JOEI_loadData( cfg );

  %% Recovery of bad channels %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  fprintf('<strong>Bad channel recovery</strong>\n\n');

  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '02a_badchan/');
  cfg.filename    = sprintf('JOEI_p%02d_02a_badchan', i);
  cfg.sessionStr  = sessionStr;

  fprintf('Load bad channels specification...\n');
  JOEI_loadData( cfg );

  data_preproc1 = JOEI_repairBadChan( data_badchan, data_preproc1 );
  clear data_badchan

  %% re-referencing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  fprintf('<strong>Rereferencing</strong>\n');

  cfg                   = [];
  cfg.refchannel        = refchannel;

  ft_info off;
  data_preproc2 = JOEI_reref( cfg, data_preproc1);
  ft_info on;

  cfg             = [];
  cfg.desFolder   = strcat(desPath, '04b_preproc2/');
  cfg.filename    = sprintf('JOEI_p%02d_04b_preproc2', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');

  fprintf('The clean and re-referenced data of dyad %d will be saved in:\n', i);
  fprintf('%s ...\n', file_path);
  JOEI_saveData(cfg, 'data_preproc2', data_preproc2);
  fprintf('Data stored!\n\n');
  clear data_preproc2 data_preproc1
end

%% clear workspace
clear file_path cfg sourceList numOfSources i selection x T ...
      settings_file ICAcomp reference refchannel mastoid
