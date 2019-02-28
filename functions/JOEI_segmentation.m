function [ data ] = JOEI_segmentation(cfg, data )
% JOEI_SEGMENTATION segments the data of each condition into segments with 
% a certain length
%
% Use as
%   [ data ] = JOEI_segmentation( cfg, data )
%
% where the input data can be the result from JOEI_IMPORTDATASET, 
% JOEI_PREPROCESSING
%
% The configuration options are
%   cfg.length    = length of segments (excepted values: 0.2, 1, 5, 10 seconds, default: 1)
%   cfg.overlap   = percentage of overlapping (range: 0 ... 1, default: 0)
%
% This function requires the fieldtrip toolbox.
%
% See also JOEI_IMPORTDATASET, JOEI_PREPROCESSING, FT_REDEFINETRIAL,
% JOEI_DATASTRUCTURE

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
segLength = ft_getopt(cfg, 'length', 1);
overlap   = ft_getopt(cfg, 'overlap', 0);

possibleLengths = [0.2, 1, 2, 5, 10];

if ~any(ismember(possibleLengths, segLength))
  error('Excepted cfg.length values are only 0.2, 1, 2, 5 and 10 seconds');
end

% -------------------------------------------------------------------------
% Segmentation settings
% -------------------------------------------------------------------------
cfg                 = [];
cfg.feedback        = 'no';
cfg.showcallinfo    = 'no';
cfg.trials          = 'all';                                                  
cfg.length          = segLength;
cfg.overlap         = overlap;

% -------------------------------------------------------------------------
% Segmentation
% -------------------------------------------------------------------------
fprintf('<strong>Segment data in segments of %d sec...</strong>\n', ...
        segLength);

ft_info off;
ft_warning off;

data = ft_redefinetrial(cfg, data);

ft_info on;
ft_warning on;
