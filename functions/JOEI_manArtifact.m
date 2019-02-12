function [ cfgAllArt ] = JOEI_manArtifact( cfg, data )
% JOEI_MANARTIFACT - this function could be use to is verify the automatic 
% detected artifacts remove some of them or add additional ones if
% required.
%
% Use as
%   [ cfgAllArt ] = JOEI_manArtifact(cfg, data)
%
% where data has to be a result of JOEI_SEGMENTATION
%
% The configuration options are
%   cfg.artifact  = output of JOEI_autoArtifact (see file JOEI_dxx_05a_autoart_yyy.mat)
%   cfg.part      = number of dyad (only necessary for adding markers to databrowser view) (default: []) 
%
% This function requires the fieldtrip toolbox.
%
% See also JOEI_SEGMENTATION, JOEI_DATABROWSER

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
artifact  = ft_getopt(cfg, 'artifact', []);
part      = ft_getopt(cfg, 'part', []);

% -------------------------------------------------------------------------
% Initialize settings, build output structure
% -------------------------------------------------------------------------
cfg             = [];
cfg.part        = part;
cfg.channel     = {'all', '-V1', '-V2'};
cfg.ylim        = [-100 100];

% -------------------------------------------------------------------------
% Check Data
% -------------------------------------------------------------------------
fprintf('\n<strong>Search visually for artifacts...</strong>\n');
cfg.artifact = artifact.artfctdef;
ft_warning off;
JOEI_easyArtfctmapPlot(artifact);                                           % plot artifact map
fig = gcf;                                                                  % default position is [560 528 560 420]
fig.Position = [0 528 560 420];                                             % --> first figure will be placed on the left side of figure 2
cfgAllArt = JOEI_databrowser(cfg, data);                                    % show databrowser view in figure 2
close all;                                                                  % figure 1 will be closed with figure 2
cfgAllArt = keepfields(cfgAllArt, {'artfctdef', 'showcallinfo'});

ft_warning on;

end
