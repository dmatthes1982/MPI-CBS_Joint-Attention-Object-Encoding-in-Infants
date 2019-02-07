function JOEI_easyTopoplot(cfg , data)
% JOEI_EASYTOPOPLOT is a function, which makes it easier to plot the
% topographic distribution of the power over the head.
%
% Use as
%   JOEI_easyTopoplot(cfg, data)
%
%  where the input data have to be a result from JOEI_PWELCH.
%
% The configuration options are
%   cfg.condition   = condition (default: 91 or 'BubblePreJAI1', see JOEI_DATASTRUCTURE)
%   cfg.freqrange   = limits for frequency in Hz (e.g. [6 9] or 10) (default: 10) 
%
% This function requires the fieldtrip toolbox
%
% See also JOEI_PWELCH, JOEI_DATASTRUCTURE

% Copyright (C) 2019, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
condition   = ft_getopt(cfg, 'condition', 91);
freqrange   = ft_getopt(cfg, 'freqrange', 10);

filepath = fileparts(mfilename('fullpath'));                                % add utilities folder to path
addpath(sprintf('%s/../utilities', filepath));

trialinfo = data.trialinfo;                                                 % get trialinfo

condition = JOEI_checkCondition( condition );                               % check cfg.condition definition    
if isempty(find(trialinfo == condition, 1))
  error('The selected dataset contains no condition %d.', condition);
else
  trialNum = ismember(trialinfo, condition);
end

if numel(freqrange) == 1
  freqrange = [freqrange freqrange];
end

% -------------------------------------------------------------------------
% Generate topoplot
% -------------------------------------------------------------------------
load(sprintf('%s/../layouts/mpi_customized_acticap32.mat', filepath), 'lay');

cfg               = [];
cfg.parameter     = 'powspctrm';
cfg.xlim          = freqrange;
cfg.zlim          = 'maxmin';
cfg.trials        = trialNum;
cfg.colormap      = 'jet';
cfg.marker        = 'on';
cfg.colorbar      = 'yes';
cfg.style         = 'both';
cfg.gridscale     = 200;                                                    % gridscale at map, the higher the better
cfg.layout        = lay;
cfg.showcallinfo  = 'no';

ft_topoplotER(cfg, data);

title(sprintf('Power - Condition %d - Freqrange [%d %d]', ...
                condition, freqrange));

set(gcf, 'Position', [0, 0, 750, 550]);
movegui(gcf, 'center');
              
end
