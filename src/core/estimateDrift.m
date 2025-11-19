function [driftXY, confidence] = estimateDrift(refImg, targetImg, mask, method)
% estimateDrift Estimate drift between two images
%
% INPUTS:
%   refImg    - Reference image (typically bait)
%   targetImg - Target image to align (typically prey)
%   mask      - Optional mask to restrict analysis region
%   method    - 'crosscorr' or 'manual' (default: 'crosscorr')
%
% OUTPUTS:
%   driftXY    - [dx, dy] estimated drift in pixels
%   confidence - Confidence metric (0-1), peak correlation value

if nargin < 4, method = 'crosscorr'; end
if nargin < 3 || isempty(mask), mask = true(size(refImg)); end

refImg = double(refImg);
targetImg = double(targetImg);

switch lower(method)
    case 'crosscorr'
        refMasked = refImg .* mask;
        targetMasked = targetImg .* mask;
        
        refMasked = refMasked - mean(refMasked(mask));
        targetMasked = targetMasked - mean(targetMasked(mask));
        
        c = normxcorr2(refMasked, targetMasked);
        
        [maxCorr, imax] = max(c(:));
        [ypeak, xpeak] = ind2sub(size(c), imax);
        
        yOffset = ypeak - size(refImg, 1);
        xOffset = xpeak - size(refImg, 2);
        
        driftXY = [xOffset, yOffset];
        confidence = maxCorr;
        
        maxShift = 10;
        if abs(driftXY(1)) > maxShift || abs(driftXY(2)) > maxShift
            warning('Large drift detected (%.1f, %.1f px). Results may be unreliable.', ...
                driftXY(1), driftXY(2));
            confidence = confidence * 0.5;
        end
        
    case 'manual'
        driftXY = [0, 0];
        confidence = 1.0;
        
    otherwise
        error('Unknown drift estimation method: %s', method);
end
end
