function [ cfgArtifacts ] = JOEI_databrowser( cfg, data )
% JOEI_DATABROWSER displays a certain joint attention imitation project 
% dataset using a appropriate scaling.
%
% Use as
%   JOEI_databrowser( cfg, data )
%
% where the input can be the result of JOEI_IMPORTDATASET,
% JOEI_PREPROCESSING or JOEI_SEGMENTATION
%
% The configuration options are
%   cfg.part        = number of dyad (no default value)
%   cfg.artifact    = structure with artifact specification, e.g. output of FT_ARTIFACT_THRESHOLD (default: [])
%   cfg.channel     = channels of interest (default: 'all')
%   cfg.ylim        = vertical scaling (default: [-100 100]);
%   cfg.blocksize   = duration in seconds for cutting the data up (default: [])
%   cfg.plotevents  = 'yes' or 'no' (default: 'yes'), if it is no raw data
%                     you have to specify cfg.dyad otherwise the events
%                     will be not found and therefore not plotted
%
% This function requires the fieldtrip toolbox
%
% See also JOEI_IMPORTDATASET, JOEI_PREPROCESSING, JOEI_SEGMENTATION, 
% JOEI_DATASTRUCTURE, FT_DATABROWSER

% Copyright (C) 2018-2019, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
part        = ft_getopt(cfg, 'part', []);
artifact    = ft_getopt(cfg, 'artifact', []);
channel     = ft_getopt(cfg, 'channel', 'all');
ylim        = ft_getopt(cfg, 'ylim', [-100 100]);
blocksize   = ft_getopt(cfg, 'blocksize', []);
plotevents  = ft_getopt(cfg, 'plotevents', 'yes');

if isempty(part)                                                            % if dyad number is not specified
  event = [];                                                               % the associated markers cannot be loaded and displayed
else                                                                        % else, load the stimulus markers 
  source = '/data/pt_01904/eegData/EEG_JOEI_rawData/';
  filename = sprintf('JOEI_%02d.vhdr', part);
  path = strcat(source, filename);
  event = ft_read_event(path);                                              % read stimulus markers
end

% -------------------------------------------------------------------------
% Configure and start databrowser
% -------------------------------------------------------------------------
cfg                 = [];
cfg.ylim            = ylim;
cfg.blocksize       = blocksize;
cfg.viewmode        = 'vertical';
cfg.artfctdef       = artifact;
cfg.continuous      = 'no';
cfg.channel         = channel;
cfg.plotevents      = plotevents;
cfg.event           = event;
cfg.artifactalpha   = 0.7;
cfg.showcallinfo    = 'no';

fprintf('Databrowser\n');

if nargout > 0
  cfgArtifacts = ft_databrowser(cfg, data);
else
  ft_databrowser(cfg, data);
end
    
end
