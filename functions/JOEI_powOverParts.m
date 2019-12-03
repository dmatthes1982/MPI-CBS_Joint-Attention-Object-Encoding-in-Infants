function  [ data_pwelchod ] = JOEI_powOverParts( cfg )
% JOEI_POWOVERPARTS estimates the mean of the power activity for all
% conditions and over all participants.
%
% Use as
%   [ data_pwelchod ] = JOEI_powOverParts( cfg )
%
% The configuration options are
%   cfg.path      = source path' (i.e. '/data/pt_01904/eegData/EEG_JOEI_processedData/06a_pwelch/')
%   cfg.session   = session number (default: 1)
%
% This function requires the fieldtrip toolbox
% 
% See also JOEI_PWELCH

% Copyright (C) 2018-2019, Daniel Matthes, MPI CBS 

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
path      = ft_getopt(cfg, 'path', ...
              '/data/pt_01904/eegData/EEG_JOEI_processedData/06a_pwelch/');
session   = ft_getopt(cfg, 'session', 1);

% -------------------------------------------------------------------------
% Load general definitions
% -------------------------------------------------------------------------
filepath = fileparts(mfilename('fullpath'));
load(sprintf('%s/../general/JOEI_generalDefinitions.mat', filepath), ...
     'generalDefinitions');   

% -------------------------------------------------------------------------
% Select participants
% -------------------------------------------------------------------------    
fprintf('<strong>Averaging power values over participants...</strong>\n');

partsList   = dir([path, sprintf('JOEI_p*_06a_pwelch_%03d.mat', session)]);
partsList   = struct2cell(partsList);
partsList   = partsList(1,:);
numOfParts  = length(partsList);

for i=1:1:numOfParts
  listOfParts(i) = sscanf(partsList{i}, ['JOEI_p%d_09b'...
                                   sprintf('%03d.mat', session)]);          %#ok<AGROW>
end

y = sprintf('%d ', listOfParts);
selection = false;

while selection == false
  fprintf('The following participants are available: %s\n', y);
  x = input('Which participants should be included into the averaging? (i.e. [1,2,3]):\n');
  if ~all(ismember(x, listOfParts))
    cprintf([1,0.5,0], 'Wrong input!\n');
  else
    selection = true;
    listOfParts = unique(x);
    numOfParts  = length(listOfParts);
  end
end
fprintf('\n');

% -------------------------------------------------------------------------
% Load and organize data
% -------------------------------------------------------------------------
data_out.trialinfo = [generalDefinitions.condNum ...
                      generalDefinitions.metaCondNum]';

data{1, numOfParts} = [];
trialinfo{1, numOfParts} = [];

for i=1:1:numOfParts
  filename = sprintf('JOEI_p%02d_06a_pwelch_%03d.mat', listOfParts(i), ...
                     session);
  file = strcat(path, filename);
  fprintf('Load %s ...\n', filename);
  load(file, 'data_pwelch');
  data{i}                   = data_pwelch.powspctrm;
  trialinfo{i}              = data_pwelch.trialinfo;
  if i == 1
    data_out.label  = data_pwelch.label;
    data_out.dimord = data_pwelch.dimord;
    data_out.freq   = data_pwelch.freq;
  end
  clear data_pwelch
end
fprintf('\n');

data = cellfun(@(x) num2cell(x, [2,3])', data, 'UniformOutput', false);

for i=1:1:numOfParts
  data{i} = cellfun(@(x) squeeze(x), data{i}, 'UniformOutput', false);
end

data = fixTrialOrder( data, trialinfo, data_out.trialinfo, ...
                      listOfParts );

data = cellfun(@(x) cat(3, x{:}), data, 'UniformOutput', false);
data = cellfun(@(x) shiftdim(x, 2), data, 'UniformOutput', false);
data = cat(4, data{:});

% -------------------------------------------------------------------------
% Estimate averaged power spectrum (over participants)
% -------------------------------------------------------------------------
data = nanmean(data, 4);

data_out.powspctrm  = data;
data_out.parts      = listOfParts;

data_pwelchod = data_out;

end

%--------------------------------------------------------------------------
% SUBFUNCTION which fixes trial order and creates empty matrices for 
% missing phases.
%--------------------------------------------------------------------------
function dataTmp = fixTrialOrder( dataTmp, trInf, trInfOrg, partNum )

emptyMatrix = NaN * ones(size(dataTmp{1}{1}, 1), size(dataTmp{1}{1}, 2));   % empty matrix with NaNs
fixed = false;

for k = 1:1:size(dataTmp, 2)
  if ~isequal(trInf{k}, trInfOrg)
    missingPhases = ~ismember(trInfOrg, trInf{k});
    missingPhases = trInfOrg(missingPhases);
    missingPhases = vec2str(missingPhases', [], [], 0);
    cprintf([0,0.6,0], ...
            sprintf(['Participant %d: Phase(s) %s is(are) missing. '...
                      '\nEmpty matrix(matrices) with NaNs created.\n'], ...
            partNum(k), missingPhases));
    [~, loc] = ismember(trInfOrg, trInf{k});
    tmpBuffer = [];
    tmpBuffer{length(trInfOrg)} = [];                                       %#ok<AGROW>
    for l = 1:1:length(trInfOrg)
      if loc(l) == 0
        tmpBuffer{l} = emptyMatrix;
      else
        tmpBuffer(l) = dataTmp{k}(loc(l));
      end
    end
    dataTmp{k} = tmpBuffer;
    fixed = true;
  end
end

if fixed == true
  fprintf('\n');
end

end
