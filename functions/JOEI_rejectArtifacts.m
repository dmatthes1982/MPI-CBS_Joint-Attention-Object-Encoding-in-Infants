function [ data ] = JOEI_rejectArtifacts( cfg, data )
% JOEI_REJECTARTIFACTS is a function which removes trials containing 
% artifacts. It returns clean data.
%
% Use as
%   [ data ] = JOEI_rejectartifacts( cfg, data )
%
% where data can be a result of JOEI_SEGMENTATION
%
% The configuration options are
%   cfg.artifact  = output of JOEI_autoArtifact or JOEI_manArtifact 
%                   (see file JOEI_pxx_05a_autoArt_yyy.mat, JOEI_pxx_05b_allArt_yyy.mat)
%   cfg.reject    = 'none', 'partial','nan', or 'complete' (default = 'complete')
%
% This function requires the fieldtrip toolbox.
%
% See also JOEI_SEGMENTATION, JOEI_MANARTIFACT and JOEI_AUTOARTIFACT 

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get config options
% -------------------------------------------------------------------------
artifact  = ft_getopt(cfg, 'artifact', []);
reject    = ft_getopt(cfg, 'reject', 'complete');

if isempty(artifact)
  error('cfg.artifact has to be defined');
end

if ~strcmp(reject, 'complete')
  artifact.artfctdef.reject       = reject;
  artifact.artfctdef.minaccepttim = 0.2;
end

% -------------------------------------------------------------------------
% Clean Data
% -------------------------------------------------------------------------
fprintf('\n<strong>Cleaning data...</strong>\n');

ft_warning off;

data = ft_rejectartifact(artifact, data);
  
ft_warning on;

end
