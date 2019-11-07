function [ data ] = JOEI_createMetaCond( cfg, data)
% JOEI_CREATEMETACOND creates a subset of trials in which a certain event
% (infant object look, mutual gaze, mutual object look) took place.
%
% Use as
%   [ data ] = JOEI_createMetaCond( cfg, data )
%
% where the input data have to be the result from either JOEI_IMPORTATASET
% or JOEI_PREPROCESSING
%
% The configuration options are
%   cfg.event     = name of event, options: 'infObj', 'mGaze', 'mObj' (default: 'infObj')
%   cfg.eventSpec = event specification, output of JOEI_IMPORTATASET
%                   (see file JOEI_pxx_01b_events_yyy.mat)
%
% This function requires the fieldtrip toolbox.
%
% See also JOEI_SEGMENTATION, JOEI_MANARTIFACT and JOEI_AUTOARTIFACT 

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get config options
% -------------------------------------------------------------------------
event     = ft_getopt(cfg, 'event', 'infObj');
eventSpec = ft_getopt(cfg, 'eventSpec', []);
                
if isempty(eventSpec)
  error('cfg.eventSpec has to be defined');
end

switch event
  case 'infObj'
    trl = eventSpec.gaze_inf.object.trl;
    markerOffset = 300;
  case 'mGaze'
    trl = eventSpec.analysis_gaze.MutualGaze.trl;
    markerOffset = 400;
  case 'mObj'
    trl = eventSpec.analysis_gaze.MutualObject.trl;
    markerOffset = 500;
end

% -------------------------------------------------------------------------
% Create data subset
% -------------------------------------------------------------------------
cfg               = [];
cfg.trl           = trl;
cfg.showcallinfo  = 'no';

ft_info off;
ft_warning off;

fprintf(['Create data of meta conditions which are related to the '...
          'event %s...\n'], event);

tf = false(1, size(cfg.trl,1));                                             % remove events which are completely not within given trials
for i = 1:1:size(cfg.trl,1)
  tf(i) = any(cfg.trl(i,1) <= data.sampleinfo(:,2) & ...
               cfg.trl(i,2) >= data.sampleinfo(:,1));
end
cfg.trl = cfg.trl(tf,:);

data = ft_redefinetrial(cfg, data);
data = removeNaN( data );
data.trialinfo = data.trialinfo + markerOffset;

ft_info on;
ft_warning on;

end

% -------------------------------------------------------------------------
% SUBFUNCTION - Remove NaN segements of trials
% -------------------------------------------------------------------------
function [data] = removeNaN( data )
  for i = 1:1:length(data.trial)
    sampleVector = data.sampleinfo(i,1):1:data.sampleinfo(i,2);             % create a sample number vector using sampleinfo
    mask = ~isnan(data.trial{i});                                           % estimate a non NaN mask
    if ~all(mask(1,:))                                                      % if trial has NaNs
      trial = data.trial{i}(:, mask(1,:));                                  % prune NaN part from trial
      time  = data.time{i}(mask(1,:));                                      % remove related part from time vector
      sampleVector = sampleVector(mask(1,:));                               % remove related pert from sample vector
      if ~isempty(trial)                                                    % if trial is not empty
        data.trial{i}         = trial;                                      % replace trial with pruned version
        data.time{i}          = time - time(1);                             % replace time vector with pruned version and remove zero point offset
        data.sampleinfo(i,1)  = sampleVector(1);                            % create adapted sampleinfo entry using pruned sample vector
        data.sampleinfo(i,2)  = sampleVector(end);
      else
        cprintf([1,0.5,0], 'One trial completely removed. It had only NaN values.\n');
        data.time{i}    = [];                                               % clear time vector
        data.trial{i}   = [];                                               % clear trial array
        data.sampleinfo = [0 0];                                            % set sampleinfo to 0 0
        data.trialinfo  = 0;                                                % set trialinfo to 0
      end
    end
  end

  mask = cell2mat(cellfun(@(x) ~isempty(x), data.trial, ...                 % remove all empty trials and their additional parameters
                    'UniformOutput', false));
  data.trial      = data.trial(mask);
  data.time       = data.time(mask);
  data.sampleinfo = data.sampleinfo(mask,:);
  data.trialinfo  = data.trialinfo(mask);
end
