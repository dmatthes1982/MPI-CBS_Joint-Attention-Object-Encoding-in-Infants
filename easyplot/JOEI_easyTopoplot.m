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
%   cfg.baseline    = baseline condition (default: [], can by any valid condition)
%                     the values of the baseline condition will be subtracted
%                     from the values of the selected condition (cfg.condition)
%   cfg.freqlim     = limits for frequency in Hz (e.g. [6 9] or 10) (default: 10)
%   cfg.zlim        = limits for color dimension, 'maxmin', 'maxabs', 'zeromax', 'minzero', or [zmin zmax] (default = 'maxmin')
%   cfg.showeogv    = 'yes' or 'no' (default: 'no'), show vertical eye electrodes in topoplot
%
% This function requires the fieldtrip toolbox
%
% See also JOEI_PWELCH, JOEI_DATASTRUCTURE

% Copyright (C) 2019, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
condition = ft_getopt(cfg, 'condition', 91);
baseline  = ft_getopt(cfg, 'baseline', []);
freqlim   = ft_getopt(cfg, 'freqlim', 10);
zlim      = ft_getopt(cfg, 'zlim', 'maxmin');
showeogv  = ft_getopt(cfg, 'showeogv', 'no');

filepath = fileparts(mfilename('fullpath'));                                % add utilities folder to path
addpath(sprintf('%s/../utilities', filepath));

trialinfo = data.trialinfo;                                                 % get trialinfo

condition = JOEI_checkCondition( condition, 'flag', 'meta' );               % check cfg.condition definition
if isempty(find(trialinfo == condition, 1))
  error('The selected dataset contains no condition %d.', condition);
else
  trialNum = ismember(trialinfo, condition);
end

if ~isempty(baseline)
  baseline    = JOEI_checkCondition( baseline, 'flag', 'meta' );            % check cfg.baseline definition
  if isempty(find(trialinfo == baseline, 1))
    error('The selected dataset contains no condition %d.', baseline);
  else
    baseNum = ismember(trialinfo, baseline);
  end
end

if numel(freqlim) == 1
  freqlim = [freqlim freqlim];
end

if isfield(data, 'numOfAllSeg')
    data = rmfield(data, 'numOfAllSeg');                                    % remove irrelevant information to avoid misleading warnings
end
if isfield(data, 'numOfGoodSeg')
    data = rmfield(data, 'numOfGoodSeg');
end
if isfield(data, 'parts')
    data = rmfield(data, 'parts');
end

% -------------------------------------------------------------------------
% Generate topoplot
% -------------------------------------------------------------------------
load(sprintf('%s/../layouts/mpi_customized_acticap32.mat', filepath), 'lay');

if strcmp(showeogv, 'no')
  tf = ~ismember(lay.label, {'V1','V2'});
  lay.pos     = lay.pos(tf,:);
  lay.label   = lay.label(tf);
  lay.width   = lay.width(tf);
  lay.height  = lay.height(tf);
end

cfg               = [];
cfg.parameter     = 'powspctrm';
cfg.xlim          = freqlim;
cfg.zlim          = zlim;
cfg.trials        = trialNum;
cfg.colormap      = 'jet';
cfg.marker        = 'on';
cfg.colorbar      = 'yes';
cfg.style         = 'both';
cfg.gridscale     = 200;                                                    % gridscale at map, the higher the better
cfg.layout        = lay;
cfg.showcallinfo  = 'no';

if ~isempty(baseline)                                                       % subtract baseline condition
  data.powspctrm(trialNum,:,:) = data.powspctrm(trialNum,:,:) - ...
                                  data.powspctrm(baseNum,:,:);
end

ft_topoplotER(cfg, data);

if isempty(baseline)                                                        % set figure title
  title(sprintf(['Power - Condition %d - Freqrange '...
            '[%d %d]'], condition, freqlim));
else
  title(sprintf(['Power - Condition %d-%d - '...
            'Freqrange [%d %d]'], condition, baseline, freqlim));
end

set(gcf, 'Position', [0, 0, 750, 550]);
movegui(gcf, 'center');
              
end
