function [ data ] = JOEI_pWelch( cfg, data )
% JOEI_PWELCH calculates the power spectral density using Welch's method
% for every condition in the dataset.
%
% Use as
%   [ data ] = JOEI_pWelch( cfg, data)
%
% where the input data hast to be the result from JOEI_SEGMENTATION
%
% The configuration options are
%   cfg.foi = frequency of interest - begin:resolution:end (default: 1:1:50)
%
% This function requires the fieldtrip toolbox.
%
% See also JOEI_SEGMENTATION

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
foi = ft_getopt(cfg, 'foi', 1:1:50);

% -------------------------------------------------------------------------
% psd settings
% -------------------------------------------------------------------------
cfg                 = [];
cfg.method          = 'mtmfft';
cfg.output          = 'pow';
cfg.channel         = 'all';                                                % calculate spectrum for all channels
cfg.trials          = 'all';                                                % calculate spectrum for every trial  
cfg.keeptrials      = 'yes';                                                % do not average over trials
cfg.pad             = 'maxperlen';                                          % do not use padding
cfg.taper           = 'hanning';                                            % hanning taper the segments
cfg.foi             = foi;                                                  % frequencies of interest
cfg.feedback        = 'no';                                                 % suppress feedback output
cfg.showcallinfo    = 'no';                                                 % suppress function call output

% -------------------------------------------------------------------------
% Calculate power spectral density using Welch's method
% -------------------------------------------------------------------------
fprintf('<strong>Calc power spectral density...</strong>\n');
ft_warning off;
data = ft_freqanalysis(cfg, data);
ft_warning on;
data = pWelch(data);

end

% -------------------------------------------------------------------------
% Local functions
% -------------------------------------------------------------------------
function [ data_pWelch ] = pWelch(data_psd)
% -------------------------------------------------------------------------
% Load general definitions
% -------------------------------------------------------------------------
filepath = fileparts(mfilename('fullpath'));
load(sprintf('%s/../general/JOEI_generalDefinitions.mat', filepath), ...
     'generalDefinitions');  

cond      = [generalDefinitions.condNum generalDefinitions.metaCondNum];
val       = ismember(cond, data_psd.trialinfo);
trialinfo = cond(val)';
powspctrm = zeros(length(trialinfo), length(data_psd.label), length(data_psd.freq));

for i = 1:1:length(trialinfo)
  val       = ismember(data_psd.trialinfo, trialinfo(i));
  tmpspctrm = data_psd.powspctrm(val,:,:);
  powspctrm(i,:,:) = nanmedian(tmpspctrm, 1);
end

data_pWelch.label = data_psd.label;
data_pWelch.dimord = data_psd.dimord;
data_pWelch.freq = data_psd.freq;
data_pWelch.powspctrm = powspctrm;
data_pWelch.trialinfo = trialinfo;
data_pWelch.cfg.previous = data_psd.cfg;
data_pWelch.cfg.pwelch_median = 'yes';
data_pWelch.cfg.pwelch_mean = 'no';

end
