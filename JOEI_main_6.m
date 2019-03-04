%% check if basic variables are defined
if ~exist('sessionStr', 'var')
  cfg           = [];
  cfg.subfolder = '04b_preproc2';
  cfg.filename  = 'JOEI_p01_04b_preproc2';
  sessionStr    = sprintf('%03d', JOEI_getSessionNum( cfg ));               % estimate current session number
end

if ~exist('desPath', 'var')
  desPath = '/data/pt_01904/eegData/EEG_JOEI_processedData/';               % destination path for processed data
end

if ~exist('numOfPart', 'var')                                               % estimate number of participants in eyecor data folder
  sourceList    = dir([strcat(desPath, '04b_preproc2/'), ...
                       strcat('*_', sessionStr, '.mat')]);
  sourceList    = struct2cell(sourceList);
  sourceList    = sourceList(1,:);
  numOfSources  = length(sourceList);
  numOfPart     = zeros(1, numOfSources);

  for i=1:1:numOfSources
    numOfPart(i)  = sscanf(sourceList{i}, ...
                    strcat('JOEI_p%d_04b_preproc2_', sessionStr, '.mat'));
  end
end

%% part 6
% Calculate the power spectrum of the preprocessed data

cprintf([0,0.6,0], '<strong>[6] - Power analysis (pWelch)</strong>\n');
fprintf('\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Calculation of power spectrum using Welch's method (pWelch)
choise = false;
while choise == false
  cprintf([0,0.6,0], 'Should rejection of detected artifacts be applied before power estimation?\n');
  x = input('Select [y/n]: ','s');
  if strcmp('y', x)
    choise = true;
    artifactRejection = true;
  elseif strcmp('n', x)
    choise = true;
    artifactRejection = false;
  else
    choise = false;
  end
end
fprintf('\n');

selection = false;
while selection == false
  cprintf([0,0.6,0], 'Please select segmentation size for pwelch estimation:\n');
  fprintf('[1] - 1 sec \n');
  fprintf('[2] - 2 sec \n');
  y = input('Option: ');

  switch y
    case 1
      selection = true;
      seglength = 1;
    case 2
      selection = true;
      seglength = 2;
    otherwise
      cprintf([1,0.5,0], 'Wrong input!\n');
  end
end
fprintf('\n');

selection = false;
while selection == false
  cprintf([0,0.6,0], 'Please select segmentation overlap for pwelch estimation:\n');
  fprintf('[1] - 0.50 %%\n');
  fprintf('[2] - 0.75 %%\n');
  if( seglength == 2 )
    fprintf('[3] - 0.875 %%\n');
  end
  y = input('Option: ');

  if y == 1
    selection = true;
    overlap = 0.5;
  elseif y == 2
    selection = true;
    overlap = 0.75;
  elseif y == 3 && seglength == 2
    selection = true;
    overlap = 0.875;
  else
    cprintf([1,0.5,0], 'Wrong input!\n\n');
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
T.artRejectPow(numOfPart) = { x };
T.powSeglength(numOfPart) = seglength;
T.powOverlap(numOfPart)   = overlap;
warning on;
delete(file_path);
writetable(T, file_path);

for i = numOfPart
  fprintf('<strong>Participant %d</strong>\n\n', i);

  % Load preprocessed data
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '04b_preproc2/');
  cfg.filename    = sprintf('JOEI_p%02d_04b_preproc2', i);
  cfg.sessionStr  = sessionStr;

  fprintf('Load preprocessed data...\n');
  JOEI_loadData( cfg );

  % Load look event specifications
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '01b_events/');
  cfg.filename    = sprintf('JOEI_p%02d_01b_events', i);
  cfg.sessionStr  = sessionStr;

  fprintf('Load look event specifications...\n\n');
  JOEI_loadData( cfg );

  % Create meta conditions
  cfg           = [];
  cfg.event     = 'infObj';
  cfg.eventSpec = cfg_events;

  data_infObj   = JOEI_createMetaCond(cfg, data_preproc2);

  cfg.event     = 'mGaze';

  data_mGaze    = JOEI_createMetaCond(cfg, data_preproc2);

  cfg.event     = 'mObj';

  data_mObj     = JOEI_createMetaCond(cfg, data_preproc2);

  % Unify datasets
  cfg = [];
  cfg.showcallinfo = 'no';

  ft_info off;
  fprintf('Append the meta condition datasets to the initial dataset...\n\n');
  data_preproc2  = ft_appenddata(cfg, data_preproc2, data_infObj, ...
                                      data_mGaze, data_mObj);
  ft_info on;

  clear data_infObj data_mGaze data_mObj cfg_events

  % Segmentation of conditions in segments of x seconds with yy percent
  % overlapping
  cfg          = [];
  cfg.length   = seglength;                                                 % window length
  cfg.overlap  = overlap;

  fprintf('<strong>Segmentation of preprocessed data.</strong>\n');
  data_preproc2 = JOEI_segmentation( cfg, data_preproc2 );

  numOfAllSeg = JOEI_numOfSeg( data_preproc2 );                             % estimate number of segments for each existing condition
  
  fprintf('\n');

  % Load artifact definitions
  if artifactRejection == true
    cfg             = [];
    cfg.srcFolder   = strcat(desPath, '05b_allart/');
    cfg.filename    = sprintf('JOEI_p%02d_05b_allart', i);
    cfg.sessionStr  = sessionStr;

    file_path = strcat(cfg.srcFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
    if ~isempty(dir(file_path))
      fprintf('Loading %s ...\n', file_path);
      JOEI_loadData( cfg );
      artifactAvailable = true;
    else
      fprintf('File %s is not existent,\n', file_path);
      fprintf('Artifact rejection is not possible!\n');
      artifactAvailable = false;
    end
  fprintf('\n');
  end

  % Artifact rejection
  if artifactRejection == true
    if artifactAvailable == true
      cfg           = [];
      cfg.artifact  = cfg_allart;
      cfg.reject    = 'complete';
      cfg.target    = 'single';

      fprintf('<strong>Artifact Rejection with preprocessed data.</strong>\n');
      data_preproc2 = JOEI_rejectArtifacts(cfg, data_preproc2);
      fprintf('\n');
    end

    clear cfg_allart
  end

  numOfGoodSeg = JOEI_numOfSeg( data_preproc2);                             % estimate number of remaining segments (after artifact rejection) for each existing condition
  
  % Estimation of power spectrum
  cfg         = [];
  cfg.foi     = 1/seglength:1/seglength:50;                                 % frequency of interest

  data_preproc2             = JOEI_pWelch( cfg, data_preproc2 );            % calculate power spectrum using Welch's method
  data_pwelch               = data_preproc2;                                % to save need of RAM
  data_pwelch.numOfAllSeg   = numOfAllSeg;                                  % add number of segments of each existing condition
  data_pwelch.numOfGoodSeg  = numOfGoodSeg;                                 % add number of clean segments of each existing condition
  clear data_preproc2

  % export power spectrum into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '06a_pwelch/');
  cfg.filename    = sprintf('JOEI_p%02d_06a_pwelch', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');

  fprintf('Power spectrum of participant %d will be saved in:\n', i);
  fprintf('%s ...\n', file_path);
  JOEI_saveData(cfg, 'data_pwelch', data_pwelch);
  fprintf('Data stored!\n\n');
  clear data_pwelch
end

%% clear workspace
clear file_path cfg sourceList numOfSources i choise tfr pwelch T ...
      artifactRejection artifactAvailable overlap x y numOfAllSeg ...
      numOfGoodSeg seglength
