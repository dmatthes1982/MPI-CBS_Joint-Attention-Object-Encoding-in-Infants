function JOEI_easyMultiPowPlot(cfg, data)
% JOEI_EASYMULTIPOWPLOT is a function, which makes it easier to plot the
% power of all electrodes within a specific condition on a head model.
%
% Use as
%   JOEI_easyMultiPowPlot(cfg, data)
%
% where the input data have to be a result from JOEI_PWELCH.
%
% The configuration options are 
%   cfg.condition   = condition (default: 91 or 'BubblePreJAI1', see JOEI_DATASTRUCTURE)
%   cfg.baseline    = baseline condition (default: [], can by any valid condition)
%                     the values of the baseline condition will be subtracted
%                     from the values of the selected condition (cfg.condition)
%   cfg.log         = use a logarithmic scale for the y axis, options: 'yes' or 'no' (default: 'no')
%   cfg.powlim      = limits for power dimension, 'maxmin' or [pmin pmax] (default = 'maxmin')
%
% This function requires the fieldtrip toolbox
%
% See also JOEI_PWELCH, JOEI_DATASTRUCTURE

% Copyright (C) 2018-2019, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
cfg.condition = ft_getopt(cfg, 'condition', 91);
cfg.baseline  = ft_getopt(cfg, 'baseline', []);
cfg.log       = ft_getopt(cfg, 'log', 'no');
powlim        = ft_getopt(cfg, 'powlim', 'maxmin');

filepath = fileparts(mfilename('fullpath'));                                % add utilities folder to path
addpath(sprintf('%s/../utilities', filepath));

trialinfo = data.trialinfo;                                                 % get trialinfo

cfg.condition = JOEI_checkCondition( cfg.condition, 'flag', 'meta' );       % check cfg.condition definition
if isempty(find(trialinfo == cfg.condition, 1))
  error('The selected dataset contains no condition %d.', cfg.condition);
else
  trialNum = find(ismember(trialinfo, cfg.condition));
end

if ~isempty(cfg.baseline)
  cfg.baseline    = JOEI_checkCondition( cfg.baseline );                    % check cfg.baseline definition
  if isempty(find(trialinfo == cfg.baseline, 1))
    error('The selected dataset contains no condition %d.', cfg.baseline);
  else
    baseNum = ismember(trialinfo, cfg.baseline);
  end
end

% -------------------------------------------------------------------------
% Load layout informations
% -------------------------------------------------------------------------
load(sprintf('%s/../layouts/mpi_customized_acticap32.mat', filepath),...
     'lay');

[selchan, sellay] = match_str(data.label, lay.label);                       % extract the subselection of channels that is part of the layout
eogvchan          = match_str(data.label, {'V1', 'V2'});                    % determine the vertical eog channles 
chanX             = lay.pos(sellay, 1);
chanY             = lay.pos(sellay, 2);
chanWidth         = lay.width(sellay);
chanHeight        = lay.height(sellay);

% -------------------------------------------------------------------------
% Multi power plot 
% -------------------------------------------------------------------------
if isempty(cfg.baseline)                                                    % extract the powerspctrm matrix
  datamatrix = squeeze(data.powspctrm(trialNum,selchan,:));
else
  datamatrix = squeeze(data.powspctrm(trialNum,selchan,:)) - ...            % subtract baseline condition
                squeeze(data.powspctrm(baseNum,selchan,:));
end

if strcmp(cfg.log, 'yes')
  datamatrix = 10 * log10( datamatrix );
end

xval        = data.freq;                                                    % extract the freq vector
xmax        = max(xval);                                                    % determine the frequency maximum

val         = ~ismember(selchan, eogvchan);                                 
ychan       = selchan(val);
if ischar(powlim)
  if strcmp(powlim, 'maxmin')
    ymin        = min(min(datamatrix(ychan, 1:48)));                        % determine the power minimum of all channels expect V1 und V2
    if(ymin > 0)
      ymin = 0;
    end
    ymax        = max(max(datamatrix(ychan, 1:48)));                        % determine the power maximum of all channels expect V1 und V2
  else
    error('cfg.powlim has to be either ''maxmin'' or [pmin pmax].');
  end
else
  if numel(powlim) == 2 && isnumeric(powlim)
    ymin = powlim(1);
    ymax = powlim(2);
  else
    error('cfg.powlim has to be either ''maxmin'' or [pmin pmax].');
  end
end

mask = datamatrix > ymax;                                                   % set outliers to NaN
datamatrix(mask) = NaN;

hold on;                                                                    % hold the figure
cla;                                                                        % clear all axis

% plot the layout
ft_plot_lay(lay, 'box', 0, 'label', 0, 'outline', 1, 'point', 'no', ...
            'mask', 'no', 'fontsize', 8, 'labelyoffset', ...
            1.4*median(lay.height/2), 'labelalignh', 'center', ...
            'chanindx', find(~ismember(lay.label, {'COMNT', 'SCALE'})) );

% plot the channels
for k=1:length(selchan) 
  yval = datamatrix(k, :);
  setChanBackground([0 xmax], [ymin ymax], chanX(k), chanY(k), ...          % set background of the channel boxes to white
                    chanWidth(k), chanHeight(k));
  ft_plot_vector(xval, yval, 'width', chanWidth(k), 'height', chanHeight(k),...
                'hpos', chanX(k), 'vpos', chanY(k), 'hlim', [0 xmax], ...
                'vlim', [ymin ymax], 'box', 0);
end

% add the comment field
k = find(strcmp('COMNT', lay.label));
comment = date;
comment = sprintf('%0s\nxlim=[%.3g %.3g]', comment, 0, xmax);
comment = sprintf('%0s\nylim=[%.3g %.3g]', comment, 0, ymax);

ft_plot_text(lay.pos(k, 1), lay.pos(k, 2), sprintf(comment), ...
             'FontSize', 8, 'FontWeight', []);

% plot the SCALE object
k = find(strcmp('SCALE', lay.label));
if ~isempty(k)
  x = lay.pos(k,1);
  y = lay.pos(k,2);
  plotScales([0 xmax], [ymin ymax], x, y, chanWidth(1), chanHeight(1));
end

% set figure title
if isempty(cfg.baseline)
  title(sprintf('Power - Cond.: %d', cfg.condition));
else
  title(sprintf('Power - Cond.: %d-%d', cfg.condition, cfg.baseline));
end

axis tight;                                                                 % format the layout
axis off;                                                                   % remove the axis
hold off;                                                                   % release the figure

% Make the figure interactive
% add the cfg/data/channel information to the figure under identifier 
% linked to this axis
ident                 = ['axh' num2str(round(sum(clock.*1e6)))];            % unique identifier for this axis
set(gca,'tag',ident);
info                      = guidata(gcf);
info.(ident).x            = lay.pos(:, 1);
info.(ident).y            = lay.pos(:, 2);
info.(ident).label        = lay.label;
info.(ident).cfg          = cfg;
info.(ident).cfg.avgelec  = 'no';
info.(ident).data         = data;
guidata(gcf, info);
set(gcf, 'WindowButtonUpFcn', {@ft_select_channel, 'multiple', ...
    true, 'callback', {@select_easyPowPlot}, ...
    'event', 'WindowButtonUpFcn'});
set(gcf, 'WindowButtonDownFcn', {@ft_select_channel, 'multiple', ...
    true, 'callback', {@select_easyPowPlot}, ...
    'event', 'WindowButtonDownFcn'});
set(gcf, 'WindowButtonMotionFcn', {@ft_select_channel, 'multiple', ...
    true, 'callback', {@select_easyPowPlot}, ...
    'event', 'WindowButtonMotionFcn'});

end

%--------------------------------------------------------------------------
% SUBFUNCTION for plotting the SCALE information
%--------------------------------------------------------------------------
function plotScales(hlim, vlim, hpos, vpos, width, height)

% the placement of all elements is identical
placement = {'hpos', hpos, 'vpos', vpos, 'width', width, 'height', height, 'hlim', hlim, 'vlim', vlim};

ft_plot_box([hlim vlim], placement{:}, 'edgecolor', 'k' , 'facecolor', 'white');

if hlim(1)<=0 && hlim(2)>=0
  ft_plot_vector([0 0], vlim, placement{:}, 'color', 'b');
end

if vlim(1)<=0 && vlim(2)>=0
  ft_plot_vector(hlim, [0 0], placement{:}, 'color', 'b');
end

ft_plot_text(hlim(1), vlim(1), [num2str(hlim(1), 3) ' '], placement{:}, 'rotation', 90, 'HorizontalAlignment', 'Right', 'VerticalAlignment', 'top', 'FontSize', 8);
ft_plot_text(hlim(2), vlim(1), [num2str(hlim(2), 3) ' '], placement{:}, 'rotation', 90, 'HorizontalAlignment', 'Right', 'VerticalAlignment', 'top', 'FontSize', 8);
ft_plot_text(hlim(1), vlim(1), [num2str(vlim(1), 3) ' '], placement{:}, 'HorizontalAlignment', 'Right', 'VerticalAlignment', 'bottom', 'FontSize', 8);
ft_plot_text(hlim(1), vlim(2), [num2str(vlim(2), 3) ' '], placement{:}, 'HorizontalAlignment', 'Right', 'VerticalAlignment', 'bottom', 'FontSize', 8);

end

%--------------------------------------------------------------------------
% SUBFUNCTION which creates channel boxes with a white background
%--------------------------------------------------------------------------
function setChanBackground(hlim, vlim, hpos, vpos, width, height)

% the placement of all elements is identical
placement = {'hpos', hpos, 'vpos', vpos, 'width', width, 'height', height, 'hlim', hlim, 'vlim', vlim};

ft_plot_box([hlim vlim], placement{:}, 'edgecolor', 'k' , 'facecolor', 'white');

end

%--------------------------------------------------------------------------
% SUBFUNCTION which is called after selecting channels
%--------------------------------------------------------------------------
function select_easyPowPlot(label, varargin)
% fetch cfg/data based on axis indentifier given as tag
ident = get(gca,'tag');
info  = guidata(gcf);
cfg   = info.(ident).cfg;
data  = info.(ident).data;
if ~isempty(label)
  if any(ismember(label, {'SCALE'}))
    cprintf([1,0.5,0], 'Selection of SCALE, F9, F10, V1, or V2 is currently not supported.\n');
  else
    cfg.electrode = label;
    fprintf('selected cfg.electrode = {%s}\n', vec2str(cfg.electrode, [], [], 0));
    % ensure that the new figure appears at the same position
    figure('Position', get(gcf, 'Position'));
    JOEI_easyPowPlot(cfg, data);
  end
end

end
