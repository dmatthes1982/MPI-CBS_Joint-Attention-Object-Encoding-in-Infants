function [ data ] = JOEI_preprocessing( cfg, data )
% JOEI_PREPROCESSING does the basic bandpass filtering of the raw data
% and is calculating the EOG signals.
%
% Use as
%   [ data ] = JOEI_preprocessing(cfg, data)
%
% where the input data have to be the result from JOEI_IMPORTATASET
%
% The configuration options are
%   cfg.bpfreq            = passband range [begin end] (default: [0.1 48])
%   cfg.bpfilttype        = bandpass filter type, 'but' or 'fir' (default: fir')
%   cfg.bpinstabilityfix  = deal with filter instability, 'no' or 'split' (default: 'no')
%   cfg.badChan           = bad channels which should be excluded (default: [])
%
% This function requires the fieldtrip toolbox.
%
% See also JOEI_IMPORTDATASET, JOEI_SELECTBADCHAN, FT_PREPROCESSING,
% JOEI_DATASTRUCTURE

% Copyright (C) 2018-2019, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
bpfreq            = ft_getopt(cfg, 'bpfreq', [0.1 48]);
bpfilttype        = ft_getopt(cfg, 'bpfilttype', 'fir');
bpinstabilityfix  = ft_getopt(cfg, 'bpinstabilityfix', 'no');
badChan           = ft_getopt(cfg, 'badChan', []);

% -------------------------------------------------------------------------
% Channel configuration
% -------------------------------------------------------------------------
if ~isempty(badChan)
  badChan = cellfun(@(x) sprintf('-%s', x), badChan, ...
                 'UniformOutput', false);
end  

Chan = [{'all'} badChan];                                                   % do bandpassfiltering only with good channels and remove the bad once

% -------------------------------------------------------------------------
% Basic bandpass filtering
% -------------------------------------------------------------------------

% general filtering
cfg                   = [];
cfg.bpfilter          = 'yes';                                              % use bandpass filter
cfg.bpfreq            = bpfreq;                                             % bandpass range
cfg.bpfilttype        = bpfilttype;                                         % bandpass filter type
cfg.bpinstabilityfix  = bpinstabilityfix;                                   % deal with filter instability
cfg.trials            = 'all';                                              % use all trials
cfg.feedback          = 'no';                                               % feedback should not be presented
cfg.showcallinfo      = 'no';                                               % prevent printing the time and memory after each function call
cfg.channel           = Chan;

% -------------------------------------------------------------------------
% Preprocessing
% -------------------------------------------------------------------------
fprintf('Filter data (basic bandpass)...\n');
data = ft_preprocessing(cfg, data);

fprintf('Estimate EOG signals...\n');
data = estimEOG(data);

end

% -------------------------------------------------------------------------
% Local functions
% -------------------------------------------------------------------------
function [ data_out ] = estimEOG( data_in )

cfg               = [];
cfg.channel       = {'F9', 'F10'};
cfg.reref         = 'yes';
cfg.refchannel    = 'F10';
cfg.showcallinfo  = 'no';
cfg.feedback      = 'no';

eogh              = ft_preprocessing(cfg, data_in);
eogh.label{1}     = 'EOGH';

cfg               = [];
cfg.channel       = 'EOGH';
cfg.showcallinfo  = 'no';

eogh              = ft_selectdata(cfg, eogh);

cfg               = [];
cfg.channel       = {'V1', 'V2'};
cfg.reref         = 'yes';
cfg.refchannel    = 'V2';
cfg.showcallinfo  = 'no';
cfg.feedback      = 'no';

eogv              = ft_preprocessing(cfg, data_in);
eogv.label{1}     = 'EOGV';

cfg               = [];
cfg.channel       = 'EOGV';
cfg.showcallinfo  = 'no';

eogv              = ft_selectdata(cfg, eogv);

cfg               = [];
cfg.showcallinfo  = 'no';
ft_info off;
data_out          = ft_appenddata(cfg, data_in, eogv, eogh);
data_out.fsample  = data_in.fsample;
ft_info on;

end
