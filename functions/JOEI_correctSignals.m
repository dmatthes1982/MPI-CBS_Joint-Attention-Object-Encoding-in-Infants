function [ data ] = JOEI_correctSignals( data_eogcomp, data )
% JOEI_CORRECTSIGNALS is a function which removes artifacts from data
% using previously estimated ica components
%
% Use as
%   [ data ] = JOEI_correctSignals( data_eogcomp, data )
%
% where data_eogcomp has to be the result of JOEI_SELECTBADCOMP and data
% has to be the result of JOEI_PREPROCESSING
%
% This function requires the fieldtrip toolbox
%
% See also JOEI_SELECTBADCOMP, JOEI_PREPROCESSING, FT_COMPONENTANALYSIS
% and FT_REJECTCOMPONENT

% Copyright (C) 2019, Daniel Matthes, MPI CBS

fprintf('<strong>Artifact correction...</strong>\n');

cfg               = [];
cfg.unmixing      = data_eogcomp.unmixing;
cfg.topolabel     = data_eogcomp.topolabel;
cfg.demean        = 'no';
cfg.showcallinfo  = 'no';

ft_info off;
dataComp = ft_componentanalysis(cfg, data);                                 % estimate components by using the in previous part 3 calculated unmixing matrix
ft_info on;

for i=1:length(data_eogcomp.elements)
  data_eogcomp.elements(i) = strrep(data_eogcomp.elements(i), ...           % change names of eog-like components from runicaXXX to componentXXX
                              'runica', 'component');
end

cfg               = [];
cfg.component     = find(ismember(dataComp.label, data_eogcomp.elements))'; % to be removed component(s)
cfg.demean        = 'no';
cfg.showcallinfo  = 'no';
cfg.feedback      = 'no';

ft_info off;
ft_warning off;
data = ft_rejectcomponent(cfg, dataComp, data);                             % revise data
ft_warning on;
ft_info on;

end
