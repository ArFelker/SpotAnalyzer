function [dots, debugInfo] = detectNanodots(img, mask, params)
% detectNanodots Detect nanodots using Laplacian of Gaussian (LoG) filter
%
% INPUTS:
%   img    - Input image (2D array)
%   mask   - Binary mask defining analysis region
%   params - Structure with fields:
%            .sigma      - LoG filter sigma (default: 1.75)
%            .threshold  - Detection threshold in std units (default: 1.0)
%            .minMeanI   - Minimum mean intensity (default: 0)
%            .minArea    - Minimum area in pixels (default: 10)
%            .minRound   - Minimum roundness (default: 0.6)
%            .maxRound   - Maximum roundness (default: 1.3)
%            .minCenterDist - Minimum center distance (default: 0)
%
% OUTPUTS:
%   dots      - Structure array with detected nanodots
%   debugInfo - Structure with intermediate results for visualization

if nargin < 3, params = struct(); end

sigma = getParamValue(params, 'sigma', 1.75);
threshold = getParamValue(params, 'threshold', 1.0);
minMeanI = getParamValue(params, 'minMeanI', 0);
minArea = getParamValue(params, 'minArea', 10);
minRound = getParamValue(params, 'minRound', 0.6);
maxRound = getParamValue(params, 'maxRound', 1.3);
minCenterDist = getParamValue(params, 'minCenterDist', 0);

img = double(img);
if isempty(mask), mask = true(size(img)); end

hsize = ceil(6 * sigma);
logFilter = fspecial('log', hsize, sigma);
logImg = imfilter(img, logFilter, 'replicate', 'same');
logImg(~mask) = 0;

peakMask = imregionalmin(logImg) & (logImg < -threshold * std(logImg(:)));
CC = bwconncomp(peakMask, 8);

rEstimate = sqrt(2) * sigma;
dots = struct('center', {}, 'radius', {}, 'metric', {}, 'mask', {});

for i = 1:CC.NumObjects
    [y, x] = ind2sub(size(img), CC.PixelIdxList{i});
    center = [mean(x), mean(y)];
    
    [X, Y] = meshgrid(1:size(img, 2), 1:size(img, 1));
    circMask = ((X - center(1)).^2 + (Y - center(2)).^2) <= rEstimate^2 & mask;
    
    if nnz(circMask) == 0, continue; end
    
    I = img(circMask);
    area = nnz(circMask);
    perim = nnz(bwperim(circMask, 8));
    roundness = 4 * pi * area / (perim^2 + eps);
    
    dots(end+1) = struct('center', center, 'radius', rEstimate, ...
        'metric', struct('meanI', mean(I), 'area', area, 'roundness', roundness), ...
        'mask', circMask);
end

dots = applyFilters(dots, minMeanI, minArea, minRound, maxRound, minCenterDist);

debugInfo.logImg = logImg;
debugInfo.peakMask = peakMask;
debugInfo.nDetected = numel(dots);
end

function dots = applyFilters(dots, minMeanI, minArea, minRound, maxRound, minCenterDist)
if isempty(dots), return; end

keep = true(size(dots));
centers = vertcat(dots.center);

if minCenterDist > 0 && size(centers, 1) > 1
    distMatrix = computeDistanceMatrix(centers);
    distMatrix(eye(size(distMatrix)) == 1) = inf;
    tooClose = any(distMatrix < minCenterDist, 2);
else
    tooClose = false(size(centers, 1), 1);
end

for k = 1:numel(dots)
    m = dots(k).metric;
    keep(k) = m.meanI >= minMeanI && ...
              m.area >= minArea && ...
              m.roundness >= minRound && ...
              m.roundness <= maxRound && ...
              ~tooClose(k);
end

dots = dots(keep);
end

function val = getParamValue(params, field, default)
if isfield(params, field)
    val = params.(field);
else
    val = default;
end
end

function D = computeDistanceMatrix(points)
% Compute pairwise distance matrix without Statistics Toolbox
n = size(points, 1);
D = zeros(n, n);
for i = 1:n
    for j = i+1:n
        d = sqrt(sum((points(i,:) - points(j,:)).^2));
        D(i,j) = d;
        D(j,i) = d;
    end
end
end
