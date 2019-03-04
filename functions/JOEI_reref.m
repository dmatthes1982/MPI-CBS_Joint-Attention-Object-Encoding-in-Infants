function [ data ] = JOEI_reref( cfg, data )
% JOEI_REREF does the re-referencing of eeg data, 
%
% Use as
%   [ data ] = JOEI_reref(cfg, data)
%
% The configuration option is
%   cfg.refchannel        = re-reference channel (default: 'TP10')
%
% This function requires the fieldtrip toolbox.
%
% See also FT_PREPROCESSING, JOEI_DATASTRUCTURE

% Copyright (C) 2019, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check the config option
% -------------------------------------------------------------------------
refchannel        = ft_getopt(cfg, 'refchannel', 'TP10');

% -------------------------------------------------------------------------
% Re-Referencing
% -------------------------------------------------------------------------
cfg               = [];
cfg.channel       = 'EOGV';
cfg.showcallinfo  = 'no';

eogv              = ft_selectdata(cfg, data);                               % copy eogv

cfg               = [];
cfg.channel       = 'EOGH';
cfg.showcallinfo  = 'no';

eogh              = ft_selectdata(cfg, data);                               % copy eogh

cfg               = [];
cfg.reref         = 'yes';                                                  % enable re-referencing
if ~iscell(refchannel)
  cfg.refchannel    = {refchannel, 'REF'};                                  % specify new reference
else
  cfg.refchannel    = [refchannel, {'REF'}];
end
cfg.implicitref   = 'REF';                                                  % add implicit channel 'REF' to the channels
cfg.refmethod     = 'avg';                                                  % average over selected electrodes
cfg.channel       = {'all', '-EOGH', '-EOGV'};                              % use all channels except eogv and eogh
cfg.trials        = 'all';                                                  % use all trials
cfg.feedback      = 'no';                                                   % feedback should not be presented
cfg.showcallinfo  = 'no';                                                   % prevent printing the time and memory after each function call

fprintf('Re-reference data...\n');
data        = ft_preprocessing(cfg, data);
data.label  = data.label';

cfg               = [];
cfg.showcallinfo  = 'no';
ft_info off;
fsample       = data.fsample;
data          = ft_appenddata(cfg, data, eogv, eogh);                       % add eogv and eogh
data.fsample  = fsample;
ft_info on;

end
