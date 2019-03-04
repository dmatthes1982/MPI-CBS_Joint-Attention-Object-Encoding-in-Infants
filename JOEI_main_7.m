%% check if basic variables are defined
if ~exist('sessionStr', 'var')
  cfg           = [];
  cfg.subFolder = '06a_pwelch/';
  cfg.filename  = 'JOEI_p01_06a_pwelch';
  sessionStr    = sprintf('%03d', JOEI_getSessionNum( cfg ));               % estimate current session number
end

if ~exist('desPath', 'var')
  desPath = '/data/pt_01904/eegData/EEG_JOEI_processedData/';               % destination path for processed data
end

%% part 7
% Averaging over participants

cprintf([0,0.6,0], '<strong>[7] - Averaging over participants</strong>\n');
fprintf('\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Averaging power over participants
choise = false;
while choise == false
  cprintf([0,0.6,0], 'Averaging power over participants?\n');
  x = input('Select [y/n]: ','s');
  if strcmp('y', x)
    choise = true;
    avgOverParts = true;
    fprintf('\n');
  elseif strcmp('n', x)
    choise = true;
    avgOverParts = false;
  else
    choise = false;
  end
end

if avgOverParts == true
  cfg             = [];
  cfg.path        = strcat(desPath, '06a_pwelch/');
  cfg.session     = str2double(sessionStr);
  
  data_pwelchop     = JOEI_powOverParts( cfg );
  
  % export the averaged power spectrum into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '07a_pwelchop/');
  cfg.filename    = 'JOEI_07a_pwelchop';
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('Saving power spectrum over participants in:\n'); 
  fprintf('%s ...\n', file_path);
  JOEI_saveData(cfg, 'data_pwelchop', data_pwelchop);
  fprintf('Data stored!\n');
  clear data_pwelchop
end

%% clear workspace
clear cfg file_path avgOverParts x choise
