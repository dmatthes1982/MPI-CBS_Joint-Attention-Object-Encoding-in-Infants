function [ data ] = JOEI_importDataset(cfg)
% JOEI_IMPORTDATASET imports one specific dataset recorded with a device 
% from brain vision.
%
% Use as
%   [ data ] = JOEI_importDataset(cfg)
%
% The configuration options are
%   cfg.path          = source path (i.e. '/data/pt_01904/eegData/EEG_JOEI_rawData/')
%   cfg.part          = number of participant
%   cfg.continuous    = 'yes' or 'no' (default: 'no')
%   cfg.prestim       = define pre-Stimulus offset in seconds (default: 0)
%   cfg.rejectoverlap = reject first of two overlapping trials, 'yes' or 'no' (default: 'yes')
%
% You can use relativ path specifications (i.e. '../../MATLAB/data/') or 
% absolute path specifications like in the example. Please be aware that 
% you have to mask space signs of the path names under linux with a 
% backslash char (i.e. '/home/user/test\ folder')
%
% This function requires the fieldtrip toolbox.
%
% See also FT_PREPROCESSING, JOEI_DATASTRUCTURE

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
path          = ft_getopt(cfg, 'path', []);
part          = ft_getopt(cfg, 'part', []);
continuous    = ft_getopt(cfg, 'continuous', 'no');
prestim       = ft_getopt(cfg, 'prestim', 0);
rejectoverlap = ft_getopt(cfg, 'rejectoverlap', 'yes');

if isempty(path)
  error('No source path is specified!');
end

if isempty(part)
  error('No specific participant is defined!');
end

headerfile = sprintf('%sJOEI_%02d.vhdr', path, part);

if strcmp(continuous, 'no')
  % -----------------------------------------------------------------------
  % Load general definitions
  % -------------------------------------------------------------------------
  filepath = fileparts(mfilename('fullpath'));
  load(sprintf('%s/../general/JOEI_generalDefinitions.mat', filepath), ...
     'generalDefinitions');

  % definition of all possible stimuli
  eventvalues   = generalDefinitions.condMark;
                
  % -----------------------------------------------------------------------
  % Generate trial definition
  % -----------------------------------------------------------------------
  % basis configuration for data import
  cfg                     = [];
  cfg.dataset             = headerfile;
  cfg.trialfun            = 'ft_trialfun_general';
  cfg.trialdef.eventtype  = 'Stimulus';
  cfg.trialdef.prestim    = prestim;
  cfg.showcallinfo        = 'no';
  cfg.feedback            = 'error';
  cfg.trialdef.eventvalue = eventvalues;

  cfg = ft_definetrial(cfg);                                                % generate config for segmentation
  if isfield(cfg, 'notification')
    cfg = rmfield(cfg, {'notification'});                                   % workarround for mergeconfig bug
  end
  
  cfg.trl = cfg.trl(cfg.trl(:,1) ~= cfg.trl(:,2), :);                       % reject outdated markers
  
  for i = size(cfg.trl):-1:2                                                % reject duplicates
    if cfg.trl(i,4) == cfg.trl(i-1,4)
      cfg.trl(i-1,:) = [];
    end
  end
  
  if strcmp(rejectoverlap, 'yes')                                           % if overlapping trials should be rejected
    overlapping = find(cfg.trl(1:end-1,2) > cfg.trl(2:end, 1));             % in case of overlapping trials, remove the first of theses trials
    if ~isempty(overlapping)
      for i = 1:1:length(overlapping)
        warning off backtrace;
        warning(['trial %d with marker ''S%3d''  will be removed due to '...
               'overlapping data with its successor.'], ...
               overlapping(i), cfg.trl(overlapping(i), 4));
        warning on backtrace;
      end
      cfg.trl(overlapping, :) = [];
    end
  end
else
  cfg                     = [];
  cfg.dataset             = headerfile;
  cfg.showcallinfo        = 'no';
  cfg.feedback            = 'no';
end

% -------------------------------------------------------------------------
% Data import
% -------------------------------------------------------------------------
cfg.channel = {'all', '-T7_1', '-T7_2', '-T8_1', '-T8_2', ...               % exclude all general bad channels
               '-PO9_1', '-PO9_2', '-PO10_1','-PO10_2', ...
               '-P7_1', '-P7_2', '-P8_1', '-P8_2'};
data = ft_preprocessing(cfg);                                               % import data

data.label = strrep(data.label(1:26), '_1', '');                            % extract only the child's data
for i=1:1:length(data.trial)
  data.trial{i} = data.trial{i}(1:26,:);
end

end
