function JOEI_createTbl( cfg )
% JOEI_CREATETBL generates '*.xls' files for the documentation of the data 
% processing process. Currently one type of doc file is only supported.
%
% Use as
%   JOEI_createTbl( cfg )
%
% The configuration options are
%   cfg.desFolder   = destination folder (default: '/data/pt_01904/eegData/EEG_JOEI_processedData/00_settings/')
%   cfg.type        = type of documentation file (options: 'settings')
%   cfg.sessionStr  = number of session, format: %03d, i.e.: '003' (default: '001')
%
% Explanation:
%   type settings - holds information about the selectable values: fsample, reference, etc.
%
% This function requires the fieldtrip toolbox.

% Copyright (C) 2018-2019, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get config options
% -------------------------------------------------------------------------
desFolder   = ft_getopt(cfg, 'desFolder', ...
          '/data/pt_01904/eegData/EEG_JOEI_processedData/00_settings/');
type        = ft_getopt(cfg, 'type', 'settings');
sessionStr  = ft_getopt(cfg, 'sessionStr', []);

if isempty(sessionStr)
  error('cfg.sessionStr has to be specified');
end

% -------------------------------------------------------------------------
% Load general definitions
% -------------------------------------------------------------------------
filepath = fileparts(mfilename('fullpath'));
load(sprintf('%s/../general/JOEI_generalDefinitions.mat', filepath), ...
     'generalDefinitions');

% -------------------------------------------------------------------------
% Create table
% -------------------------------------------------------------------------
switch type
  case 'settings'
    T = table(1,{'unknown'},0,{'unknown'},{'unknown'},{'unknown'},...
              {'unknown'},{'unknown'},0,{'unknown'},0,0,{'unknown'});
    T.Properties.VariableNames = ...
        {'participant', 'noiChan', 'prestim', 'badChan', 'reference', ...
         'bandpass', 'ICAcomp', 'artMethod', 'artThreshold', ...
         'artChan', 'powSeglength', 'powOverlap', 'artRejectPow'};
    filepath = [desFolder type '_' sessionStr '.xls'];
    writetable(T, filepath);
  otherwise
    error('Wrong cfg.type! It has to be ''settings''.');
end

end
