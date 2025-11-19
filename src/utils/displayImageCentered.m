function displayImageCentered(ax, img, titleText, keepHoldOn)
% displayImageCentered - Zeigt Bild mittig, vollflächig und groß an
%
% INPUTS:
%   ax         - UIAxes handle
%   img        - Bild (grayscale oder RGB)
%   titleText  - Titel (optional)
%   keepHoldOn - true = hold on bleibt aktiv für Overlays (default: false)

if nargin < 3
    titleText = '';
end

if nargin < 4
    keepHoldOn = false;
end

% Clear axes
cla(ax);
hold(ax, 'off');

% Display image using imagesc for full-size display
imagesc(ax, img);
colormap(ax, 'gray');

% Set axes properties for full-size, centered display
axis(ax, 'image');      % Preserve aspect ratio
axis(ax, 'tight');      % Remove whitespace
axis(ax, 'off');        % Hide axes ticks

% Make sure axes fills the parent completely
ax.Units = 'normalized';
ax.Position = [0.02, 0.02, 0.96, 0.96];

% Set proper data aspect ratio
daspect(ax, [1 1 1]);

% Set limits to show full image
xlim(ax, [0.5, size(img, 2) + 0.5]);
ylim(ax, [0.5, size(img, 1) + 0.5]);

% Set title if provided
if ~isempty(titleText)
    title(ax, titleText, 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'k');
end

% Enable zoom and pan
zoom(ax, 'on');
pan(ax, 'on');

% WICHTIG: Wenn keepHoldOn=true, hold on für Overlays aktivieren
if keepHoldOn
    hold(ax, 'on');
end

end
