function SpotAnalyzer(varargin)
% SpotAnalyzer - Interactive GUI for nanodot quantification in fluorescence microscopy
%
% USAGE:
%   SpotAnalyzer          % Launch main GUI
%   SpotAnalyzer('pooled') % Launch pooled analysis
%
% FEATURES:
%   - LoG-based spot detection
%   - Multi-channel analysis (bait + prey)
%   - Automated drift correction
%   - Local background estimation
%   - Bait-specific contrast calculations
%   - Batch processing
%
% WORKFLOW:
%   1. Load Images    2. Define ROI     3. Detect Dots   4. Define Ring
%   5. Analyze        6. Visualize      7. Export
%
% REQUIREMENTS:
%   - MATLAB R2023b+
%   - Image Processing Toolbox
%
% Author: Arthur Felker (arfelker@uni-osnabrueck.de)
% License: MIT

if nargin > 0 && strcmpi(varargin{1}, 'pooled')
    launchPooledAnalysis();
else
    launchMainGUI();
end
end

function launchMainGUI()
addPathsToProject();

try
    app = SpotAnalyzerGUI();
catch ME
    errordlg(sprintf('Failed to launch SpotAnalyzer:\n%s', ME.message), 'Error');
    rethrow(ME);
end
end

function launchPooledAnalysis()
addPathsToProject();

try
    app = PooledAnalysisGUI();
catch ME
    errordlg(sprintf('Failed to launch Pooled Analysis:\n%s', ME.message), 'Error');
    rethrow(ME);
end
end

function addPathsToProject()
mainPath = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(mainPath, 'src')));
end
