function [ data_badchan ] = JOEI_selectBadChan( data_raw )
% JOEI_SELECTBADCHAN can be used for selecting bad channels visually. The
% data will be presented in the fieldtrip databrowser view and the bad
% channels will be marked in the JOEI_CHANNELCHECKBOX gui. The function
% returns a fieldtrip-like datastructure which includes only a cell array 
% with the selected bad channels.
%
% Use as
%   [ data_badchan ] = JOEI_selectBadChan( data_raw )
%
% where the input has to be raw data
%
% The function requires the fieldtrip toolbox
%
% SEE also JOEI_DATABROWSER and JOEI_CHANNELCHECKBOX

% Copyright (C) 2018, Daniel Matthes, MPI CBS

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
JOEI_databrowser( cfg, data_raw );
badLabel = JOEI_channelCheckbox();
close(gcf);                                                                 % close also databrowser view when the channelCheckbox will be closed
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
  
if ~isempty(badLabel)
  data_badchan.badChan = data_raw.label(ismember(data_raw.label, badLabel));
else
  data_badchan.badChan = [];
end

end
