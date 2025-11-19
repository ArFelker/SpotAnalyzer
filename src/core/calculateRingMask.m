function [ringMasks, validFlags] = calculateRingMask(dots, imgSize, gap, width, polyMask, areaThreshold)
% calculateRingMask Create ring masks for background estimation
%
% INPUTS:
%   dots          - Structure array from detectNanodots
%   imgSize       - [height, width] of image
%   gap           - Gap between dot and inner ring edge (pixels)
%   width         - Width of the ring (pixels)
%   polyMask      - Optional polygon mask ([] if none)
%   areaThreshold - Minimum fraction of ideal ring area (default: 0.90)
%
% OUTPUTS:
%   ringMasks   - Cell array of binary ring masks
%   validFlags  - Logical array indicating valid rings

if nargin < 6, areaThreshold = 0.90; end

N = numel(dots);
ringMasks = cell(1, N);
validFlags = true(1, N);

[X, Y] = meshgrid(1:imgSize(2), 1:imgSize(1));

for k = 1:N
    center = dots(k).center;
    r0 = dots(k).radius;
    
    rInner = r0 + gap;
    rOuter = rInner + width;
    
    x0 = max(1, floor(center(1) - rOuter));
    x1 = min(imgSize(2), ceil(center(1) + rOuter));
    y0 = max(1, floor(center(2) - rOuter));
    y1 = min(imgSize(1), ceil(center(2) + rOuter));
    
    Xsub = X(y0:y1, x0:x1);
    Ysub = Y(y0:y1, x0:x1);
    
    dist2 = (Xsub - center(1)).^2 + (Ysub - center(2)).^2;
    subMask = dist2 <= rOuter^2 & dist2 > rInner^2;
    
    if ~isempty(polyMask)
        subMask = subMask & polyMask(y0:y1, x0:x1);
    end
    
    mask = false(imgSize);
    mask(y0:y1, x0:x1) = subMask;
    
    idealArea = pi * (rOuter^2 - rInner^2);
    actualArea = nnz(subMask);
    validFlags(k) = actualArea >= areaThreshold * idealArea;
    
    ringMasks{k} = mask;
end
end
