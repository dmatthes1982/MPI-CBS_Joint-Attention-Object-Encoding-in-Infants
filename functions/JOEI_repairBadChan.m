function [ data ] = JOEI_repairBadChan( data_badchan, data )
% JOEI_REPAIRBADCHAN can be used for repairing previously selected bad
% channels. For repairing this function uses the weighted neighbour
% approach.
%
% Use as
%   [ data ] = JOEI_repairBadChan( data_badchan, data )
%
% where data_badchan has to be the result of INFADI_SELECTBADCHAN.
%
% Used layout and neighbour definitions:
%   mpi_customized_acticap32.mat
%   mpi_customized_acticap32_neighb.mat
%
% The function requires the fieldtrip toolbox
%
% SEE also FT_CHANNELREPAIR

% Copyright (C) 2018-2019, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Load layout and neighbour definitions
% -------------------------------------------------------------------------
load('mpi_customized_acticap32_neighb.mat', 'neighbours');
load('mpi_customized_acticap32.mat', 'lay');

% -------------------------------------------------------------------------
% Configure Repairing
% -------------------------------------------------------------------------
cfg                 = [];
cfg.method          = 'weighted';
cfg.neighbours      = neighbours;
cfg.layout          = lay;
cfg.trials          = 'all';
cfg.showcallinfo    = 'no';
cfg.missingchannel  = data_badchan.badChan;

% -------------------------------------------------------------------------
% Repairing bad channels
% -------------------------------------------------------------------------
fprintf('<strong>Repairing bad channels...</strong>\n');
if isempty(cfg.missingchannel)
  fprintf('All channels are good, no repairing operation required!\n');
else
  ft_warning off;
  data = ft_channelrepair(cfg, data);
  ft_warning on;
  data = removefields(data, {'elec'});
end
label = [lay.label; {'REF'; 'EOGV'; 'EOGH'}];
data  = correctChanOrder( data, label);

end

% -------------------------------------------------------------------------
% Local function - move corrected channel to original position
% -------------------------------------------------------------------------
function [ dataTmp ] = correctChanOrder( dataTmp, label )

[~, pos]  = ismember(label, dataTmp.label);
pos       = pos(~ismember(pos, 0));

dataTmp.label = dataTmp.label(pos);
dataTmp.trial = cellfun(@(x) x(pos, :), dataTmp.trial, 'UniformOutput', false);

end
