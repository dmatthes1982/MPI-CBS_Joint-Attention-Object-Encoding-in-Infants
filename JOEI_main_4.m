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

% select ICA-based artifact correction
selection = false;
while selection == false
  cprintf([0,0.6,0], 'Do want to use run a  ICA-based artifact correction?\n');
  x = input('Select [y/n]: ','s');
  if strcmp('y', x)
    selection = true;
    icacorr 	= true;
  elseif strcmp('n', x)
    selection = true;
    icacorr 	= false;
  else
    selection = false;
  end
end
if icacorr == true
  tmpPath = strcat(desPath, '03_icacomp/');
  file_path = strcat(tmpPath, 'JOEI_p*_03_icacomp_', sessionStr, '.mat');

  fileList    = dir(file_path);
  fileList    = struct2cell(fileList);
  fileList    = fileList(1,:);
  numOfFiles  = length(fileList);
  numOfICA    = zeros(1, numOfFiles);

  for i=1:1:numOfFiles
    numOfICA(i) = sscanf(fileList{i}, ...
                    strcat('JOEI_p%d_03_icacomp_', sessionStr, '.mat'));
  end

  if ~all(ismember(numOfPart, numOfICA))
    cprintf([1,0.5,0], ['\nICA-based artifact correction is not possible '...
           'for all participants. Hence, it will be '...
           'skipped completely. \nPlease run Part ''[3] - '...
           'ICA decomposition'' first.\n\n']);
    quitproc = true;
    clear i icacorr mastoid numOfICA refchannel reference tmpPath ...
          file_path fileList cfg numOfFiles
    return;
  else
    quitproc = false;
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

  %% ICA-based artifact correction %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if(icacorr == true)
    fprintf('<strong>ICA-based artifact correction</strong>\n\n');

    cfg             = [];
    cfg.srcFolder   = strcat(desPath, '03_icacomp/');
    cfg.filename    = sprintf('JOEI_p%02d_03_icacomp', i);
    cfg.sessionStr  = sessionStr;

    fprintf('Load ICA result...\n');
    JOEI_loadData( cfg );

    % Select ICA components which are related to noice, muscle and eog
    % artifacts
    data_badcomp    = JOEI_selectBadComp(data_icacomp);

    clear data_icacomp
    fprintf('\n');

    % export the selected ICA components and the unmixing matrix into
    % a *.mat file
    cfg             = [];
    cfg.desFolder   = strcat(desPath, '04a_badcomp/');
    cfg.filename    = sprintf('JOEI_p%02d_04a_badcomp', i);
    cfg.sessionStr  = sessionStr;

    file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                       '.mat');

    fprintf(['The artifact related components and the unmixing matrix '...
              'of participant %d will be saved in:\n'], i);
    fprintf('%s ...\n', file_path);
    JOEI_saveData(cfg, 'data_badcomp', data_badcomp);
    fprintf('Data stored!\n\n');

    % add selected ICA components to the settings file
    if isempty(data_badcomp.elements)
      ICAcomp = {'---'};
    else
      ICAcomp = {strjoin(data_badcomp.elements,',')};
    end
    warning off;
    T.ICAcomp(i) = ICAcomp;
    warning on;

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

    % correct EEG signals
    data_corrected = JOEI_correctSignals(data_badcomp, data_preproc1);

    clear data_badcomp data_preproc1
    fprintf('\n');

    % export the reviced data in a *.mat file
    cfg             = [];
    cfg.desFolder   = strcat(desPath, '04b_corrected/');
    cfg.filename    = sprintf('JOEI_p%02d_04b_corrected', i);
    cfg.sessionStr  = sessionStr;

    file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                       '.mat');

    fprintf('The reviced data of participant %d will be saved in:\n', i);
    fprintf('%s ...\n', file_path);
    JOEI_saveData(cfg, 'data_corrected', data_corrected);
    fprintf('Data stored!\n\n');
  else
    % clear ICA components cell in the settings file
    warning off;
    T.ICAcomp(i) = {'---'};
    warning on;

    % store settings table
    delete(settings_file);
    writetable(T, settings_file);

    % load basic bandpass filtered data
    cfg             = [];
    cfg.srcFolder   = strcat(desPath, '02b_preproc1/');
    cfg.filename    = sprintf('JOEI_p%02d_02b_preproc1', i);
    cfg.sessionStr  = sessionStr;

    fprintf('Load bandpass filtered data...\n');
    JOEI_loadData( cfg )

    data_corrected = data_preproc1;
    clear data_preproc1
  end

  %% Recovery of bad channels %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  fprintf('<strong>Bad channel recovery</strong>\n\n');

  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '02a_badchan/');
  cfg.filename    = sprintf('JOEI_p%02d_02a_badchan', i);
  cfg.sessionStr  = sessionStr;

  fprintf('Load bad channels specification...\n');
  JOEI_loadData( cfg );

  data_preproc1 = JOEI_repairBadChan( data_badchan, data_corrected );
  clear data_badchan data_corrected

  %% re-referencing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  fprintf('\n<strong>Rereferencing</strong>\n');

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

  fprintf('The clean and re-referenced data of participant %d will be saved in:\n', i);
  fprintf('%s ...\n', file_path);
  JOEI_saveData(cfg, 'data_preproc2', data_preproc2);
  fprintf('Data stored!\n\n');
  clear data_preproc2 data_preproc1
end

%% clear workspace
clear file_path cfg sourceList numOfSources i selection x T ...
      settings_file ICAcomp reference refchannel mastoid icacorr ...
      fileList numOfFiles numOfICA tmpPath
