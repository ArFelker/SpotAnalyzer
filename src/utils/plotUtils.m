function plotUtils(ax, img, dots, ringMasks, params)
% plotDetectionOverlay Display image with detected dots and rings
%
% INPUTS:
%   ax        - Axes handle
%   img       - Image to display
%   dots      - Detected dots structure
%   ringMasks - Cell array of ring masks (optional)
%   params    - Display parameters (optional)

if nargin < 4, ringMasks = []; end
if nargin < 5, params = struct(); end

showRings = getFieldOrDefault(params, 'showRings', true);
showDots = getFieldOrDefault(params, 'showDots', true);
dotColor = getFieldOrDefault(params, 'dotColor', 'r');
ringColor = getFieldOrDefault(params, 'ringColor', 'b');

cla(ax);
imshow(img, [], 'Parent', ax);
hold(ax, 'on');

if showDots && ~isempty(dots)
    centers = vertcat(dots.center);
    radii = [dots.radius]';
    viscircles(ax, centers, radii, 'Color', dotColor, 'LineWidth', 1.5);
end

if showRings && ~isempty(ringMasks)
    [Ny, Nx] = size(img);
    alphaMap = zeros(Ny, Nx, 'single');
    
    for k = 1:numel(ringMasks)
        if ~isempty(ringMasks{k})
            alphaMap = alphaMap + single(ringMasks{k});
        end
    end
    
    alphaMap = min(alphaMap, 1) * 0.25;
    
    overlay = imshow(cat(3, zeros(Ny, Nx), zeros(Ny, Nx), ones(Ny, Nx)), ...
        'Parent', ax);
    set(overlay, 'AlphaData', alphaMap);
end

hold(ax, 'off');
axis(ax, 'image', 'off');
end

function createHeatmapPlot(ax, x, y, values, titleStr)
% createHeatmapPlot Create heatmap scatter plot
%
% INPUTS:
%   ax       - Axes handle
%   x, y     - Coordinates
%   values   - Color values
%   titleStr - Title string

scatter(ax, x, y, 30, values, 'filled');
colormap(ax, 'parula');
colorbar(ax);
axis(ax, 'equal', 'ij', 'off');
title(ax, titleStr);
end

function createHistogramWithKDE(ax, data, titleStr)
% createHistogramWithKDE Create histogram with kernel density overlay
%
% INPUTS:
%   ax       - Axes handle
%   data     - Data vector
%   titleStr - Title string

data = data(~isnan(data));
if isempty(data), return; end

histogram(ax, data, 30, 'Normalization', 'pdf', 'FaceColor', [0.7, 0.7, 0.9]);
hold(ax, 'on');

try
    [f, xi] = ksdensity(data, 'Support', 'positive');
    plot(ax, xi, f, 'r', 'LineWidth', 1.5);
catch
    [f, xi] = ksdensity(data);
    plot(ax, xi, f, 'r', 'LineWidth', 1.5);
end

hold(ax, 'off');
title(ax, titleStr);
xlabel(ax, 'Value');
ylabel(ax, 'Density');
end

function createECDFPlot(ax, dataMap, titleStr)
% createECDFPlot Create empirical CDF plot for multiple channels
%
% INPUTS:
%   ax      - Axes handle
%   dataMap - Containers.Map with channel names as keys, data as values
%   titleStr - Title string

hold(ax, 'on');
channels = keys(dataMap);
legendEntries = {};

for i = 1:numel(channels)
    ch = channels{i};
    data = dataMap(ch);
    data = data(~isnan(data));
    
    if ~isempty(data)
        [f, x] = ecdf(data);
        plot(ax, x, f, 'LineWidth', 1.5);
        legendEntries{end+1} = char(ch);
    end
end

hold(ax, 'off');
legend(ax, legendEntries, 'Location', 'southeast');
title(ax, titleStr);
xlabel(ax, 'Value');
ylabel(ax, 'F(x)');
grid(ax, 'on');
end

function val = getFieldOrDefault(s, field, default)
if isfield(s, field)
    val = s.(field);
else
    val = default;
end
end
