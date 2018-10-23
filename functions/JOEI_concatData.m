function [ data ] = JOEI_concatData( data )
% JOEI_CONCATDATA concatenate all trials of a dataset to a continuous data
% stream.
%
% Use as
%   [ data ] = JOEI_concatData( data )
%
% where the input can be i.e. the result from JOEI_IMPORTDATASET or 
% JOEI_PREPROCESSING
%
% This function requires the fieldtrip toolbox.
%
% See also JOEI_IMPORTDATASET, JOEI_PREPROCESSING

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Concatenate the data
% -------------------------------------------------------------------------
fprintf('Concatenate trials...\n');
numOfTrials = length(data.trial);                                           % estimate number of trials
trialLength = zeros(numOfTrials, 1);                                        
numOfChan   = size(data.trial{1}, 1);                                       % estimate number of channels

for i = 1:numOfTrials
  trialLength(i) = size(data.trial{i}, 2);                                  % estimate length of single trials
end

dataLength  = sum( trialLength );                                           % estimate number of all samples in the dataset
data_concat = zeros(numOfChan, dataLength);
time_concat = zeros(1, dataLength);
endsample   = 0;

for i = 1:numOfTrials
  begsample = endsample + 1;
  endsample = endsample + trialLength(i);
  data_concat(:, begsample:endsample) = data.trial{i}(:,:);                 % concatenate data trials
  if begsample == 1
    time_concat(1, begsample:endsample) = data.time{i}(:);                  % concatenate time vectors
  else
    if (data.time{i}(1) == 0 )
      time_concat(1, begsample:endsample) = data.time{i}(:) + ...
                                time_concat(1, begsample - 1) + ...         % create continuous time scale
                                1/data.fsample;
    elseif(data.time{i}(1) > time_concat(1, begsample - 1))
      time_concat(1, begsample:endsample) = data.time{i}(:);                % keep existing time scale
    else
      time_concat(1, begsample:endsample) = data.time{i}(:) + ...
                                time_concat(1, begsample - 1) + ...         % create continuous time scale
                                1/data.fsample - ...
                                data.time{i}(1);
    end
  end
end

data.trial       = [];
data.time        = [];
data.trial{1}    = data_concat;                                             % add concatenated data to the data struct
data.time{1}     = time_concat;                                             % add concatenated time vector to the data struct
data.trialinfo   = 0;                                                       % add a fake event number to the trialinfo for subsequend artifact rejection
data.sampleinfo  = [1 dataLength];                                          % add also a fake sampleinfo for subsequend artifact rejection

end
