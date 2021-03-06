function [ cfgAutoArt ] = JOEI_autoArtifact( cfg, data, varargin )
% JOEI_AUTOARTIFACT marks timeslots as an artifact in which the values of
% specified channels exeeds either a min-max level, a defined range, a
% standard deviation threshold or a defined mutiple of the median absolute
% deviation.
%
% Use as
%   [ cfgAutoArt ] = JOEI_autoArtifact(cfg, data, varargin)
%
% where data have to be a result of JOEI_PREPROCESSING or JOEI_CONCATDATA
%
% The configuration options are
%   cfg.channel     = cell-array with channel labels (default: {'Cz', 'O1', 'O2'}))
%   cfg.method      = 'minmax', 'range', 'stddev' or 'mad' (default: 'minmax')
%   cfg.deadsegs    = 'yes' or 'no', estimating segments in which at least one channel is dead or in saturation
%                     if cfg.deathsegs = 'yes', varargin has to be data_raw
%   cfg.badchan     = vector of channels which were marked as bad and repaired during preprocessing,
%                     theses channels will be excluded from the dead segments detection.
%   cfg.sliding     = use a sliding window, 'yes' or 'no', (default: 'no')
%   cfg.winsize     = size of sliding window (default: 200 ms)
%                     only required if cfg.sliding = 'yes'
%   cfg.continuous  = data is continuous ('yes' or 'no', default: 'no')
%                     only required, if cfg.sliding = 'no'
%
% Specify the trial specification, which will later be used with artifact rejection
%   cfg.trllength   = trial length (default: 200 ms)
%   cfg.overlap     = amount of window overlapping in percentage (default: 0, permitted values: 0 or 50)
%
% Specify at least one of theses thresholds
%   cfg.min         = lower limit in uV for cfg.method = 0 (default: -75) 
%   cfg.max         = upper limit in uV for cfg.method = 0 (default: 75)
%   cfg.range       = range in uV (default: 200)
%   cfg.stddev      = standard deviation threshold in uV (default: 50)
%                     only usable, cfg.sliding = 'yes'
%   cfg.mad         = multiple of median absolute deviation (default: 3)
%
% This function requires the fieldtrip toolbox.
%
% See also JOEI_GENTRL, JOEI_PREPROCESSING, JOEI_SEGMENTATION, 
% JOEI_CONCATDATA, FT_ARTIFACT_THRESHOLD

% Copyright (C) 2018-2021, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
chan        = ft_getopt(cfg, 'channel', {'Cz', 'O1', 'O2'});                % channels to test
method      = ft_getopt(cfg, 'method', 'minmax');                           % artifact detection method
deadsegs    = ft_getopt(cfg, 'deadsegs', 'no');                            	% estimating segments in which at least one channel is dead or in saturation
badchan     = ft_getopt(cfg, 'badchan', []);                                % set of channels which should be excluded from the bad channel detection
sliding     = ft_getopt(cfg, 'sliding', 'no');                              % use a sliding window

chan = ft_channelselection(chan, data.label);                               % transform channel of interest specification in a processable form

if ~(strcmp(sliding, 'no') || strcmp(sliding, 'yes'))                       % validate cfg.sliding
  error('Sliding has to be either ''yes'' or ''no''!');
end

trllength   = ft_getopt(cfg, 'trllength', 200);                             % subtrial length to which the detected artifacts will be extended
overlap     = ft_getopt(cfg, 'overlap', 0);                                 % overlapping between the subtrials

if ~(overlap ==0 || overlap == 50)                                          % only non overlapping or 50% is allowed to simplify this function
  error('Currently there is only overlapping of 0 or 50% permitted');
end

cfgTrl          = [];
cfgTrl.length   = trllength;
cfgTrl.overlap  = overlap;
trl = JOEI_genTrl(cfgTrl, data);                                            % generate subtrial specification

trllength = trllength * data.fsample/1000;                                  % convert subtrial length from milliseconds into number of samples

switch method                                                               % get and check method dependent config input
  case 'minmax'
    minVal    = ft_getopt(cfg, 'min', -75);
    maxVal    = ft_getopt(cfg, 'max', 75);
    if strcmp(sliding, 'no')
      continuous  = ft_getopt(cfg, 'continuous', 'no');
    else
      error('Method ''minmax'' is not supported with option sliding=''yes''');
    end
  case 'range'
    range     = ft_getopt(cfg, 'range', 200);
    if strcmp(sliding, 'no')
      continuous  = ft_getopt(cfg, 'continuous', 0);
    else
      winsize     = ft_getopt(cfg, 'winsize', 200);
    end
  case 'stddev'
    stddev     = ft_getopt(cfg, 'stddev', 50);
    if strcmp(sliding, 'no')
      error('Method ''stddev'' is not supported with option sliding=''no''');
    else
      winsize     = ft_getopt(cfg, 'winsize', 200);
    end
  case 'mad'
    mad     = ft_getopt(cfg, 'mad', 3);
    if strcmp(sliding, 'no')
      error('Method ''mad'' is not supported with option sliding=''no''');
    else
      winsize     = ft_getopt(cfg, 'winsize', 200);
    end
  otherwise
    error('Only ''minmax'', ''range'' and ''stdev'' are supported methods');
end

if strcmp(deadsegs, 'yes')
  data_raw = varargin{1};
end

% -------------------------------------------------------------------------
% Artifact detection settings
% -------------------------------------------------------------------------
cfg = [];
cfg.method                        = method;
cfg.sliding                       = sliding;
cfg.artfctdef.threshold.channel   = chan;                                   % specify channels of interest
cfg.artfctdef.threshold.bpfilter  = 'no';                                   % use no additional bandpass
cfg.artfctdef.threshold.bpfreq    = [];                                     % use no additional bandpass
cfg.artfctdef.threshold.onset     = [];                                     % just defined to get a similar output from ft_artifact_threshold and artifact_threshold
cfg.artfctdef.threshold.offset    = [];                                     % just defined to get a similar output from ft_artifact_threshold and artifact_threshold
cfg.showcallinfo                  = 'no';

switch method                                                               % set method dependent config parameters
  case 'minmax'
    cfg.artfctdef.threshold.min     = minVal;                               % minimum threshold
    cfg.artfctdef.threshold.max     = maxVal;                               % maximum threshold
    if strcmp(sliding, 'no')
      cfg.continuous = continuous;
      cfg.trl        = trl;
    end
  case 'range'
    cfg.artfctdef.threshold.range   = range;                                % range
    if strcmp(sliding, 'yes')
      cfg.artfctdef.threshold.winsize = winsize;
      cfg.artfctdef.threshold.trl = trl;
    else
      cfg.continuous = continuous;
      cfg.trl        = trl;
    end
  case 'stddev'
    cfg.artfctdef.threshold.stddev  = stddev;                               % stddev
    if strcmp(sliding, 'yes')
      cfg.artfctdef.threshold.winsize = winsize;
      cfg.artfctdef.threshold.trl = trl;
    end
  case 'mad'
    cfg.artfctdef.threshold.mad  = mad;                                     % mad
    if strcmp(sliding, 'yes')
      cfg.artfctdef.threshold.winsize = winsize;
      cfg.artfctdef.threshold.trl = trl;
    end
end

% -------------------------------------------------------------------------
% Estimate artifacts
% -------------------------------------------------------------------------
ft_info off;

fprintf('<strong>Estimate artifacts...</strong>\n');
cfgAutoArt = artifact_detect(cfg, data);
cfgAutoArt = keepfields(cfgAutoArt, {'artfctdef', 'showcallinfo'});

if strcmp(deadsegs, 'yes')
  if (isempty(badchan))                                                     % determine the channels of interest
    chanOfInterest = chan;                                                  % remove corrected channels
  else
    if ischar(chan)
      chanOfInterest = {chan};
    else
      chanOfInterest = chan;
    end
    tf = contains(chanOfInterest, badchan);
    chanOfInterest = chanOfInterest(~tf);
    if find(contains(chanOfInterest, 'all'))
      tmp = cellfun(@(X) ['-' X], badchan, 'UniformOutput', false);
      chanOfInterest = [chanOfInterest tmp'];
    end
  end

  fprintf('<strong>Run detection of segments in which at least one channel is dead or in saturation...</strong>\n');
  cfg2 = [];
  cfg2.method                        = 'zero';
  cfg2.sliding                       = 'yes';
  cfg2.artfctdef.threshold.channel   = chanOfInterest;                      % set channels of interest
  cfg2.artfctdef.threshold.bpfilter  = 'no';                                % use no additional bandpass
  cfg2.artfctdef.threshold.bpfreq    = [];                                  % use no additional bandpass
  cfg2.artfctdef.threshold.onset     = [];                                  % just defined to get a similar output from ft_artifact_threshold and artifact_threshold
  cfg2.artfctdef.threshold.offset    = [];                                  % just defined to get a similar output from ft_artifact_threshold and artifact_threshold
  cfg2.artfctdef.threshold.zero      = 1.5;
  cfg2.artfctdef.threshold.winsize   = 200;
  cfg2.artfctdef.threshold.trl       = trl;
  cfg2.showcallinfo                  = 'no';

  cfgDeadSeg = artifact_detect(cfg2, data_raw);                             % find dead segment artifacts
  if ~isempty(badchan)                                                      % adjust matrix size to auto artifact map
    tmpmap = cfgDeadSeg.artfctdef.threshold.artfctmap;

    pos = find(contains(cfgAutoArt.artfctdef.threshold.channel, ...
                          badchan)) - 1;
    pos = sort(pos);

    for i=1:1:length(pos)
      tmpmap = cellfun(@(X) ...
                [X(1:pos(i),:); zeros(1, size(X,2)); X(pos(i)+1:end,:)], ...
                tmpmap, 'UniformOutput', false);
    end

    cfgDeadSeg.artfctdef.threshold.artfctmap = tmpmap;
  end

  cfgAutoArt.artfctdef.threshold.artfctmap = cellfun(@(X,Y) or(X,Y), ...    % merge artifact maps
        cfgAutoArt.artfctdef.threshold.artfctmap, ...
        cfgDeadSeg.artfctdef.threshold.artfctmap, 'UniformOutput', false);
  cfgAutoArt.artfctdef.threshold.artifact = ...                             % combine artifact list
            [cfgAutoArt.artfctdef.threshold.artifact; ...
              cfgDeadSeg.artfctdef.threshold.artifact];
  cfgAutoArt.artfctdef.threshold.zero = 1.5;                                % add zero-artifact threshold
end

[cfgAutoArt.artfctdef.threshold, cfgAutoArt.badNum] = ...                   % extend artifacts to subtrial definition
                combineArtifacts( overlap, trllength, ...
                                  cfgAutoArt.artfctdef.threshold );
fprintf('%d segments with artifacts detected!\n', cfgAutoArt.badNum);

cfgAutoArt.trialsNum = size(trl, 1);

if (cfgAutoArt.badNum == cfgAutoArt.trialsNum)
  warning(['All trials are marked as bad, it is recommended to recheck '...
            'the channels quality!']);
else
  ratio = (cfgAutoArt.badNum*100)/cfgAutoArt.trialsNum;
  if ratio < 66 
    color = [0,0.6,0];
  else
    color = [1,0.5,0];
  end
  cprintf(color, '%.2f percent of the data are including artifacts.\n', ...
          ratio);
end

if isfield(cfgAutoArt.artfctdef.threshold, 'artfctmap')
  artfctmap = cfgAutoArt.artfctdef.threshold.artfctmap;
  artfctmap = cellfun(@(x) sum(x, 2), artfctmap, 'UniformOutput', false);
  cfgAutoArt.badNumChan = nansum(cat(2,artfctmap{:}),2);
  
  cfgAutoArt.label = ft_channelselection(...
              cfgAutoArt.artfctdef.threshold.channel, data.label);
end

ft_info on;

end

% -------------------------------------------------------------------------
% SUBFUNCTION which selects the appropriate artifact detection method based
% on the selected config options
% -------------------------------------------------------------------------
function [ autoart ] = artifact_detect(cfgT, data_in)

method  = cfgT.method;
sliding = cfgT.sliding;
cfgT    = removefields(cfgT, {'method', 'sliding'});

if strcmp(sliding, 'yes')                                                   % sliding window --> use own artifacts_threshold function
  autoart = artifact_sliding_threshold(cfgT, data_in);
elseif strcmp(method, 'minmax')                                             % method minmax --> use own special_minmax_threshold function
  autoart = special_minmax_threshold(cfgT, data_in);
else                                                                        % no sliding window, no minmax method --> use ft_artifacts_threshold function
  autoart = ft_artifact_threshold(cfgT, data_in);
end

end

% -------------------------------------------------------------------------
% SUBFUNCTION which detects artifacts by using a sliding window
% -------------------------------------------------------------------------
function [ autoart ] = artifact_sliding_threshold(cfgT, data_in)

  numOfTrl  = length(data_in.trialinfo);                                    % get number of trials in the data
  winsize   = cfgT.artfctdef.threshold.winsize * data_in.fsample / 1000;    % convert window size from milliseconds to number of samples
  artifact  = zeros(0,2);                                                   % initialize artifact variable
  artfctmap{1,numOfTrl} = [];

  channel = ft_channelselection(cfgT.artfctdef.threshold.channel, ...
              data_in.label);

  for i = 1:1:numOfTrl
    data_in.trial{i} = data_in.trial{i}(ismember(data_in.label, ...         % prune the available data to the channels of interest
                        channel) ,:);
  end

  if isfield(cfgT.artfctdef.threshold, 'range')                             % check for range violations
    for i=1:1:numOfTrl
      tmpmin = movmin(data_in.trial{i}, winsize, 2);                        % get all minimum values
      tmpmin = prune_mat(tmpmin, winsize);                                  % remove useless results from the edges

      tmpmax = movmax(data_in.trial{i}, winsize, 2);                        % get all maximum values
      tmpmax = prune_mat(tmpmax, winsize);                                  % remove useless results from the edges

      tmp = abs(tmpmin - tmpmax);                                           % estimate a moving maximum difference

      artfctmap{i} = tmp > cfgT.artfctdef.threshold.range;                  % find all violations
      [artfctmap{i}, artifact] = estim_artifact_limits(artfctmap{i}, ...    % add artifact to the artifacts matrix, extend the violations in the map to the window size
                                    artifact, data_in.sampleinfo(i,1), ...
                                    channel, winsize);
    end
  elseif isfield(cfgT.artfctdef.threshold, 'stddev')                        % check for standard deviation violations
    for i=1:1:numOfTrl
      tmp = movstd(data_in.trial{i}, winsize, 0, 2);                        % estimate a moving standard deviation
      tmp = prune_mat(tmp, winsize);                                        % remove useless results from the edges

      artfctmap{i} = tmp > cfgT.artfctdef.threshold.stddev;                 % find all violations
      [artfctmap{i}, artifact] = estim_artifact_limits(artfctmap{i}, ...    % add artifact to the artifacts matrix, extend the violations in the map to the window size
                                    artifact, data_in.sampleinfo(i,1), ...
                                    channel, winsize);
    end
  elseif isfield(cfgT.artfctdef.threshold, 'zero')                          % check for standard deviation violations which indicating dead channels
    for i=1:1:numOfTrl
      tmp = movstd(data_in.trial{i}, winsize, 0, 2);                        % estimate a moving standard deviation
      tmp = prune_mat(tmp, winsize);                                        % remove useless results from the edges

      artfctmap{i} = tmp < cfgT.artfctdef.threshold.zero;                   % find all violations
      [artfctmap{i}, artifact] = estim_artifact_limits(artfctmap{i}, ...    % add artifact to the artifacts matrix, extend the violations in the map to the window size
                                    artifact, data_in.sampleinfo(i,1), ...
                                    channel, winsize);
    end
  elseif isfield(cfgT.artfctdef.threshold, 'mad')                           % check for median absolute deviation violations
    data_continuous = cat(2, data_in.trial{:});                             % concatenate all trials
    tmpmad = mad(data_continuous, 1, 2);                                    % estimate the median absolute deviation of the whole data
    tmpmedian = median(data_continuous, 2);                                 % estimate the median of the data

    for i=1:1:numOfTrl
      tmpmin = movmin(data_in.trial{i}, winsize, 2);                        % get all minimum values
      tmpmin = prune_mat(tmpmin, winsize);                                  % remove useless results from the edges

      tmpmax = movmax(data_in.trial{i}, winsize, 2);                        % get all maximum values
      tmpmax = prune_mat(tmpmax, winsize);                                  % remove useless results from the edges

      tmpdiffmax = abs(tmpmax - tmpmedian);                                 % estimate the differences between the maximum values and the median
      tmpdiffmin = abs(tmpmin - tmpmedian);                                 % estimate the differences between the minimum values and the median
      tmp = cat(3, tmpdiffmax, tmpdiffmin);                                 % select always the maximum absolute difference
      tmp = max(tmp, [], 3);

      artfctmap{i} = tmp > cfgT.artfctdef.threshold.mad*tmpmad;             % find all violations
      [artfctmap{i}, artifact] = estim_artifact_limits(artfctmap{i}, ...    % add artifact to the artifacts matrix, extend the violations in the map to the window size
                                    artifact, data_in.sampleinfo(i,1), ...
                                    channel, winsize);
    end
  end

  autoart.artfctdef     = cfgT.artfctdef;                                   % generate output data structure
  autoart.showcallinfo  = cfgT.showcallinfo;
  autoart.artfctdef.threshold.artifact  = artifact;
  autoart.artfctdef.threshold.artfctmap = artfctmap;
  autoart.artfctdef.threshold.sliding   = 'yes';

end

% -------------------------------------------------------------------------
% SUBFUNCTION which prunes useless results from matrix
% -------------------------------------------------------------------------
function [ mat ] = prune_mat(mat, winsize)
  if mod(winsize, 2)                                                        % remove useless results from the edges
    mat = mat(:, (winsize/2 + 1):(end-winsize/2));
  else
    mat = mat(:, (winsize/2 + 1):(end-winsize/2 + 1));
  end
end

% -------------------------------------------------------------------------
% SUBFUNCTION which is estimating the absolut artifact limits from the
% given violations and which is extending the artifactmap entry to the
% trial size
% -------------------------------------------------------------------------
function [map, artifact] = estim_artifact_limits(map, artifact, offset,...
                               channel, winsize)
  [channum, begnum] = find(map);                                            % estimate pairs of channel numbers and begin numbers for each violation
  if size(begnum, 2) > 1                                                    % begnum and channum have to be row vectors
    begnum = begnum';
    channum = chanum';
  end
  map = [map false(length(channel), winsize - 1)];                          % extend artfctmap to trial size
  endnum = begnum + winsize - 1;                                            % estimate end numbers for each violation
  for j=1:1:length(channum)
    map(channum(j), begnum(j):endnum(j)) = true;                            % extend the violations in the map to the window size
  end
  if ~isempty(begnum)
    begnum = unique(begnum);                                                % select all unique violations
    begnum = begnum + offset - 1;                                           % convert relative sample number into an absolute one
    begnum(:,2) = begnum(:,1) + winsize - 1;
    artifact = [artifact; begnum];                                          % add results to the artifacts matrix
  end
end

% -------------------------------------------------------------------------
% SUBFUNCTION which detects threshold artifacts by using a minmax threshold
% - it is a replacement of ft_artifact threshold which provides an
% additional artifact map
% -------------------------------------------------------------------------
function [ autoart ] = special_minmax_threshold(cfgT, data_in)

  numOfTrl  = length(data_in.trialinfo);                                    % get number of trials in the data
  artifact  = zeros(0,2);                                                   % initialize artifact variable
  artfctmap{1,numOfTrl} = [];

  channel = ft_channelselection(cfgT.artfctdef.threshold.channel, ...
              data_in.label);

  for i = 1:1:numOfTrl
    data_in.trial{i} = data_in.trial{i}(ismember(data_in.label, ...         % prune the available data to the channels of interest
                        channel) ,:);
  end

  if isfield(cfgT.artfctdef.threshold, 'max')                               % check for range violations
    for i=1:1:numOfTrl
      artfctmap{i} = data_in.trial{i} < cfgT.artfctdef.threshold.min;       % find all min violations
      artfctmap{i} = artfctmap{i} | data_in.trial{i} > ...                  % add all max violations
                      cfgT.artfctdef.threshold.max;
      artval = any(artfctmap{i}, 1);
      begsample = find(diff([false artval])>0) + ...                        % estimates artifact snippets
                    data_in.sampleinfo(i,1) - 1;
      endsample = find(diff([artval false])<0) + ...
                    data_in.sampleinfo(i,1) - 1;
      artifact  = cat(1, artifact, [begsample(:) endsample(:)]);            % add results to the artifacts matrix
    end
  end

  autoart.artfctdef     = cfgT.artfctdef;                                   % generate output data structure
  autoart.showcallinfo  = cfgT.showcallinfo;
  autoart.artfctdef.threshold.artifact  = artifact;
  autoart.artfctdef.threshold.trl = cfgT.trl;
  autoart.artfctdef.threshold.artfctmap = artfctmap;
end


% -------------------------------------------------------------------------
% SUBFUNCTION which extends and combines artifacts according to the
% subtrial definition
% -------------------------------------------------------------------------
function [ threshold, bNum ] = combineArtifacts( overl, trll, threshold )

if isempty(threshold.artifact)                                              % do nothing, if nothing was detected
  bNum = 0;
  return;
end

trlMask   = zeros(size(threshold.trl,1), 1);

for i = 1:size(threshold.trl,1)
  if overl == 0                                                             % if no overlapping was selected
    if any(~(threshold.artifact(:,2) < threshold.trl(i,1)) & ...            % mark artifacts which final points are not less than the trials zero point
            ~(threshold.artifact(:,1) > threshold.trl(i,2)))                % mark artifacts which zero points are not greater than the trials final point
      trlMask(i) = 1;                                                       % mark trial as bad, if both previous conditions are true at least for one artifact
    end
  else                                                                      % if overlapping of 50% was selected
    if any(~(threshold.artifact(:,2) < (threshold.trl(i,1) + trll/2)) & ... % mark artifacts which final points are not less than the trials zero point - trllength/2
            ~(threshold.artifact(:,1) > (threshold.trl(i,2) - trll/2)))     % mark artifacts which zero points are not greater than the trials final point + trllength/2
      trlMask(i) = 1;                                                       % mark trial as bad, if both previous conditions are true at least for one artifact
    end
  end
end

bNum = sum(trlMask);                                                        % calc number of bad segments
threshold.artifact = threshold.trl(logical(trlMask),1:2);                   % if trial contains artifacts, mark whole trial as artifact

if isfield(threshold, 'artfctmap')
  map = [];

  for i=1:1:size(threshold.artfctmap, 2)
    for j = 1:trll:(size(threshold.artfctmap{i},2) - trll + 1)
      map = [map sum(threshold.artfctmap{i}(:,j:j+trll-1) == 1, 2) > 0];    %#ok<AGROW>
    end
    if ~isempty(map)
      threshold.artfctmap{i} = map;
      map = [];
    else
      cprintf([1,0.5,0], 'Trial %d is shorter than %d second (segmentation size).\n', i, trll/500);
      cprintf([1,0.5,0], 'It will be rejected in general. Thus, no artifact information is available.\n');
      threshold.artfctmap{i} = NaN(size(threshold.artfctmap{i}, 1), 1);
    end
  end

end

end
