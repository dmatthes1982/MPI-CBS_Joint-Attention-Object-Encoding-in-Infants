function [ numOfSeg ] = JOEI_numOfSeg( data )
% JOEI_NUMOFSEG estimates number of segments per condition.
%
% Use as
%   [ numOfSeg ] = JOEI_numOfSeg( data )
%
% where the input data could be any data structure of the JOEI project.
%
% This function requires the fieldtrip toolbox.
%
% See also JOEI_SEGMENTATION

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Load general definitions
% -------------------------------------------------------------------------
filepath = fileparts(mfilename('fullpath'));
load(sprintf('%s/../general/JOEI_generalDefinitions.mat', filepath), ...
     'generalDefinitions');

conditions = [generalDefinitions.condNum generalDefinitions.metaCondNum];

% -------------------------------------------------------------------------
% Estimate number of segments
% -------------------------------------------------------------------------
numOfSeg = zeros(numel(conditions), 1);

for i = 1:1:numel(conditions)
  numOfSeg(i) = sum(ismember(data.trialinfo, conditions(i)));
end

end
