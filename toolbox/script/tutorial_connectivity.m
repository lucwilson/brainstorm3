function tutorial_connectivity(reports_dir)
% TUTORIAL_CONNECTIVITY: Script that runs the Brainstorm connectivity tutorial.
%
% INPUTS: 
%    - reports_dir  : Directory where to save the execution report (instead of displaying it)

% @=============================================================================
% This function is part of the Brainstorm software:
% https://neuroimage.usc.edu/brainstorm
% 
% Copyright (c) University of Southern California & McGill University
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPLv3
% license can be found at http://www.gnu.org/copyleft/gpl.html.
% 
% FOR RESEARCH PURPOSES ONLY. THE SOFTWARE IS PROVIDED "AS IS," AND THE
% UNIVERSITY OF SOUTHERN CALIFORNIA AND ITS COLLABORATORS DO NOT MAKE ANY
% WARRANTY, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, NOR DO THEY ASSUME ANY
% LIABILITY OR RESPONSIBILITY FOR THE USE OF THIS SOFTWARE.
%
% For more information type "brainstorm license" at command prompt.
% =============================================================================@
%
% Author: Raymundo Cassani, 2021-2022
%         Francois Tadel, 2022


%% ===== PARAMETERS =====
% Output folder for reports
if (nargin < 1) || isempty(reports_dir) || ~isfolder(reports_dir)
    reports_dir = [];
end


%% ===== CREATE PROTOCOL  =====
% Start brainstorm without the GUI
if ~brainstorm('status')
    brainstorm nogui
end
% Create Protocol
ProtocolName = 'TutorialConnectivity';
% Delete existing protocol
gui_brainstorm('DeleteProtocol', ProtocolName);
% Create new protocol
gui_brainstorm('CreateProtocol', ProtocolName, 0, 0);
% Start a new report
bst_report('Start');


%% ===== SIMULATE DATA (MVAR MODEL) =====
% Seed for random number generator
rng(111); 
% Process: Simulate AR signals
sFileSim = bst_process('CallProcess', 'process_simulate_ar_spectra', [], [], ...
    'subjectname',  'Subject01', ...
    'condition',    'Simulation', ...
    'samples',      12000, ...
    'srate',        120, ...
    'interactions', ['1, 1 / 10, 25 / 0.3, 0.5' 10 ...
                     '2, 2 / 10, 25 / 0.7, 0.3' 10 ... 
                     '3, 3 / 10, 25 / 0.2, 0.2' 10 ... 
                     '1, 3 / 25 / 0.1']);

% Make sure the display mode is "columns"
bst_set('TSDisplayMode', 'column');
% Process: Snapshot: Recordings time series
bst_process('CallProcess', 'process_snapshot', sFileSim, [], ...
    'type',    'data', ...  % Recordings time series
    'Comment', 'Simulated signals');

                 

%% ===== CORRELATION =====
% Process: Correlation NxN
sFiles = bst_process('CallProcess', 'process_corr1n', sFileSim, [], ...
    'timewindow', [], ...
    'scalarprod', 0, ...
    'outputmode', 1);  % Save individual results (one file per input file)

% Process: Snapshot: Connectivity matrix
bst_process('CallProcess', 'process_snapshot', sFiles, [], ...
    'type',    'connectimage', ...  % Connectivity matrix
    'Comment', 'Correlation NxN');


%% ===== COHERENCE =====
% Process: Magnitude-squared coherence:  |C|^2 = |Cxy|^2/(Cxx*Cyy)
sFiles = bst_process('CallProcess', 'process_cohere1n', sFileSim, [], ...
    'timewindow',    [], ...
    'removeevoked',  0, ...
    'cohmeasure',    'mscohere', ...  % Magnitude-squared coherence:  |C|^2 = |Cxy|^2/(Cxx*Cyy)
    'tfmeasure',     'stft', ...  % Fourier transform
    'tfedit',        struct(...
         'Comment',         'Complex', ...
         'TimeBands',       [], ...
         'Freqs',           [], ...
         'StftWinLen',      1, ...
         'StftWinOvr',      50, ...
         'StftFrqMax',      60, ...
         'ClusterFuncTime', 'none', ...
         'Measure',         'none', ...
         'Output',          'all', ...
         'SaveKernel',      0), ...
    'timeres',       'none', ...  % None
    'avgwinlength',  1, ...
    'avgwinoverlap', 50, ...
    'outputmode',    'input');  % separately for each file

% Process: Snapshot: Frequency spectrum
bst_process('CallProcess', 'process_snapshot', sFiles, [], ...
    'type',    'spectrum', ...  % Frequency spectrum
    'Comment', 'MSC NxN');

% Process: Snapshot: Connectivity graph
bst_process('CallProcess', 'process_snapshot', sFiles, [], ...
    'type',    'connectgraph', ...  % Connectivity graph
    'Comment', 'MSC NxN');

% Process: Snapshot: Connectivity matrix
bst_process('CallProcess', 'process_snapshot', sFiles, [], ...
    'type',    'connectimage', ...  % Connectivity matrix
    'Comment', 'MSC NxN');

% Process: Imaginary coherence:  IC = |imag(C)|
sFiles = bst_process('CallProcess', 'process_cohere1n', sFileSim, [], ...
    'timewindow',    [], ...
    'removeevoked',  0, ...
    'cohmeasure',    'icohere2019', ...  % Imaginary coherence:  IC = |imag(C)|
    'tfmeasure',     'stft', ...  % Fourier transform
    'tfedit',        struct(...
         'Comment',         'Complex', ...
         'TimeBands',       [], ...
         'Freqs',           [], ...
         'StftWinLen',      1, ...
         'StftWinOvr',      50, ...
         'StftFrqMax',      60, ...
         'ClusterFuncTime', 'none', ...
         'Measure',         'none', ...
         'Output',          'all', ...
         'SaveKernel',      0), ...
    'timeres',       'none', ...  % None
    'avgwinlength',  1, ...
    'avgwinoverlap', 50, ...
    'outputmode',    'input');  % separately for each file

% Process: Snapshot: Frequency spectrum
bst_process('CallProcess', 'process_snapshot', sFiles, [], ...
    'type',    'spectrum', ...  % Frequency spectrum
    'Comment', 'Imaginary coherence NxN');

% Process: Lagged coherence / Corrected imaginary coherence:  LC = |imag(C)|/sqrt(1-real(C)^2)
sFiles = bst_process('CallProcess', 'process_cohere1n', sFileSim, [], ...
    'timewindow',    [], ...
    'removeevoked',  0, ...
    'cohmeasure',    'lcohere2019', ...  % Lagged coherence / Corrected imaginary coherence:  LC = |imag(C)|/sqrt(1-real(C)^2)
    'tfmeasure',     'stft', ...  % Fourier transform
    'tfedit',        struct(...
         'Comment',         'Complex', ...
         'TimeBands',       [], ...
         'Freqs',           [], ...
         'StftWinLen',      1, ...
         'StftWinOvr',      50, ...
         'StftFrqMax',      60, ...
         'ClusterFuncTime', 'none', ...
         'Measure',         'none', ...
         'Output',          'all', ...
         'SaveKernel',      0), ...
    'timeres',       'none', ...  % None
    'avgwinlength',  1, ...
    'avgwinoverlap', 50, ...
    'outputmode',    'input');  % separately for each file

% Process: Snapshot: Frequency spectrum
bst_process('CallProcess', 'process_snapshot', sFiles, [], ...
    'type',    'spectrum', ...  % Frequency spectrum
    'Comment', 'Lagged coherence NxN');


%% ===== GRANGER CAUSALITY =====
% Process: Bivariate Granger causality NxN
sFiles = bst_process('CallProcess', 'process_granger1n', sFileSim, [], ...
    'timewindow',   [], ...
    'removeevoked', 0, ...
    'grangerorder', 6, ...
    'outputmode',   1);  % Save individual results (one file per input file)

% Process: Snapshot: Connectivity graph
bst_process('CallProcess', 'process_snapshot', sFiles, [], ...
    'type',    'connectgraph', ...  % Connectivity graph
    'Comment', 'Granger causality NxN');

% Process: Snapshot: Connectivity matrix
bst_process('CallProcess', 'process_snapshot', sFiles, [], ...
    'type',    'connectimage', ...  % Connectivity matrix
    'Comment', 'Granger causality NxN');


%% ===== SPECTRAL GRANGER CAUSALITY =====
% Process: Bivariate Granger causality (spectral) NxN
sFiles = bst_process('CallProcess', 'process_spgranger1n', sFileSim, [], ...
    'timewindow',   [], ...
    'removeevoked', 0, ...
    'grangerorder', 6, ...
    'maxfreqres',   1, ...
    'maxfreq',      60, ...
    'outputmode',   1);  % Save individual results (one file per input file)

% Process: Snapshot: Frequency spectrum
bst_process('CallProcess', 'process_snapshot', sFiles, [], ...
    'type',    'spectrum', ...  % Frequency spectrum
    'Comment', 'Spectral Granger causality NxN');


%% ===== ENVELOPE CORRELATION =====
% Process: Envelope Correlation NxN [2023]
sFiles = bst_process('CallProcess', 'process_henv1n', sFileSim, [], ...
    'timewindow',    [], ...
    'removeevoked',  0, ...
    'cohmeasure',    'oenv', ...  % Envelope correlation (orthogonalized)
    'tfmeasure',     'hilbert', ...  % Hilbert transform
    'tfedit',        struct(...
         'Comment',         'Complex', ...
         'TimeBands',       [], ...
         'Freqs',           {{'delta', '2, 4', 'mean'; 'theta', '5, 7', 'mean'; 'alpha', '8, 12', 'mean'; 'beta', '15, 29', 'mean'; 'gamma1', '30, 59', 'mean'}}, ...
         'ClusterFuncTime', 'none', ...
         'Measure',         'none', ...
         'Output',          'all', ...
         'SaveKernel',      0), ...
    'timeres',       'windowed', ...  % Windowed
    'avgwinlength',  5, ...
    'avgwinoverlap', 50, ...
    'parallel',      0, ...
    'outputmode',    'input');  % separately for each file

% Process: Snapshot: Frequency spectrum
bst_process('CallProcess', 'process_snapshot', sFiles, [], ...
    'type',    'spectrum', ...  % Frequency spectrum
    'Comment', 'Envelope correlation (Hilbert transform) NxN');

% Process: Envelope Correlation NxN [2023]
sFiles = bst_process('CallProcess', 'process_henv1n', sFileSim, [], ...
    'timewindow',    [], ...
    'removeevoked',  0, ...
    'cohmeasure',    'oenv', ...  % Envelope correlation (orthogonalized)
    'tfmeasure',     'morlet', ...  % Morlet wavelets
    'tfedit',        struct(...
         'Comment',         'Complex,1-60Hz', ...
         'TimeBands',       [], ...
         'Freqs',           [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60], ...
         'MorletFc',        1, ...
         'MorletFwhmTc',    3, ...
         'ClusterFuncTime', 'none', ...
         'Measure',         'none', ...
         'Output',          'all', ...
         'SaveKernel',      0), ...
    'timeres',       'windowed', ...  % Windowed
    'avgwinlength',  5, ...
    'avgwinoverlap', 50, ...
    'parallel',      0, ...
    'outputmode',    'input');  % separately for each file

% Process: Snapshot: Frequency spectrum
bst_process('CallProcess', 'process_snapshot', sFiles, [], ...
    'type',    'spectrum', ...  % Frequency spectrum
    'Comment', 'Envelope correlation (Morlet wavelet) NxN');


%% ===== PHASE LOCKING VALUE =====
plv_variants = {'plv',   ...  % Phase locking value
                'ciplv', ...  % Lagged phase synchronization / Corrected imaginary PLV
                'wpli'};      % Weighted phase lag index
for ix = 1 : length(plv_variants)
    % Process: Phase locking value
    sFiles = bst_process('CallProcess', 'process_plv1n', sFileSim, [], ...
        'timewindow',    [], ...
        'plvmethod',     plv_variants{ix}, ...
        'plvmeasure',    2, ...  % Magnitude
        'tfmeasure',     'hilbert', ...  % Hilbert transform
        'tfedit',        struct(...
             'Comment',         'Complex', ...
             'TimeBands',       [], ...
             'Freqs',           {{'delta', '2, 4', 'mean'; 'theta', '5, 7', 'mean'; 'alpha', '8, 12', 'mean'; 'beta', '15, 29', 'mean'; 'gamma1', '30, 59', 'mean'}}, ...
             'ClusterFuncTime', 'none', ...
             'Measure',         'none', ...
             'Output',          'all', ...
             'SaveKernel',      0), ...
        'timeres',       'none', ...  % None
        'avgwinlength',  1, ...
        'avgwinoverlap', 50, ...
        'outputmode',    'input');  % separately for each file

    % Process: Snapshot: Frequency spectrum
    bst_process('CallProcess', 'process_snapshot', sFiles, [], ...
        'type',    'spectrum', ...  % Frequency spectrum
        'Comment',  ['Phase locking value (' plv_variants{ix} ')  NxN']);
end

%% ===== PHASE TRANSFER ENTROPY =====
% Process: Phase Transfer Entropy NxN
sFiles = bst_process('CallProcess', 'process_pte1n', sFileSim, [], ...
    'timewindow', [], ...
    'freqbands',  {'delta', '2, 4', 'mean'; 'theta', '5, 7', 'mean'; 'alpha', '8, 12', 'mean'; 'beta', '15, 29', 'mean'; 'gamma1', '30, 59', 'mean'}, ...
    'normalized', 0, ...
    'outputmode', 1);  % Save individual results (one file per input file)

% Process: Snapshot: Frequency spectrum
bst_process('CallProcess', 'process_snapshot', sFiles, [], ...
    'type',    'spectrum', ...  % Frequency spectrum
    'Comment', 'Phase transfer entropy NxN');


%% ===== SAVE REPORT =====
% Save and display report
ReportFile = bst_report('Save', []);
if ~isempty(reports_dir) && ~isempty(ReportFile)
    bst_report('Export', ReportFile, reports_dir);
else
    bst_report('Open', ReportFile);
end