function imgOut = imageProcessing(img, method, params)
% enhanceContrast Apply contrast enhancement to image
%
% INPUTS:
%   img    - Input image
%   method - 'stretch' or 'clahe'
%   params - Optional parameters structure
%
% OUTPUTS:
%   imgOut - Enhanced image (scaled 0-1)

if nargin < 2, method = 'stretch'; end
if nargin < 3, params = struct(); end

img = double(img);

switch lower(method)
    case 'stretch'
        lowPct = getFieldOrDefault(params, 'lowPct', 0.1);
        highPct = getFieldOrDefault(params, 'highPct', 99.9);
        
        limits = stretchlim(img, [lowPct/100, highPct/100]);
        imgOut = imadjust(mat2gray(img), limits, []);
        
    case 'clahe'
        nTiles = getFieldOrDefault(params, 'nTiles', [8, 8]);
        clipLimit = getFieldOrDefault(params, 'clipLimit', 0.01);
        
        imgOut = adapthisteq(mat2gray(img), 'NumTiles', nTiles, ...
            'ClipLimit', clipLimit);
        
    otherwise
        imgOut = mat2gray(img);
end
end

function val = getFieldOrDefault(s, field, default)
if isfield(s, field)
    val = s.(field);
else
    val = default;
end
end
