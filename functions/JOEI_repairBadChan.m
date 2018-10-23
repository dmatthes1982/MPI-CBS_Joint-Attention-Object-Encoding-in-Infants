function [ data_repaired ] = JOEI_repairBadChan( data_badchan, data_raw )
% JOEI_REPAIRBADCHAN can be used for repairing previously selected bad
% channels. For repairing this function uses the weighted neighbour
% approach. After the repairing operation, the result will be displayed in
% the fieldtrip databrowser for verification purpose.
%
% Use as
%   [ data_repaired ] = JOEI_repairBadChan( data_badchan, data_raw )
%
% where data_raw has to be raw data and data_badchan the result of
% JOEI_SELECTBADCHAN.
%
% Used layout and neighbour definitions:
%   mpi_customized_acticap32.mat
%   mpi_customized_acticap32_neighb.mat
%
% The function requires the fieldtrip toolbox
%
% SEE also JOEI_DATABROWSER and FT_CHANNELREPAIR

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Load layout and neighbour definitions
% -------------------------------------------------------------------------
load('mpi_customized_acticap32_neighb.mat', 'neighbours');
load('mpi_customized_acticap32.mat', 'lay');

% -------------------------------------------------------------------------
% Configure Repairing
% -------------------------------------------------------------------------
cfg               = [];
cfg.method        = 'weighted';
cfg.neighbours    = neighbours;
cfg.layout        = lay;
cfg.trials        = 'all';
cfg.showcallinfo  = 'no';
cfg.badchannel    = data_badchan.badChan;

% -------------------------------------------------------------------------
% Repairing bad channels
% -------------------------------------------------------------------------
fprintf('<strong>Repairing bad channels...</strong>\n');
if isempty(cfg.badchannel)
  fprintf('All channels are good, no repairing operation required!\n');
  data_repaired = data_raw;
else
  data_repaired = ft_channelrepair(cfg, data_raw);
  data_repaired = removefields(data_repaired, {'elec'});
end

cfgView           = [];
cfgView.ylim      = [-200 200];
cfgView.blocksize = 120;
  
fprintf('\n<strong>Verification view...</strong>\n');
JOEI_databrowser( cfgView, data_repaired );
commandwindow;                                                              % set focus to commandwindow
input('Press enter to continue!:');
close(gcf);

fprintf('\n');

end
