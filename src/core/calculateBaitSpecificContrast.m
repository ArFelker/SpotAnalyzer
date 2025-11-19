function results = calculateBaitSpecificContrast(baitResults, preyResults, dots, roiMask)
% calculateBaitSpecificContrast Calculate bait-specific prey contrast
%
% This function calculates the bait-normalized specificity and prey-specific contrast:
%   C_bait_norm = (I_bait_in - I_bait_out) / (I_bait_in - I_bg)
%   C_prey_spec = C_prey / C_bait_norm
%
% INPUTS:
%   baitResults - Table with bait quantification (must have I_dot, I_bg)
%   preyResults - Table with prey quantification (must have K values)
%   dots        - Structure array with dot information
%   roiMask     - ROI mask (optional, for I_out calculation)
%
% OUTPUTS:
%   results - Table with columns: dotID, channel, C_bait_norm, C_prey_spec, Specificity

if nargin < 4 || isempty(roiMask)
    useROI = false;
else
    useROI = true;
end

nDots = height(baitResults);
preyChannels = unique(preyResults.channel);
nPrey = numel(preyChannels);

dotID = [];
channel = [];
C_bait_norm = [];
C_prey_spec = [];
Specificity = [];

for p = 1:nPrey
    preyChannel = preyChannels(p);
    preyData = preyResults(preyResults.channel == preyChannel, :);
    
    for k = 1:nDots
        I_bait_in = baitResults.I_dot(k);
        I_bait_bg = baitResults.I_bg(k);
        
        if useROI
            dotMask = dots(k).mask;
            invertedMask = roiMask & ~dotMask;
            
            if nnz(invertedMask) > 0
                I_bait_out = I_bait_bg;
            else
                I_bait_out = I_bait_bg;
            end
        else
            I_bait_out = I_bait_bg;
        end
        
        C_bait_norm_val = (I_bait_in - I_bait_out) / (I_bait_in - I_bait_bg + eps);
        
        if preyData.dotID(k) ~= k
            warning('Dot ID mismatch for %s, dot %d', preyChannel, k);
            continue;
        end
        
        C_prey = preyData.K(k);
        C_prey_spec_val = C_prey / (C_bait_norm_val + eps);
        
        spec_val = C_bait_norm_val;
        
        dotID = [dotID; k];
        channel = [channel; preyChannel];
        C_bait_norm = [C_bait_norm; C_bait_norm_val];
        C_prey_spec = [C_prey_spec; C_prey_spec_val];
        Specificity = [Specificity; spec_val];
    end
end

results = table(dotID, channel, C_bait_norm, C_prey_spec, Specificity);
end
