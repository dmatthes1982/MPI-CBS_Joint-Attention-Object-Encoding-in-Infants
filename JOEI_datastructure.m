% JOEI_DATASTRUCTURE
%
% The data in the --- Joint attention object encoding in infants --- is 
% structured as follows:
%
% dataset example:
%
% data_raw (1x1 fieldtrip data structure)
%
% In every substep of the data processing pipeline (i.e. 01a_raw,
% 01b_events, 01c_badchan, 01d_repaired, 02_preproc, 03_icacomp ...) N
% single datasets will be created. The number N stands for the current
% number of participants within the study. Every dataset for each
% participants is stored in a separate *.mat file, to avoid the need of
% swap memory during data  processing. The different conditions in a
% dataset are separated through trials and the field trialinfo contains
% the condition markers of each trials. In case of subsegmented data the
% structure contains more than one trial for each condition. The
% information about the order of the trials of one condition is available
% through the relating time elements.
%
% Many functions especially the plot functions need a declaration of the 
% specific condition, which should be selected. The JOEI study is described
% by the following conditions:
%
% - BubblePreJAI1     - 91
% - BubblePreNoJAI1   - 92
% - BubblePreJAI2     - 93
% - BubblePreNoJAI2   - 94
% - JA1Obj1           - 11
% - JA1Obj2           - 12
% - JA1Obj3           - 13
% - JA2Obj1           - 14
% - JA2Obj2           - 15
% - JA2Obj2           - 16
% - NoJA1Obj1         - 21
% - NoJA1Obj2         - 22
% - NoJA1Obj2         - 23
% - NoJA2Obj1         - 24
% - NoJA2Obj2         - 25
% - NoJA2Obj2         - 26
% - JA1Obj1Tab1       - 111
% - JA1Obj1Tab2       - 112
% - JA1Obj2Tab1       - 121
% - JA1Obj2Tab2       - 122
% - JA1Obj3Tab1       - 131
% - JA1Obj3Tab2       - 132
% - JA2Obj1Tab1       - 141
% - JA2Obj1Tab2       - 142
% - JA2Obj2Tab1       - 151
% - JA2Obj2Tab2       - 152
% - JA2Obj3Tab1       - 161
% - JA2Obj3Tab2       - 162
% - NoJA1Obj1Tab1     - 211
% - NoJA1Obj1Tab2     - 212
% - NoJA1Obj2Tab1     - 221
% - NoJA1Obj2Tab2     - 222
% - NoJA1Obj3Tab1     - 231
% - NoJA1Obj3Tab2     - 232
% - NoJA2Obj1Tab1     - 241
% - NoJA2Obj1Tab2     - 242
% - NoJA2Obj2Tab1     - 251
% - NoJA2Obj2Tab2     - 252
% - NoJA2Obj3Tab1     - 253
% - NoJA2Obj3Tab2     - 254
%
% Furthermore there are existing so-called Meta Conditions. These
% conditions including only a subset of the original conditions and they
% are described trough the occurrence of a certain event (i.e. infant
% object look, mutual gaze, mutual object look). The relating numbers and
% names are:
%
% - JA1Obj1-infObj    - 311
% - JA1Obj2-infObj    - 312
% - JA1Obj3-infObj    - 313
% - JA2Obj1-infObj    - 314
% - JA2Obj2-infObj    - 315
% - JA2Obj2-infObj    - 316
% - NoJA1Obj1-infObj  - 321
% - NoJA1Obj2-infObj  - 322
% - NoJA1Obj2-infObj  - 323
% - NoJA2Obj1-infObj  - 324
% - NoJA2Obj2-infObj  - 325
% - NoJA2Obj2-infObj  - 326
% - JA1Obj1-mGaze     - 411
% - JA1Obj2-mGaze     - 412
% - JA1Obj3-mGaze     - 413
% - JA2Obj1-mGaze     - 414
% - JA2Obj2-mGaze     - 415
% - JA2Obj2-mGaze     - 416
% - NoJA1Obj1-mGaze   - 421
% - NoJA1Obj2-mGaze   - 422
% - NoJA1Obj2-mGaze   - 423
% - NoJA2Obj1-mGaze   - 424
% - NoJA2Obj2-mGaze   - 425
% - NoJA2Obj2-mGaze   - 426
% - JA1Obj1-mObj      - 511
% - JA1Obj2-mObj      - 512
% - JA1Obj3-mObj      - 513
% - JA2Obj1-mObj      - 514
% - JA2Obj2-mObj      - 515
% - JA2Obj2-mObj      - 516
% - NoJA1Obj1-mObj    - 521
% - NoJA1Obj2-mObj    - 522
% - NoJA1Obj2-mObj    - 523
% - NoJA2Obj1-mObj    - 524
% - NoJA2Obj2-mObj    - 525
% - NoJA2Obj2-mObj    - 526
%
% The declaration of the condition is done by setting the cfg.condition
% option with the string or the number of the specific condition.

% Copyright (C) 2018, Daniel Matthes, MPI CBS
