function [ data_eogcomp ] = JOEI_selectBadComp( data_icacomp )
% JOEI_SELECTBADCOMP is a function for selecting bad ICA components
% visually. Within the GUI, each component can be set to either keep or
% reject for a later artifact correction operation.
%
% Use as
%   [ data_eogcomp ] = JOEI_selectBadComp( data_eogcomp, data_icacomp )
%
% where the input as to be the result of JOEI_ICA
%
% This function requires the fieldtrip toolbox
%
% See also JOEI_ICA and FT_ICABROWSER

% Copyright (C) 2019, Daniel Matthes, MPI CBS

fprintf('<strong>Select ICA components which shall be subtracted from data...</strong>\n');
fprintf('Select components to reject!\n');

filepath = fileparts(mfilename('fullpath'));                                % load cap layout
load(sprintf('%s/../layouts/mpi_customized_acticap32.mat', filepath), ...
     'lay');

cfg               = [];
cfg.rejcomp       = [];
cfg.blocksize     = 30;
cfg.zlim          = 'maxabs';
cfg.layout        = lay;
cfg.colormap      = 'jet';
cfg.showcallinfo  = 'no';

ft_warning off;
badComp = ft_icabrowser(cfg, data_icacomp);
ft_warning on;

if sum(badComp) == 0
  cprintf([1,0.5,0],'No component is selected!\n');
  cprintf([1,0.5,0],'NOTE: The following cleaning operation will keep the data unchanged!\n');
end

data_eogcomp.elements   = data_icacomp.label(badComp);
data_eogcomp.label      = data_icacomp.label;
data_eogcomp.topolabel  = data_icacomp.topolabel;
data_eogcomp.topo       = data_icacomp.topo;
data_eogcomp.unmixing   = data_icacomp.unmixing;

end
