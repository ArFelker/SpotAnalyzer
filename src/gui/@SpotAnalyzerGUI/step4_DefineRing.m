function step4_DefineRing(app)
if ~isfield(app.Data, 'dots') || isempty(app.Data.dots)
    uialert(app.Fig, 'Please detect dots first (Step 3).', 'No Dots');
    return;
end

% Create parameter grid
grid = uigridlayout(app.ParamPanel, [4, 2]);
grid.RowHeight = {35, 35, 40, '1x'};
grid.ColumnWidth = {130, '1x'};
grid.RowSpacing = 10;
grid.Padding = [10 10 10 10];
grid.Scrollable = 'on';

% Row 1: Gap
lbl1 = uilabel(grid);
lbl1.Text = 'Gap (px):';
lbl1.Layout.Row = 1;
lbl1.Layout.Column = 1;
lbl1.HorizontalAlignment = 'right';
lbl1.FontWeight = 'bold';
lbl1.FontSize = 11;

gapEdit = uieditfield(grid, 'numeric');
gapEdit.Value = app.Params.gap;
gapEdit.Limits = [0, 5];
gapEdit.ValueChangedFcn = @(~,~)updateRing();
gapEdit.Layout.Row = 1;
gapEdit.Layout.Column = 2;

% Row 2: Width (fixed to 1 px - display only)
lbl2 = uilabel(grid);
lbl2.Text = 'Background (px):';
lbl2.Layout.Row = 2;
lbl2.Layout.Column = 1;
lbl2.HorizontalAlignment = 'right';
lbl2.FontWeight = 'bold';
lbl2.FontSize = 11;

widthLbl = uilabel(grid);
widthLbl.Text = '1 (fixed)';
widthLbl.Layout.Row = 2;
widthLbl.Layout.Column = 2;
widthLbl.FontColor = [0.3 0.3 0.3];

% Row 3: Result button
resultBtn = uibutton(grid, 'push');
resultBtn.Text = 'Show Ring Statistics';
resultBtn.ButtonPushedFcn = @showStats;
resultBtn.Layout.Row = 3;
resultBtn.Layout.Column = [1, 2];

% Row 4: Info
infoLbl = uilabel(grid);
infoLbl.Text = '💡 Blue=Buffer zone (gap), Green=Background (1px). Background measured in green ring.';
infoLbl.Layout.Row = 4;
infoLbl.Layout.Column = [1, 2];
infoLbl.FontColor = [0.3 0.5 0.7];
infoLbl.FontSize = 10;
infoLbl.WordWrap = 'on';
infoLbl.VerticalAlignment = 'top';

% Fixed width
app.Params.width = 1.0;

updateRing();

    function updateRing()
        gap = gapEdit.Value;
        width = 1.0;
        
        app.Params.gap = gap;
        app.Params.width = width;
        
        polyMask = [];
        if isfield(app.Data, 'roiMask')
            polyMask = app.Data.roiMask;
        end
        
        imgSize = size(app.Data.baitImg);
        [ringMasks, validFlags] = calculateRingMask(app.Data.dots, imgSize, ...
            gap, width, polyMask, 0.90);
        
        app.Data.ringMasks = ringMasks;
        app.Data.validFlags = validFlags;
        
        for k = 1:numel(app.Data.dots)
            app.Data.dots(k).bgMask = ringMasks{k};
        end
        
        % Filter to valid dots only
        app.Data.dots = app.Data.dots(validFlags);
        app.Data.ringMasks = ringMasks(validFlags);
        
        % Display base image
        displayImageCentered(app.ImageAxes, app.Data.baitImg, ...
            sprintf('Gap=%.2f px | 🔵Buffer 🟢Background | Valid: %d/%d', ...
            gap, nnz(validFlags), numel(validFlags)), true);
        
        % Create buffer zone mask (blue) - from r to r+gap
        bufferMask = zeros(imgSize, 'single');
        for k = 1:numel(app.Data.dots)
            center = extractCenterAsArray(app.Data.dots(k).center, k);
            [xx, yy] = meshgrid(1:imgSize(2), 1:imgSize(1));
            dist = sqrt((xx - center(1)).^2 + (yy - center(2)).^2);
            bufferMask = bufferMask + single(dist > app.Data.dots(k).radius & dist <= app.Data.dots(k).radius + gap);
        end
        bufferMask = min(bufferMask, 1);
        
        % Display blue buffer zone
        blueOverlay = zeros([imgSize, 3]);
        blueOverlay(:,:,3) = 1;
        h1 = imagesc(app.ImageAxes, blueOverlay);
        set(h1, 'AlphaData', bufferMask * 0.3);
        
        % Create background ring mask (green) - 1 pixel at r+gap to r+gap+1
        bgMask = zeros(imgSize, 'single');
        for k = 1:numel(app.Data.ringMasks)
            bgMask = bgMask + single(app.Data.ringMasks{k});
        end
        bgMask = min(bgMask, 1);
        
        % Display green background ring
        greenOverlay = zeros([imgSize, 3]);
        greenOverlay(:,:,2) = 1;
        h2 = imagesc(app.ImageAxes, greenOverlay);
        set(h2, 'AlphaData', bgMask * 0.5);
        
        % Draw circles
        if ~isempty(app.Data.dots)
            centers = zeros(numel(app.Data.dots), 2);
            for k = 1:numel(app.Data.dots)
                centers(k,:) = extractCenterAsArray(app.Data.dots(k).center, k);
            end
            radii = [app.Data.dots.radius]';
            
            % Spot circles (red)
            viscircles(app.ImageAxes, centers, radii, 'Color', 'r', 'LineWidth', 1.5);
            
            % Buffer zone boundary (blue)
            viscircles(app.ImageAxes, centers, radii + gap, 'Color', 'b', 'LineWidth', 1.2);
            
            % Background ring boundary (green)
            viscircles(app.ImageAxes, centers, radii + gap + width, 'Color', 'g', 'LineWidth', 1.2);
        end
        
        hold(app.ImageAxes, 'off');
    end

    function centerArray = extractCenterAsArray(center, dotIndex)
        if isnumeric(center)
            if numel(center) == 2
                centerArray = reshape(center, 1, 2);
                return;
            else
                error('Dot %d: center has %d elements (expected 2)', dotIndex, numel(center));
            end
        end
        
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
        
        if iscell(center)
            if numel(center) == 2
                centerArray = [center{1}, center{2}];
                return;
            else
                error('Dot %d: center is cell but has %d elements', dotIndex, numel(center));
            end
        end
        
        error('Dot %d: center has unknown type: %s', dotIndex, class(center));
    end

    function showStats(~, ~)
        if ~isfield(app.Data, 'ringMasks') || isempty(app.Data.ringMasks)
            uialert(app.Fig, 'No ring masks available.', 'No Data');
            return;
        end
        
        nDots = numel(app.Data.ringMasks);
        ringAreas = cellfun(@(x) sum(x(:)), app.Data.ringMasks);
        
        msgText = sprintf(['Ring Statistics:\n\n' ...
            'Valid dots: %d\n' ...
            'Buffer zone: %.2f pixels\n' ...
            'Background: 1 pixel (green ring)\n\n' ...
            'Background areas:\n' ...
            '  Mean: %.1f pixels\n' ...
            '  Min: %d pixels\n' ...
            '  Max: %d pixels'], ...
            nDots, app.Params.gap, ...
            mean(ringAreas), min(ringAreas), max(ringAreas));
        
        uialert(app.Fig, msgText, 'Ring Statistics', 'Icon', 'info');
    end
end
