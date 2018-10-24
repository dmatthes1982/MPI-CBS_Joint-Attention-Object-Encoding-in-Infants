function JOEI_easyPlot( cfg, data )
% JOEI_EASYPLOT is a function, which makes it easier to plot the data of a 
% specific condition and trial from the JOEI-data-structure.
%
% Use as
%   JOEI_easyPlot(cfg, data)
%
% where the input data can be the results of JOEI_IMPORTDATASET or
% JOEI_PREPROCESSING
%
% The configuration options are
%   cfg.condition = condition (default: 91 or 'BubblePreJAI1', see JOEI data structure)
%   cfg.electrode = number of electrode (default: 'Cz')
%   cfg.trial     = number of trial (default: 1)
%
% This function requires the fieldtrip toolbox.
%
% See also JOEI_DATASTRUCTURE, PLOT

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
cond = ft_getopt(cfg, 'condition', 91);
elec = ft_getopt(cfg, 'electrode', 'Cz');
trl  = ft_getopt(cfg, 'trial', 1);

trialinfo = data.trialinfo;                                                 % get trialinfo
label     = data.label;                                                     % get labels

filepath = fileparts(mfilename('fullpath'));
addpath(sprintf('%s/../utilities', filepath));

cond    = JOEI_checkCondition( cond );                                      % check cfg.condition definition    
trials  = find(trialinfo == cond);
if isempty(trials)
  error('The selected dataset contains no condition %d.', cond);
else
  numTrials = length(trials);
  if numTrials < trl                                                        % check cfg.trial definition
    error('The selected dataset contains only %d trials.', numTrials);
  else
    trlInCond = trl;
    trl = trl-1 + trials(1);
  end
end

if isnumeric(elec)                                                          % check cfg.electrode definition
  if elec < 1 || elec > 32
    error('cfg.elec hast to be a number between 1 and 32 or a existing label like ''Cz''.');
  end
else
  elec = find(strcmp(label, elec));
  if isempty(elec)
    error('cfg.elec hast to be a existing label like ''Cz''or a number between 1 and 32.');
  end
end

% -------------------------------------------------------------------------
% Plot timeline
% -------------------------------------------------------------------------
plot(data.time{trl}, data.trial{trl}(elec,:));
title(sprintf('Cond.: %d - Elec.: %s - Trial: %d', ...
      cond, strrep(data.label{elec}, '_', '\_'), trlInCond));      

xlabel('time in seconds');
ylabel('voltage in \muV');

end
