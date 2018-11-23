function [ data ] = JOEI_estNoisyChan( data )
% JOEI_ESTNOISYCHAN is a function which is detecting automatically noisy
% channels. Channels are marked as noisy/bad channels when its total power
% from 3Hz on is above 1.5 * IQR + Q3 or below Q1 - 1.5 * IQR.
%
% Use as
%   [ data ] = JOEI_estNoisyChan( cfg, data )
%
% where input data has to be the result of JOEI_CONCATDATA.
%
% Reference:
%   [Wass 2018] "Parental neural responsivity to infants visual attention: 
%                 how mature brains scaffold immature brains during social 
%                 interaction."
%
% This function requires the fieldtrip toolbox
%
% See also JOEI_CONCATDATA

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Check data
% -------------------------------------------------------------------------
if numel(data.trialinfo) ~= 1
  error('Dataset has more than one trial. Data has to be concatenated!');
end

fprintf('<strong>Estimating noisy channels...</strong>\n');
% -----------------------------------------------------------------------
% Estimate power spectrum
% -----------------------------------------------------------------------
cfg                 = [];
cfg.method          = 'mtmfft';
cfg.output          = 'pow';
cfg.channel           = {'all', '-V1', '-V2'};                              % calculate spectrum for all channels, except V1 and V2
cfg.trials          = 'all';                                                % calculate spectrum for every trial
cfg.keeptrials      = 'yes';                                                % do not average over trials
cfg.pad             = 'nextpow2';                                           % do not use padding
cfg.taper           = 'hanning';                                            % hanning taper the segments
cfg.foilim          = [0 250];                                              % frequency band of interest
cfg.feedback        = 'no';                                                 % suppress feedback output
cfg.showcallinfo    = 'no';                                                 % suppress function call output

fprintf('Estimate power spectrum...\n');
data = ft_freqanalysis( cfg, data);

% -----------------------------------------------------------------------
% Estimate total power of each channel
% -----------------------------------------------------------------------
fprintf('Add all power values from 3 Hz on together...\n');
loc                 = find(data.freq < 3, 1, 'last');                       % Apply highpass at 3 Hz to suppress eye artifacts and baseline drifts
data.totalpow       = sum(squeeze(data.powspctrm(:,:,loc:end)), 2);
data.quartile       = prctile(data.totalpow, [25,50,75]);
data.interquartile  = data.quartile(3) - data.quartile(1);
data.outliers       = (data.totalpow > ( data.quartile(3) + ...
                        1.5 * data.interquartile)) | ...
                      (data.totalpow < ( data.quartile(1) - ...
                        1.5 * data.interquartile));  

% -----------------------------------------------------------------------
% Generate output
% -----------------------------------------------------------------------
data.freqrange  = {[3 max(data.freq)]};
data.dimord     = 'chan_freqrange';
data            = removefields(data, {'freq', 'cumsumcnt', 'cumtapcnt'...
                                      'trialinfo', 'cfg', 'powspctrm'});

end
