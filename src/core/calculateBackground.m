function dots = calculateBackground(dots, img, imgSize, polyMask, ringExpandPx)
% calculateBackground Calculate background values using expanded ring region
%
% INPUTS:
%   dots         - Structure array with dots and bgMask fields
%   img          - Image for background calculation
%   imgSize      - [height, width] of image
%   polyMask     - Optional polygon mask ([] if none)
%   ringExpandPx - Expansion width beyond ring (default: 1)
%
% OUTPUTS:
%   dots - Updated structure array with bgValue field added

if nargin < 5, ringExpandPx = 1; end

img = double(img);
[X, Y] = meshgrid(1:imgSize(2), 1:imgSize(1));

for k = 1:numel(dots)
    ring = dots(k).bgMask;
    
    [yr, xr] = find(ring);
    rOuter = max(hypot(xr - dots(k).center(1), yr - dots(k).center(2)));
    
    rStripMin = rOuter + 0.5;
    rStripMax = rOuter + ringExpandPx + 0.5;
    
    dist2 = (X - dots(k).center(1)).^2 + (Y - dots(k).center(2)).^2;
    stripMask = dist2 <= rStripMax^2 & dist2 > rStripMin^2;
    
    if ~isempty(polyMask)
        stripMask = stripMask & polyMask;
    end
    
    if nnz(stripMask) > 0
        dots(k).bgValue = mean(img(stripMask));
    else
        dots(k).bgValue = mean(img(ring));
    end
end
end
