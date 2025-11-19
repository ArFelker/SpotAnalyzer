function results = quantifySignals(img, dots, offset, channelName, driftXY)
% quantifySignals Quantify dot and background intensities
%
% INPUTS:
%   img         - Image to quantify (2D array)
%   dots        - Structure array with dot information including masks
%   offset      - Camera offset value (scalar)
%   channelName - Name of the channel (string)
%   driftXY     - [dx, dy] drift correction (default: [0, 0])
%
% OUTPUTS:
%   results - Table with columns: dotID, channel, x_px, y_px, 
%             I_dot, I_bg, K, SNR, driftX, driftY

if nargin < 5, driftXY = [0, 0]; end

img = double(img);
N = numel(dots);

dotID = (1:N)';
channel = repmat(string(channelName), N, 1);
x_px = zeros(N, 1);
y_px = zeros(N, 1);
I_dot = zeros(N, 1);
I_bg = zeros(N, 1);
K = zeros(N, 1);
SNR = zeros(N, 1);
driftX = repmat(driftXY(1), N, 1);
driftY = repmat(driftXY(2), N, 1);

for k = 1:N
    % ROBUST CENTER EXTRACTION
    centerXY = extractCenterAsArray(dots(k).center, k);
    
    if driftXY(1) ~= 0 || driftXY(2) ~= 0
        dotMask = circshift(dots(k).mask, round([driftXY(2), driftXY(1)]));
        bgMask = circshift(dots(k).bgMask, round([driftXY(2), driftXY(1)]));
        x_px(k) = centerXY(1) + driftXY(1);
        y_px(k) = centerXY(2) + driftXY(2);
    else
        dotMask = dots(k).mask;
        bgMask = dots(k).bgMask;
        x_px(k) = centerXY(1);
        y_px(k) = centerXY(2);
    end
    
    I_dot(k) = mean(img(dotMask));
    
    if isfield(dots(k), 'bgValue') && driftXY(1) == 0 && driftXY(2) == 0
        I_bg(k) = dots(k).bgValue;
    else
        I_bg(k) = mean(img(bgMask));
    end
    
    K(k) = (I_dot(k) - offset) / (I_bg(k) - offset);
    SNR(k) = (I_dot(k) - I_bg(k)) / std(img(bgMask));
end

results = table(dotID, channel, x_px, y_px, I_dot, I_bg, K, SNR, driftX, driftY);
end

function centerArray = extractCenterAsArray(center, dotIndex)
    % ROBUST extraction of center coordinates as [x, y] array
    
    % Case 1: Already a numeric array
    if isnumeric(center)
        if numel(center) == 2
            centerArray = reshape(center, 1, 2);
            return;
        else
            error('Dot %d: center is numeric but has %d elements (expected 2)', ...
                dotIndex, numel(center));
        end
    end
    
    % Case 2: Struct with x,y fields
    if isstruct(center)
        if isfield(center, 'x') && isfield(center, 'y')
            centerArray = [center.x, center.y];
            return;
        elseif isfield(center, 'X') && isfield(center, 'Y')
            centerArray = [center.X, center.Y];
            return;
        else
            error('Dot %d: center is struct but fields are: %s', ...
                dotIndex, strjoin(fieldnames(center), ', '));
        end
    end
    
    % Case 3: Cell array
    if iscell(center)
        if numel(center) == 2
            centerArray = [center{1}, center{2}];
            return;
        else
            error('Dot %d: center is cell but has %d elements', dotIndex, numel(center));
        end
    end
    
    % Unknown type
    error('Dot %d: center has unknown type: %s', dotIndex, class(center));
end
