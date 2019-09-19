%% check if basic variables are defined
if ~exist('sessionStr', 'var')
  cfg           = [];
  cfg.subFolder = '02b_preproc1/';
  cfg.filename  = 'JOEI_p01_02b_preproc1';
  sessionStr    = sprintf('%03d', JOEI_getSessionNum( cfg ));               % estimate current session number
end

if ~exist('desPath', 'var')
  desPath = '/data/pt_0904/eegData/EEG_JOEI_processedData/';                % destination path for processed data
end

if ~exist('numOfPart', 'var')                                               % estimate number of participants in preprocessed data folder
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

%% part 3
% ICA decomposition
% Processing steps:
% 1. Concatenated preprocessed trials to a continuous stream
% 2. Detect and reject transient artifacts (200uV delta within 200 ms.
%    The window is shifted with 100 ms, what means 50 % overlapping.)
% 3. Concatenated cleaned data to a continuous stream
% 4. ICA decomposition

cprintf([0,0.6,0], '<strong>[3] - ICA decomposition</strong>\n');
fprintf('\n');

for i = numOfPart
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '02b_preproc1/');
  cfg.filename    = sprintf('JOEI_p%02d_02b_preproc1', i);
  cfg.sessionStr  = sessionStr;

  fprintf('<strong>Dyad %d</strong>\n', i);
  fprintf('Load preprocessed data...\n');
  JOEI_loadData( cfg );

  % Concatenated preprocessed trials to a continuous stream
  data_continuous = JOEI_concatData( data_preproc1 );

  clear data_preproc1
  fprintf('\n');

  % Detect and reject transient artifacts (200uV delta within 200 ms.
  % The window is shifted with 100 ms, what means 50 % overlapping.)
  fprintf('<strong>Search for artifacts in all electrodes except F9, F10, V1 and V2...\n</strong>');
  cfg             = [];
  cfg.channel     = {'all', '-F9', '-F10', '-V1' '-V2', '-EOGV', ...        % use all channels for transient artifact detection expect EOGV, EOGH and REF
                      '-EOGH', '-REF'};
  cfg.method      = 'range';
  cfg.deadsegs   = 'no';                                                    % detection of segments in which at least one channel is dead or in saturation
  cfg.sliding     = 'no';
  cfg.continuous  = 'yes';
  cfg.trllength   = 200;                                                    % minimal subtrial length: 200 msec
  cfg.overlap     = 50;                                                     % 50 % overlapping
  cfg.range       = 200;                                                    % 200 µV

  cfg_autoart1    = JOEI_autoArtifact(cfg, data_continuous);

  fprintf('\n<strong>Search for artifacts in F9, F10, V1 and V2...\n</strong>');
  cfg             = [];
  cfg.channel     = {'V1', 'V2', 'F9', 'F10'};                              % use only F9, F10, V1 and V2
  cfg.method      = 'range';
  cfg.deadsegs   = 'no';                                                    % detection of segments in which at least one channel is dead or in saturation
  cfg.sliding     = 'no';
  cfg.continuous  = 'yes';
  cfg.trllength   = 200;                                                    % minimal subtrial length: 200 msec
  cfg.overlap     = 50;                                                     % 50 % overlapping
  cfg.range       = 400;                                                    % 400 µV

  cfg_autoart2    = JOEI_autoArtifact(cfg, data_continuous);

  fprintf('\n<strong>Merge estimated artifacts...\n</strong>');
  cfg_autoart     = JOEI_mergeThArtResults(cfg_autoart1, cfg_autoart2);
  clear cfg_autoart1 cfg_autoart2

  cfg           = [];
  cfg.artifact  = cfg_autoart;
  cfg.reject    = 'partial';                                                % partial rejection

  data_cleaned  = JOEI_rejectArtifacts(cfg, data_continuous);

  clear data_continuous cfg_autoart
  fprintf('\n');

  % Concatenated cleaned data to a continuous stream
  data_cleaned = JOEI_concatData( data_cleaned );

  % ICA decomposition
  cfg               = [];
  cfg.channel       = {'all', '-EOGV', '-EOGH', '-REF'};                    % use all channels for EOG decomposition expect EOGV, EOGH and REF
  cfg.numcomponent  = 'all';

  data_icacomp      = JOEI_ica(cfg, data_cleaned);
  fprintf('\n');

  % export the determined ica components in a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '03_icacomp/');
  cfg.filename    = sprintf('JOEI_p%02d_03_icacomp', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');

  fprintf('The ica components of dyad %d will be saved in:\n', i);
  fprintf('%s ...\n', file_path);
  JOEI_saveData(cfg, 'data_icacomp', data_icacomp);
  fprintf('Data stored!\n\n');
  clear data_icacomp data_cleaned
end

%% clear workspace
clear file_path cfg sourceList numOfSources i j
