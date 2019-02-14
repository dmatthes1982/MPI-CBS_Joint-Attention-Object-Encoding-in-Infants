function [ data_badchan ] = JOEI_selectBadChan( data_raw, data_noisy )
% JOEI_SELECTBADCHAN can be used for selecting bad channels visually. The
% data will be presented in two different ways. The first fieldtrip
% databrowser view shows the time course of each channel. The second view
% shows the total power of each channel and is highlighting outliers. The
% bad channels can be marked within the JOEI_CHANNELCHECKBOX gui.
%
% Use as
%   [ data_badchan ] = JOEI_selectBadChan( data_raw, data_noisy )
%
% where the first input has to be concatenated raw data and second one has
% to be the rsult of JOEI_ESTNOISYCHAN.
%
% The function requires the fieldtrip toolbox
%
% SEE also JOEI_DATABROWSER, JOEI_ESTNOISYCHAN and JOEI_CHANNELCHECKBOX

% Copyright (C) 2018-2019, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Check data
% -------------------------------------------------------------------------
if numel(data_raw.trialinfo) ~= 1
  error('First dataset has more than one trial. Data has to be concatenated!');
end

if ~isfield(data_noisy, 'totalpow')
  error('Second dataset has to be the result of JOEI_ESTNOISYCHAN!');
end

% -------------------------------------------------------------------------
% Databrowser settings
% -------------------------------------------------------------------------
cfg             = [];
cfg.ylim        = [-200 200];
cfg.blocksize   = 120;
cfg.plotevents  = 'no';

% -------------------------------------------------------------------------
% Selection of bad channels
% -------------------------------------------------------------------------
fprintf('<strong>Select bad channels...</strong>\n');
JOEI_easyTotalPowerBarPlot( data_noisy );
fig = gcf;                                                                  % default position is [560 528 560 420]
fig.Position = [0 528 560 420];                                             % --> first figure will be placed on the left side of figure 2
JOEI_databrowser( cfg, data_raw );
cfgCC.maxchan = fix(numel(data_raw.label) * 0.1);                           % estimate 10% of the total number of channels in the data
badLabel = JOEI_channelCheckbox( cfgCC );
close(gcf);                                                                 % close also databrowser view when the channelCheckbox will be closed
close(gcf);                                                                 % close also total power diagram when the channelCheckbox will be closed
 if any(strcmp(badLabel, 'TP10'))
  warning backtrace off;
  warning(['You have repaired ''TP10'', accordingly selecting linked ' ...
           'mastoid as reference in step [2] - preprocessing is not '...
           'longer recommended.']);
  warning backtrace on;
end
if length(badLabel) >= 2
  warning backtrace off;
  warning(['You have selected more than one channel. Please compare your ' ... 
           'selection with the neighbour definitions in 00_settings/general. ' ...
           'Bad channels will exluded from a repairing operation of a ' ...
           'likewise bad neighbour, but each channel should have at least '...
           'two good neighbours.']);
  warning backtrace on;
end
fprintf('\n');

data_badchan = data_noisy;

if ~isempty(badLabel)
  data_badchan.badChan = data_raw.label(ismember(data_raw.label, badLabel));
else
  data_badchan.badChan = [];
end

end
