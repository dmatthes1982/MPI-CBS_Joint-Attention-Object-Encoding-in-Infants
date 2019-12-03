%% check if basic variables are defined
if ~exist('sessionStr', 'var')
  cfg           = [];
  cfg.subfolder = '04c_preproc2';
  cfg.filename  = 'JOEI_p01_04c_preproc2';
  sessionStr    = sprintf('%03d', JOEI_getSessionNum( cfg ));               % estimate current session number
end

if ~exist('desPath', 'var')
  desPath = '/data/pt_01904/eegData/EEG_JOEI_processedData/';               % destination path for processed data
end

if ~exist('numOfPart', 'var')                                               % estimate number of participants in preproc2 data folder
  sourceList    = dir([strcat(desPath, '04c_preproc2/'), ...
                       strcat('*_', sessionStr, '.mat')]);
  sourceList    = struct2cell(sourceList);
  sourceList    = sourceList(1,:);
  numOfSources  = length(sourceList);
  numOfPart     = zeros(1, numOfSources);

  for i=1:1:numOfSources
    numOfPart(i)  = sscanf(sourceList{i}, ...
                    strcat('JOEI_p%d_04c_preproc2_', sessionStr, '.mat'));
  end
end

%% part 6
% Calculate the power spectrum of the preprocessed data

cprintf([0,0.6,0], '<strong>[6] - Power analysis (pWelch)</strong>\n');
fprintf('\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Calculation of power spectrum using Welch's method (pWelch)
selection = false;                                                          % artifact removal? [y/n]
while selection == false
  cprintf([0,0.6,0], 'Should rejection of detected artifacts be applied before power estimation?\n');
  x = input('Select [y/n]: ','s');
  if strcmp('y', x)
    selection = true;
    artifactRejection = true;
  elseif strcmp('n', x)
    selection = true;
    artifactRejection = false;
  else
    selection = false;
  end
end
fprintf('\n');

selection = false;                                                          % use of exclusion table? [y/n]
while selection == false
  cprintf([0,0.6,0], 'Do you want to consider the exclusion table?\n');
  y = input('Select [y/n]: ','s');
  if strcmp('y', y)
    selection = true;
    exclusionTable = true;
  elseif strcmp('n', y)
    selection = true;
    exclusionTable = false;
  else
    selection = false;
  end
end

if exclusionTable == true
  if ~exist([desPath '00_settings/Ausschluss_overall.txt'], 'file')
    y = 'n';
    exclusionTable = false;
    fprintf('Exclusion table ''Ausschluss_overall.txt'' does not excist. It can''t be considered\n');
  end
end
fprintf('\n');

selection = false;                                                          % selection of pwelch parameter
while selection == false
  cprintf([0,0.6,0], 'Please select segmentation size for pwelch estimation:\n');
  fprintf('[1] - 1 sec \n');
  fprintf('[2] - 2 sec \n');
  z = input('Option: ');

  switch z
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
  z = input('Option: ');

  if z == 1
    selection = true;
    overlap = 0.5;
  elseif z == 2
    selection = true;
    overlap = 0.75;
  elseif z == 3 && seglength == 2
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
T.exclusionTbl(numOfPart) = { y };
T.powSeglength(numOfPart) = seglength;
T.powOverlap(numOfPart)   = overlap;
warning on;
delete(file_path);
writetable(T, file_path);

if exclusionTable == true                                                   % Load exclusion table if requested
  fprintf('<strong>Load exclusion table...</strong>\n\n');

  exclTbl = readtable([desPath '00_settings/Ausschluss_overall.txt']);
  varNames = exclTbl.Properties.VariableNames;
  tf = cellfun(@(X) strncmp(X, 'S', 1), varNames, 'UniformOutput', false);
  tf = cell2mat(tf);
  varNames = varNames(tf);
  varNames = cellfun(@(X) strrep(X, 'S', ''), varNames, ...
                        'UniformOutput', false);
  varNames = cellfun(@(X) str2double(X), varNames, 'UniformOutput', false);
  varNames = cell2mat(varNames);

  cData = table2cell(exclTbl);
  cData = cData(:,tf);
  cData = cell2mat(cData);
  cData = ~cData;                                                           % since it's easier to use 1 for in and 0 for out

  partList = exclTbl.VP(:);

  clear exclTbl tf
end

for i = numOfPart
  fprintf('<strong>Participant %d</strong>\n\n', i);

  % Load preprocessed data
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '04c_preproc2/');
  cfg.filename    = sprintf('JOEI_p%02d_04c_preproc2', i);
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

  % Remove bad trials if exclusion table consideration was selected
  if exclusionTable == true
    [~, col] = ismember(i, partList);

    if col
      tf = ismember(varNames, data_preproc2.trialinfo);
      status = cData(col,tf);
      vars = varNames(tf);
      [~, pos] = ismember(vars, data_preproc2.trialinfo);

      tf = true(1, length(data_preproc2.trialinfo));
      tf(pos) = status;

      data_preproc2.trialinfo   = data_preproc2.trialinfo(tf);
      data_preproc2.sampleinfo  = data_preproc2.sampleinfo(tf,:);
      data_preproc2.trial       = data_preproc2.trial(tf);
      data_preproc2.time        = data_preproc2.time(tf);
    end

    clear pos col tf status vars
  end

  % Create meta conditions
  cfg             = [];
  cfg.event       = 'infObj';
  cfg.eventSpec   = cfg_events;
  data_infObj     = JOEI_createMetaCond(cfg, data_preproc2);

  cfg.event       = 'mGaze';
  data_mGaze      = JOEI_createMetaCond(cfg, data_preproc2);

  cfg.event       = 'mObj';
  data_mObj       = JOEI_createMetaCond(cfg, data_preproc2);

  filepath = fileparts(mfilename('fullpath'));
  load(sprintf('%s/general/JOEI_generalDefinitions.mat', filepath), ...
                'generalDefinitions');

  cfg               = [];
  cfg.showcallinfo  = 'no';
  cfg.trials        = ismember(data_preproc2.trialinfo, ...
                        generalDefinitions.condNum(1:16));
  fprintf('Extract data of meta conditions ''AllJA'', ''AllNoJA'' and ''AllBubble''...\n');
  data_all          = ft_selectdata(cfg, data_preproc2);

  cfg.trials        = ismember(data_infObj.trialinfo, ...
                        generalDefinitions.metaCondNum(1:12));
  fprintf('Extract data of meta conditions ''AllJA-infObj'' and ''AllNoJA-infObj''...\n');
  data_allinfObj    = ft_selectdata(cfg, data_infObj);

  cfg.trials        = ismember(data_mGaze.trialinfo, ...
                        generalDefinitions.metaCondNum(13:24));
  fprintf('Extract data of meta conditions ''AllJA-mGaze'' and ''AllNoJA-mGaze''...\n');
  data_allmGaze     = ft_selectdata(cfg, data_mGaze);

  cfg.trials        = ismember(data_mObj.trialinfo, ...
                        generalDefinitions.metaCondNum(25:36));
  fprintf('Extract data of meta conditions ''AllJA-mObj'' and ''AllNoJA-mObj''...\n');
  data_allmObj      = ft_selectdata(cfg, data_mObj);

  data_all.trialinfo        = data_all.trialinfo - ...
                              mod(data_all.trialinfo, 10) + 1000;
  data_allinfObj.trialinfo  = data_allinfObj.trialinfo - ...
                              mod(data_allinfObj.trialinfo, 10) + 1000;
  data_allmGaze.trialinfo   = data_allmGaze.trialinfo - ...
                              mod(data_allmGaze.trialinfo, 10) + 1000;
  data_allmObj.trialinfo    = data_allmObj.trialinfo - ...
                              mod(data_allmObj.trialinfo, 10) + 1000;

  % Unify datasets
  cfg = [];
  cfg.showcallinfo = 'no';

  ft_info off;
  fprintf('Append the meta condition datasets to the initial dataset...\n\n');
  data_preproc2  = ft_appenddata(cfg, data_preproc2, data_infObj, ...
                                      data_mGaze, data_mObj, data_all, ...
                                      data_allinfObj, data_allmGaze, ...
                                      data_allmObj);
  ft_info on;

  clear data_infObj data_mGaze data_mObj data_all data_allinfObj ...
        data_allmGaze data_allmObj cfg_events generalDefinitions ...
        filepath

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
clear file_path cfg sourceList numOfSources i selection tfr pwelch T ...
      artifactRejection artifactAvailable overlap x y z numOfAllSeg ...
      numOfGoodSeg seglength exclusionTable cData partList varNames
