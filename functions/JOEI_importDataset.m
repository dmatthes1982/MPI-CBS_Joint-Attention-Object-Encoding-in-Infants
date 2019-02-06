function [ data, cfg_events ] = JOEI_importDataset(cfg)
% JOEI_IMPORTDATASET imports one specific dataset recorded with a device 
% from brain vision.
%
% Use as
%   [ data, cfg_events ] = JOEI_importDataset(cfg)
%
% The configuration options are
%   cfg.path          = source path (i.e. '/data/pt_01904/eegData/EEG_JOEI_rawData/')
%   cfg.part          = number of participant
%   cfg.noichan       = channels which are not of interest (default: [])
%   cfg.continuous    = 'yes' or 'no' (default: 'no')
%   cfg.prestim       = define pre-Stimulus offset in seconds (default: 0)
%   cfg.rejectoverlap = reject first of two overlapping trials, 'yes' or 'no' (default: 'yes')
%
% You can use relativ path specifications (i.e. '../../MATLAB/data/') or 
% absolute path specifications like in the example. Please be aware that 
% you have to mask space signs of the path names under linux with a 
% backslash char (i.e. '/home/user/test\ folder')
%
% The output of this function consists of two elements. The first one
% contains the imported raw data. The second one holds different trl
% definitions which are describing moments of mutual gaze, mutual object
% look and infant object look within the different conditions.
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
noichan       = ft_getopt(cfg, 'noichan', []);
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
  % -----------------------------------------------------------------------
  filepath = fileparts(mfilename('fullpath'));
  load(sprintf('%s/../general/JOEI_generalDefinitions.mat', filepath), ...
     'generalDefinitions');

  % definition of all possible stimuli
  eventvalues   = generalDefinitions.condMark;

  % -----------------------------------------------------------------------
  % Check, if mofication of marker file in interact was done properly
  % -----------------------------------------------------------------------
  event   = ft_read_event(headerfile);                                      % import all existing events from marker file
  control = event(ismember({event(:).type}, 'Stimulus'));                   % extract the control marker
  control = control(ismember({control(:).value}, 'control'));

  response = event(ismember({event(:).type}, 'Response'));                  % extract the video recording triggers
  response = response(ismember({response(:).value}, 'R128'));

  if (control(1).sample == response(1).sample)
    fprintf('Video start trigger and the control marker are matching.\n');
  else
    error(['Video start trigger and the control marker don''t match! '...
            'Please check your Interact export settings.\n']);
  end

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
if ~isempty(noichan)
  noichan = cellfun(@(x) strcat('-', x), noichan, ...
                          'UniformOutput', false);
  noichanp1 = cellfun(@(x) strcat(x, '_1'), noichan, ...
                          'UniformOutput', false);
  noichanp2 = cellfun(@(x) strcat(x, '_2'), noichan, ...
                          'UniformOutput', false);
  cfg.channel = [ {'all'} noichanp1 noichanp2 ];                            % exclude channels which are not of interest
else
  cfg.channel = 'all';
end

data = ft_preprocessing(cfg);                                               % import data

numOfChan = numel(data.label)/2;

data.label = strrep(data.label(1:numOfChan), '_1', '');                     % extract only the child's data
for i=1:1:length(data.trial)
  data.trial{i} = data.trial{i}(1:numOfChan,:);
end

% -------------------------------------------------------------------------
% Extract trial definitions for the following events:
% infant object look, mutual gaze, mutual object look
% -------------------------------------------------------------------------
marker  = event(ismember({event(:).type}, 'gaze_inf'));                     % infant object look
object  = marker(ismember({marker(:).value}, 'object'));

gaze_inf.object.trl(:,1) = [object(:).sample];
gaze_inf.object.trl(:,2) = [object(:).sample] + [object(:).duration] - 1;
offset = {object(:).offset};
idx = cellfun(@isempty, offset);
offset(idx) = {0};
gaze_inf.object.trl(:,3) = cell2mat(offset);

for i = size(gaze_inf.object.trl,1):-1:1
  startWithin = any(gaze_inf.object.trl(i,1) >= data.sampleinfo(:,1) & ...
                    gaze_inf.object.trl(i,1) <= data.sampleinfo(:,2));
  stopWithin  = any(gaze_inf.object.trl(i,2) >= data.sampleinfo(:,1) & ...
                    gaze_inf.object.trl(i,2) <= data.sampleinfo(:,2));
  status      = startWithin | stopWithin;

  if status == false
    cprintf([1,0.5,0], ['INFO: Event gaze_inf.object [%d to %d] cannot '...
          'be attributed to any trial. It will be removed.\n'], ...
          gaze_inf.object.trl(i,1), gaze_inf.object.trl(i,2));
    gaze_inf.object.trl(i,:) = [];
  end
end

fprintf('\n');

marker  = event(ismember({event(:).type}, 'analysis_gaze'));                % mutual gaze
mgaze   = marker(ismember({marker(:).value}, 'MutualGaze'));

analysis_gaze.MutualGaze.trl(:,1) = [mgaze(:).sample];
analysis_gaze.MutualGaze.trl(:,2) = [mgaze(:).sample] + ...
                                    [mgaze(:).duration] - 1;
offset = {mgaze(:).offset};
idx = cellfun(@isempty, offset);
offset(idx) = {0};
analysis_gaze.MutualGaze.trl(:,3) = cell2mat(offset);

marker  = event(ismember({event(:).type}, 'analysis_gaze'));                % mutual object look
mobject = marker(ismember({marker(:).value}, 'MutualObject'));

analysis_gaze.MutualObject.trl(:,1) = [mobject(:).sample];
analysis_gaze.MutualObject.trl(:,2) = [mobject(:).sample] + ...
                                    [mobject(:).duration] - 1;
offset = {mobject(:).offset};
idx = cellfun(@isempty, offset);
offset(idx) = {0};
analysis_gaze.MutualObject.trl(:,3) = cell2mat(offset);

cfg_events = [];
cfg_events.gaze_inf       = gaze_inf;
cfg_events.analysis_gaze  = analysis_gaze;

end
