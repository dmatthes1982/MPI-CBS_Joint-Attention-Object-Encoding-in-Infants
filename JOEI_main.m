% -------------------------------------------------------------------------
% Add directory and subfolders to path
% -------------------------------------------------------------------------
clc;
JOEI_init;

% -------------------------------------------------------------------------
% Set number of cores/threads to 4
% -------------------------------------------------------------------------
LASTN = maxNumCompThreads(4);                                               %#ok<NASGU>
clear LASTN

cprintf([0,0.6,0], '<strong>------------------------------------------------------------</strong>\n');
cprintf([0,0.6,0], '<strong>Joint attention object encoding in infants - data processing</strong>\n');
cprintf([0,0.6,0], '<strong>Version: 0.1</strong>\n');
cprintf([0,0.6,0], 'Copyright (C) 2018, Daniel Matthes, MPI CBS\n');
cprintf([0,0.6,0], '<strong>------------------------------------------------------------</strong>\n');

% -------------------------------------------------------------------------
% Path settings
% -------------------------------------------------------------------------
srcPath = '/data/pt_01904/eegData/EEG_JOEI_rawData/';
desPath = '/data/pt_01904/eegData/EEG_JOEI_processedData/';

fprintf('\nThe default paths are:\n');
fprintf('Source: %s\n',srcPath);
fprintf('Destination: %s\n',desPath);

selection = false;
while selection == false
  fprintf('\nDo you want to select the default paths?\n');
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
  srcPath = uigetdir(pwd, 'Select Source Folder...');
  desPath = uigetdir(strcat(srcPath,'/..'), ...
                      'Select Destination Folder...');
  srcPath = strcat(srcPath, '/');
  desPath = strcat(desPath, '/');
end

if ~exist(strcat(desPath, '00_settings'), 'dir')
  mkdir(strcat(desPath, '00_settings'));
end
if ~exist(strcat(desPath, '01a_raw'), 'dir')
  mkdir(strcat(desPath, '01a_raw'));
end
if ~exist(strcat(desPath, '01b_events'), 'dir')
  mkdir(strcat(desPath, '01b_events'));
end
if ~exist(strcat(desPath, '01c_badchan'), 'dir')
  mkdir(strcat(desPath, '01c_badchan'));
end
if ~exist(strcat(desPath, '01d_repaired'), 'dir')
  mkdir(strcat(desPath, '01d_repaired'));
end
if ~exist(strcat(desPath, '02_preproc'), 'dir')
  mkdir(strcat(desPath, '02_preproc'));
end
if ~exist(strcat(desPath, '03_icacomp'), 'dir')
  mkdir(strcat(desPath, '03_icacomp'));
end
if ~exist(strcat(desPath, '04_icacor'), 'dir')
  mkdir(strcat(desPath, '04_icacor'));
end
if ~exist(strcat(desPath, '05a_autoart'), 'dir')
  mkdir(strcat(desPath, '05a_autoart'));
end
if ~exist(strcat(desPath, '05b_allart'), 'dir')
  mkdir(strcat(desPath, '05b_allart'));
end
if ~exist(strcat(desPath, '06a_pwelch'), 'dir')
  mkdir(strcat(desPath, '06a_pwelch'));
end
if ~exist(strcat(desPath, '07a_pwelchop'), 'dir')
  mkdir(strcat(desPath, '07a_pwelchop'));
end

clear sessionStr numOfPart part newPaths

% -------------------------------------------------------------------------
% Session selection
% -------------------------------------------------------------------------
selection = false;

tmpPath = strcat(desPath, '01a_raw/');

sessionList     = dir([tmpPath, 'JOEI_p*_01a_raw_*.mat']);
sessionList     = struct2cell(sessionList);
sessionList     = sessionList(1,:);
numOfSessions   = length(sessionList);

sessionNum      = zeros(1, numOfSessions);
sessionListCopy = sessionList;

for i=1:1:numOfSessions
  sessionListCopy{i} = strsplit(sessionList{i}, '01a_raw_');
  sessionListCopy{i} = sessionListCopy{i}{end};
  sessionNum(i) = sscanf(sessionListCopy{i}, '%d.mat');
end

sessionNum = unique(sessionNum);
y = sprintf('%d ', sessionNum);

userList = cell(1, length(sessionNum));

for i = sessionNum
  match = find(strcmp(sessionListCopy, sprintf('%03d.mat', i)), 1, 'first');
  filePath = [tmpPath, sessionList{match}];
  [~, cmdout] = system(['ls -l ' filePath '']);
  attrib = strsplit(cmdout);
  userList{i} = attrib{3};
end

while selection == false
  fprintf('\nThe following sessions are available: %s\n', y);
  fprintf('The session owners are:\n');
  for i = sessionNum
    fprintf('%d - %s\n', i, userList{i});
  end
  fprintf('\n');
  fprintf('Please select one session or create a new one:\n');
  fprintf('[0] - Create new session\n');
  fprintf('[num] - Select session\n\n');
  x = input('Session: ');

  if length(x) > 1
    cprintf([1,0.5,0], 'Wrong input, select only one session!\n');
  else
    if ismember(x, sessionNum)
      selection = true;
      session = x;
      sessionStr = sprintf('%03d', session);
    elseif x == 0  
      selection = true;
      session = x;
      if ~isempty(max(sessionNum))
        sessionStr = sprintf('%03d', max(sessionNum) + 1);
      else
        sessionStr = sprintf('%03d', 1);
      end
    else
      cprintf([1,0.5,0], 'Wrong input, session does not exist!\n');
    end
  end
end

clear tmpPath sessionListCopy userList match filePath cmdout attrib 

% -------------------------------------------------------------------------
% General selection of participants
% -------------------------------------------------------------------------
selection = false;

while selection == false
  fprintf('\nPlease select one option:\n');
  fprintf('[1] - Process all available participants\n');
  fprintf('[2] - Process all new participants\n');
  fprintf('[3] - Process specific participant\n');
  fprintf('[4] - Quit data processing\n\n');
  x = input('Option: ');
  
  switch x
    case 1
      selection = true;
      partsSpec = 'all';
    case 2
      selection = true;
      partsSpec = 'new';
    case 3
      selection = true;
      partsSpec = 'specific';
    case 4
      fprintf('\nData processing aborted.\n');
      clear selection i x y srcPath desPath session sessionList ...
            sessionNum numOfSessions sessionStr
      return;
    otherwise
      cprintf([1,0.5,0], 'Wrong input!\n');
  end
end

% -------------------------------------------------------------------------
% General selection of preprocessing option
% -------------------------------------------------------------------------
selection = false;

if session == 0
  fprintf('\nA new session always will start with part:\n');
  fprintf('[1] - Import raw data\n');
  part = 1;
else
  while selection == false
    fprintf('\nPlease select what you want to do with the selected participants:\n');
    fprintf('[1] - Data import and repairing of bad channels\n');
    fprintf('[2] - Preprocessing, filtering, re-referencing\n');
    cprintf([0.5 0.5 0.5], '[3] - ICA decomposition (currently not available)\n');
    cprintf([0.5 0.5 0.5], '[4] - ICA based data correction (currently not available)\n');
    fprintf('[5] - Automatic and manual artifact detection\n');
    fprintf('[6] - Power analysis (pWelch)\n');
    fprintf('[7] - Averaging over participants\n');
    fprintf('[8] - Quit data processing\n\n');
    x = input('Option: ');
  
    switch x
      case 1
        part = 1;
        selection = true;
      case 2
        part = 2;
        selection = true;
      case 3
        part = 3;
        selection = false;
        cprintf([1,0.5,0], 'Currently not available!\n');
      case 4
        part = 4;
        selection = false;
        cprintf([1,0.5,0], 'Currently not available!\n');
      case 5
        part = 5;
        selection = true;
      case 6
        part = 6;
        selection = true;
      case 7
        part = 7;
        selection = true;
      case 8
        fprintf('\nData processing aborted.\n');
        clear selection i x y srcPath desPath session sessionList ...
            sessionNum numOfSessions partsSpec sessionStr
        return;
      otherwise
        selection = false;
        cprintf([1,0.5,0], 'Wrong input!\n');
    end
  end
end

% -------------------------------------------------------------------------
% Specific selection of participants
% -------------------------------------------------------------------------
sourceList    = dir([srcPath, '/*.vhdr']);
sourceList    = struct2cell(sourceList);
sourceList    = sourceList(1,:);
numOfSources  = length(sourceList);
fileNum       = zeros(1, numOfSources);

for i=1:1:numOfSources
  fileNum(i)     = sscanf(sourceList{i}, 'JOEI_%d.vhdr');
end

switch part
  case 1
    fileNamePre = [];
    tmpPath = strcat(desPath, '01a_raw/');
    fileNamePost = strcat(tmpPath, 'JOEI_p*_01a_raw_', sessionStr, '.mat');
  case 2
    tmpPath = strcat(desPath, '01d_repaired/');
    fileNamePre = strcat(tmpPath, 'JOEI_p*_01d_repaired_', sessionStr, '.mat');
    tmpPath = strcat(desPath, '02_preproc/');
    fileNamePost = strcat(tmpPath, 'JOEI_p*_02_preproc_', sessionStr, '.mat');
  case 3
    tmpPath = strcat(desPath, '02_preproc/');
    fileNamePre = strcat(tmpPath, 'JOEI_p*_02_preproc_', sessionStr, '.mat');
    tmpPath = strcat(desPath, '03_icacomp/');
    fileNamePost = strcat(tmpPath, 'JOEI_p*_03_icacomp_', sessionStr, '.mat');
  case 4
    tmpPath = strcat(desPath, '03_icacomp/');
    fileNamePre = strcat(tmpPath, 'JOEI_p*_03_icacomp_', sessionStr, '.mat');
    tmpPath = strcat(desPath, '04_icacor/');
    fileNamePost = strcat(tmpPath, 'JOEI_p*_04_icacor_', sessionStr, '.mat');
  case 5
    tmpPath = strcat(desPath, '02_preproc/');
    fileNamePre = strcat(tmpPath, 'JOEI_p*_02_preproc_', sessionStr, '.mat');
    tmpPath = strcat(desPath, '05b_allart/');
    fileNamePost = strcat(tmpPath, 'JOEI_p*_05b_allart_', sessionStr, '.mat');
  case 6
    tmpPath = strcat(desPath, '02_preproc/');
    fileNamePre = strcat(tmpPath, 'JOEI_p*_02_preproc_', sessionStr, '.mat');
    tmpPath = strcat(desPath, '06a_pwelch/');
    fileNamePost = strcat(tmpPath, 'JOEI_p*_06a_pwelch_', sessionStr, '.mat');
  case 7
    fileNamePre = 0;
  otherwise
    error('Something unexpected happend. part = %d is not defined' ...
          , part);
end

if ~isequal(fileNamePre, 0)
  if isempty(fileNamePre)
    numOfPrePart = fileNum;
  else
    fileListPre = dir(fileNamePre);
    if isempty(fileListPre)
      cprintf([1,0.5,0], ['Selected part [%d] can not be executed, no '...'
            'input data available\n Please choose a previous part.\n'], part);
      clear desPath fileNamePost fileNamePre fileNum i numOfSources ...
            selection sourceList srcPath x y partsSpec fileListPre ... 
            sessionList sessionNum numOfSessions session part sessionStr ...
            tmpPath
      return;
    else
      fileListPre = struct2cell(fileListPre);
      fileListPre = fileListPre(1,:);
      numOfFiles  = length(fileListPre);
      numOfPrePart = zeros(1, numOfFiles);
      for i=1:1:numOfFiles
        numOfPrePart(i) = sscanf(fileListPre{i}, strcat('JOEI_p%d*', sessionStr, '.mat'));
      end
    end
  end

  if strcmp(partsSpec, 'all')                                               % process all participants
    numOfPart = numOfPrePart;
  elseif strcmp(partsSpec, 'specific')                                      % process specific participants
    y = sprintf('%d ', numOfPrePart);
    
    selection = false;
    
    while selection == false
      fprintf('\nThe following participants are available: %s\n', y);
      fprintf(['Comma-seperate your selection and put it in squared ' ...
               'brackets!\n']);
      x = input('\nPlease make your choice! (i.e. [1,2,3]): ');
      
      if ~all(ismember(x, numOfPrePart))
        cprintf([1,0.5,0], 'Wrong input!\n');
      else
        selection = true;
        numOfPart = x;
      end
    end
  elseif strcmp(partsSpec, 'new')                                           % process only new participants
    if session == 0
      numOfPart = numOfPrePart;
    else
      fileListPost = dir(fileNamePost);
      if isempty(fileListPost)
        numOfPostPart = [];
      else
        fileListPost = struct2cell(fileListPost);
        fileListPost = fileListPost(1,:);
        numOfFiles  = length(fileListPost);
        numOfPostPart = zeros(1, numOfFiles);
        for i=1:1:numOfFiles
          numOfPostPart(i) = sscanf(fileListPost{i}, strcat('JOEI_p%d*', sessionStr, '.mat'));
        end
      end
  
      numOfPart = numOfPrePart(~ismember(numOfPrePart, numOfPostPart));
      if isempty(numOfPart)
        cprintf([1,0.5,0], 'No new participants available!\n');
        fprintf('Data processing aborted.\n');
        clear desPath fileNamePost fileNamePre fileNum i numOfPrePart ...
              numOfSources selection sourceList srcPath x y partsSpec ...
              fileListPost fileListPre numOfPostPart sessionList ...
              numOfFiles sessionNum numOfSessions session numOfPart ...
              part sessionStr tmpPath
        return;
      end
    end
  end

  y = sprintf('%d ', numOfPart);
  fprintf(['\nThe following participants will be processed ' ... 
         'in the selected part [%d]:\n'],  part);
  fprintf('%s\n\n', y);

  clear fileNamePost fileNamePre fileNum i numOfPrePart ...
        numOfSources selection sourceList x y fileListPost ...
        fileListPre numOfPostPart sessionList sessionNum numOfSessions ...
        session partsSpec numOfFiles tmpPath
else
  fprintf('\n');
  clear fileNamePost fileNamePre fileNum i numOfSources selection ...
        sourceList x y sessionList sessionNum numOfSessions ...
        session partsSpec numOfFiles tmpPath
end

% -------------------------------------------------------------------------
% Data processing main loop
% -------------------------------------------------------------------------
sessionStatus = true;
sessionPart = part;

clear part;

while sessionStatus == true
  switch sessionPart
    case 1
      JOEI_main_1;
      selection = false;
      while selection == false
        fprintf('<strong>Continue data processing with:</strong>\n');
        fprintf('<strong>[2] - Preprocessing, filtering, re-referencing?</strong>\n');
        x = input('\nSelect [y/n]: ','s');
        if strcmp('y', x)
          selection = true;
          sessionStatus = true;
          sessionPart = 2;
        elseif strcmp('n', x)
          selection = true;
          sessionStatus = false;
        else
          selection = false;
        end
      end
    case 2
      JOEI_main_2;
      selection = false;
      while selection == false
        fprintf('<strong>Continue data processing with:</strong>\n');
        fprintf('<strong>[5] - Automatic and manual detection of artifacts?</strong>\n');
        x = input('\nSelect [y/n]: ','s');
        if strcmp('y', x)
          selection = true;
          sessionStatus = true;
          sessionPart = 5;
        elseif strcmp('n', x)
          selection = true;
          sessionStatus = false;
        else
          selection = false;
        end
      end
    case 3
      JOEI_main_3;
      selection = false;
      while selection == false
        fprintf('<strong>Continue data processing with:</strong>\n');
        fprintf('<strong>[4] - ICA based data correction?</strong>\n');
        x = input('\nSelect [y/n]: ','s');
        if strcmp('y', x)
          selection = true;
          sessionStatus = true;
          sessionPart = 4;
        elseif strcmp('n', x)
          selection = true;
          sessionStatus = false;
        else
          selection = false;
        end
      end
    case 4
      JOEI_main_4;
      selection = false;
      while selection == false
        fprintf('<strong>Continue data processing with:</strong>\n');
        fprintf('<strong>[5] - Automatic and manual detection of artifacts?</strong>\n');
        x = input('\nSelect [y/n]: ','s');
        if strcmp('y', x)
          selection = true;
          sessionStatus = true;
          sessionPart = 5;
        elseif strcmp('n', x)
          selection = true;
          sessionStatus = false;
        else
          selection = false;
        end
      end
    case 5
      JOEI_main_5;
      selection = false;
      while selection == false
        fprintf('<strong>Continue data processing with:</strong>\n');
        fprintf('<strong>[6] - Power analysis (pWelch)?</strong>\n');
        x = input('\nSelect [y/n]: ','s');
        if strcmp('y', x)
          selection = true;
          sessionStatus = true;
          sessionPart = 6;
        elseif strcmp('n', x)
          selection = true;
          sessionStatus = false;
        else
          selection = false;
        end
      end
    case 6
      JOEI_main_6;
      selection = false;
      while selection == false
        fprintf('<strong>Continue data processing with:</strong>\n');
        fprintf('<strong>[7] - Averaging over participants?</strong>\n');
        x = input('\nSelect [y/n]: ','s');
        if strcmp('y', x)
          selection = true;
          sessionStatus = true;
          sessionPart = 7;
        elseif strcmp('n', x)
          selection = true;
          sessionStatus = false;
        else
          selection = false;
        end
      end  
    case 7
      JOEI_main_7;
      sessionStatus = false;
    otherwise
      sessionStatus = false;
  end
  fprintf('\n');
end

fprintf('<strong>Data processing finished.</strong>\n');
fprintf('<strong>Session will be closed.</strong>\n');

clear sessionStr numOfPart srcPath desPath sessionPart sessionStatus ...
      selection x
