function [ num ] = JOEI_checkCondition( condition, varargin )
% JOEI_CHECKCONDITION - This functions checks the defined condition. 
%
% Use as
%   [ num ] = JOEI_checkCondition( condition )
%
% If condition is a number the function checks, if this number is equal to 
% one of the default values and return this number in case of confirmity. 
% If condition is a string, the function returns the associated number, if
% the given string is valid. Otherwise the function throws an error.
%
% Additional options should be specified in key-value pairs and can be
%   'flag'  = to mark special data which are including a special set of
%             condition markers (i.e. 'meta')
%
% All available condition strings and numbers are defined in
% JOEI_DATASTRUCTURE
%
% SEE also JOEI_DATASTRUCTURE

% Copyright (C) 2018-2019, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get varargin options
% -------------------------------------------------------------------------
flag = ft_getopt(varargin, 'flag');

% -------------------------------------------------------------------------
% Load general definitions
% -------------------------------------------------------------------------
filepath = fileparts(mfilename('fullpath'));
load(sprintf('%s/../general/JOEI_generalDefinitions.mat', filepath), ...
     'generalDefinitions');

if isempty(flag)
  condNum = generalDefinitions.condNum;
  condString = generalDefinitions.condString;
elseif strcmp(flag, 'meta')
  condNum = [ generalDefinitions.condNum generalDefinitions.metaCondNum ];
  condString = [ generalDefinitions.condString; ...
                  generalDefinitions.metaCondString ];
end

% -------------------------------------------------------------------------
% Check Condition
% -------------------------------------------------------------------------
if isnumeric(condition)                                                     % if condition is already numeric
  if ~ismember(condition, condNum)
    error('%d is not a valid condition', condition);
  else
    num = condition;
  end
else                                                                        % if condition is specified as string
  elements = ismember(condString, condition);
  if ~any(elements)
     error('%s is not a valid condition', condition);
  else
    num = condNum(elements);
  end
end

end
