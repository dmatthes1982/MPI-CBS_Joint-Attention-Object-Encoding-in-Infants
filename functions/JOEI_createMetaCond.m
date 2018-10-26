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
data = ft_redefinetrial(cfg, data);
data.trialinfo = data.trialinfo + markerOffset;

ft_info on;
ft_warning on;

end
