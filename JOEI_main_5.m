%% check if basic variables are defined
if ~exist('sessionStr', 'var')
  cfg           = [];
  cfg.subFolder = '04c_preproc2/';
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

%% part 5
% 1. auto artifact detection (threshold and method is selectable - default: 'minmax', +-100 µV)
% 2. manual artifact detection (verification)

cprintf([0,0.6,0], '<strong>[5] - Automatic and manual artifact detection</strong>\n');
fprintf('\n');

default_threshold = [100,   ...                                             % default for method 'minmax'
                     200,  ...                                              % default for method 'range'
                     50,   ...                                              % default for method 'stddev'
                     7];                                                    % default for method 'mad'
threshold_range   = [50, 200; ...                                           % range for method 'minmax'
                     50, 300; ...                                           % range for method 'range'
                     20, 100; ...                                           % range for method 'stddev'
                     3, 7];                                                 % range for method 'mad'

% method selection
selection = false;
while selection == false
  cprintf([0,0.6,0], 'Please select an artifact detection method:\n');
  fprintf('[1] - minmax threshold\n');
  fprintf('[2] - range threshold within 200ms, sliding window\n');
  fprintf('[3] - stddev threshold within 200ms, sliding window\n');
  fprintf('[4] - mutiple of median absolute deviation, sliding window\n');
  x = input('Option: ');

  switch x
    case 1
      selection = true;
      method = 'minmax';
      winsize = [];
      sliding = 'no';
    case 2
      selection = true;
      method = 'range';
      winsize = 200;
      sliding = 'yes';
    case 3
      selection = true;
      method = 'stddev';
      winsize = 200;
      sliding = 'yes';
    case 4
      selection = true;
      method = 'mad';
      winsize = 200;
      sliding = 'yes';
    otherwise
      cprintf([1,0.5,0], 'Wrong input!\n');
  end
end
fprintf('\n');

% use default threshold
selection = false;
while selection == false
  if x ~= 4
    cprintf([0,0.6,0], 'Do you want to use the default threshold of %d %sV for automatic artifact detection?\n', default_threshold(x), char(956));
  else
    cprintf([0,0.6,0], 'Do you want to use the default threshold of %d times of mad for automatic artifact detection?\n', default_threshold(x));
  end
  y = input('Select [y/n]: ','s');
  if strcmp('y', y)
    selection = true;
    threshold = default_threshold(x);
  elseif strcmp('n', y)
    selection = true;
    threshold = [];
  else
    selection = false;
  end
end
fprintf('\n');

% use alternative threshold
if isempty(threshold)
  selection = false;
  while selection == false
    if x ~= 4
      cprintf([0,0.6,0], 'Define the threshold (in %sV) with a value from the range between %d and %d!\n', char(956), threshold_range(x,:));
      if x == 1
        cprintf([0,0.6,0], 'Note: i.e. value 100 means threshold limits are +-100%sV\n', char(956));
      end
    else
      cprintf([0,0.6,0], 'Define the threshold (in mutiples of mad) with a value from the range between %d and %d!\n', threshold_range(x,:));
    end
    y = input('Value: ');
    if isnumeric(y)
      if (y < threshold_range(x,1) || y > threshold_range(x,2))
        cprintf([1,0.5,0], '\nWrong input!\n\n');
        selection = false;
      else
        threshold = y;
        selection = true;
      end
    else
      cprintf([1,0.5,0], '\nWrong input!\n\n');
      selection = false;
    end
  end
fprintf('\n');  
end

% detection of segments in which channels are dead or in saturation
selection = false;
while selection == false
  cprintf([0,0.6,0], 'Do you want to mark segments as artificats in which channels are dead or in saturation?\n');
  y = input('Select [y/n]: ','s');
  if ismember(y, {'y','n'})
    selection = true;
    deadSegs = y;
  else
    selection = false;
  end
end
fprintf('\n');

% channel selection
selection = false;
while selection == false
  cprintf([0,0.6,0], 'Select channels, which should be used for artifact detection?\n');
  fprintf('[1] - all channels (except V1, V2, REF, EOGV and EOGH)\n');
  fprintf('[2] - only Fz, F3, FC3, FC1, Cz, C3, C4, FC4, FC2, F4\n');
  fprintf('[3] - other specific selection\n');
  x = input('Option: ');

  switch x
    case 1
      selection = true;
      selChan = {'all', '-V1', '-V2', '-REF', '-EOGV', '-EOGH'};
      channels = {'all'};
    case 2
      selection = true;
      selChan = {'Fz', 'F3', 'FC3', 'FC1', 'Cz', 'C3', 'C4', ...
                  'FC4', 'FC2', 'F4', '-V1', '-V2', '-REF', ...
                  '-EOGV', '-EOGH'};
      channels = {'Fz,F3,FC3,FC1,Cz,C3,C4,FC4,FC2,F4'};
    case 3
      selection = true;
      cprintf([0,0.6,0], '\nAvailable channels will be determined. Please wait...\n');
      cfg             = [];
      cfg.srcFolder   = strcat(desPath, '04c_preproc2/');
      cfg.filename    = sprintf('JOEI_p%02d_04c_preproc2', numOfPart(1));
      cfg.sessionStr  = sessionStr;

      JOEI_loadData( cfg );

      label = data_preproc2.label;
      label = label(~ismember(label, {'REF', 'EOGV', 'EOGH'}));             % remove 'REF', 'EOGV' and 'EOGH'
      clear data_preproc2

      sel = listdlg('PromptString', 'Select channels of interest...', ...   % open the dialog window --> the user can select the channels of interest
              'ListString', label, ...
              'ListSize', [220, 300] );

      selChan = label(sel);
      channels = {strjoin(selChan,',')};

      fprintf('You have selected the following channels:\n');
      fprintf('%s\n', channels{1});
    otherwise
      cprintf([1,0.5,0], 'Wrong input!\n');
  end
end
fprintf('\n');

% handle existing manual selected artifacts
selection = false;
while selection == false
  cprintf([0,0.6,0], 'Do you want to load existing manually selected artifacts?\n');
  y = input('Select [y/n]: ','s');
  if strcmp('y', y)
    selection = true;
    importArt = true;
  elseif strcmp('n', y)
    selection = true;
    importArt = false;
  else
    selection = false;
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
T.artMethod(numOfPart) = {method};
T.artThreshold(numOfPart) = threshold;
T.deadSegs(numOfPart) = {deadSegs};
T.artChan(numOfPart) = channels;
warning on;
delete(file_path);
writetable(T, file_path);

for i = numOfPart
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '04c_preproc2/');
  cfg.filename    = sprintf('JOEI_p%02d_04c_preproc2', i);
  cfg.sessionStr  = sessionStr;
  
  fprintf('<strong>Participant %d</strong>\n', i);
  fprintf('Load preprocessed data...\n');
  JOEI_loadData( cfg );
  
  if strcmp(deadSegs, 'y')
    cfg             = [];
    cfg.srcFolder   = strcat(desPath, '01a_raw/');
    cfg.filename    = sprintf('JOEI_p%02d_01a_raw', i);
    cfg.sessionStr  = sessionStr;

    fprintf('Load raw data...\n\n');
    JOEI_loadData( cfg );
  else
    fprintf('\n');
  end

  % automatic artifact detection
  cfg             = [];
  cfg.channel     = selChan;
  cfg.method      = method;                                                 % artifact detection method
  if strcmp(deadSegs, 'y')
    cfg.deadsegs   = 'yes';                                                 % detection of segments in which at least one channel is dead or in saturation
  end
  cfg.sliding     = sliding;                                                % use sliding window or not
  cfg.winsize     = winsize;                                                % size of sliding window
  cfg.continuous  = 'no';                                                   % data is trial-based
  cfg.trllength   = 200;                                                    % minimal subtrial length: 200 ms
  cfg.overlap     = 0;                                                      % no overlap
  cfg.min         = -threshold;                                             % min: -threshold µV
  cfg.max         = threshold;                                              % max: threshold µV
  cfg.range       = threshold;                                              % range: threshold µV
  cfg.stddev      = threshold;                                              % stddev: threshold µV
  cfg.mad         = threshold;                                              % mad: multiples of median absolute deviation

  if strcmp(deadSegs, 'n')
    cfg_autoart     = JOEI_autoArtifact(cfg, data_preproc2);
  else
    cfg_autoart     = JOEI_autoArtifact(cfg, data_preproc2, data_raw);
  end

  % import existing manual selected artifacts
  if importArt == true
    cfg             = [];
    cfg.srcFolder   = strcat(desPath, '05b_allart/');
    cfg.filename    = sprintf('JOEI_p%02d_05b_allart', i);
    cfg.sessionStr  = sessionStr;

    filename = strcat(cfg.srcFolder, cfg.filename, '_', cfg.sessionStr, ...
                      '.mat');

    if ~exist( filename, 'file')
      cprintf([1,0.5,0], ['\nThere are no manual defined artifacts existing'...
                          ' for dyad %d.\n'], i);
      clear filename
    else
      fprintf('\nImport existing manual defined artifacts...\n');
      JOEI_loadData( cfg );
      cfg_autoart.artfctdef.visual = cfg_allart.artfctdef.visual;
      clear cfg_allart filename
    end
  end

  % verify automatic detected artifacts / manual artifact detection
  cfg           = [];
  cfg.artifact  = cfg_autoart;
  cfg.part      = i;
  
  cfg_allart    = JOEI_manArtifact(cfg, data_preproc2);
  
  % export the automatic selected artifacts into a *.mat file
  cfg_autoart.artfctdef = removefields(cfg_autoart.artfctdef, {'visual'});

  cfg             = [];
  cfg.desFolder   = strcat(desPath, '05a_autoart/');
  cfg.filename    = sprintf('JOEI_p%02d_05a_autoart', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('\nThe automatic selected artifacts of participant %d will be saved in:\n', i); 
  fprintf('%s ...\n', file_path);
  JOEI_saveData(cfg, 'cfg_autoart', cfg_autoart);
  fprintf('Data stored!\n');
  clear cfg_autoart data_preproc2 data_raw trl
  
  % export the verified and the additional artifacts into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '05b_allart/');
  cfg.filename    = sprintf('JOEI_p%02d_05b_allart', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('The visual verified artifacts of participant %d will be saved in:\n', i); 
  fprintf('%s ...\n', file_path);
  JOEI_saveData(cfg, 'cfg_allart', cfg_allart);
  fprintf('Data stored!\n\n');
  clear cfg_allart
  
  if(i < max(numOfPart))
    selection = false;
    while selection == false
      fprintf('Proceed with the next participant?\n');
      x = input('\nSelect [y/n]: ','s');
      if strcmp('y', x)
        selection = true;
      elseif strcmp('n', x)
        clear file_path numOfSources sourceList cfg i x selection
        return;
      else
        selection = false;
      end
    end
    fprintf('\n');
  end
end

%% clear workspace
clear file_path numOfSources sourceList cfg i x y selection T threshold ...
      method winsize sliding default_threshold threshold_range selChan ...
      channels label sel importArt deadSegs
