function step3_DetectDots(app)
if ~isfield(app.Data, 'baitImg') || isempty(app.Data.baitImg)
    uialert(app.Fig, 'Please load bait image first.', 'No Data');
    return;
end

% Get ROI mask if exists
mask = [];
if isfield(app.Data, 'roiMask')
    mask = app.Data.roiMask;
end

% Create scrollable parameter grid
grid = uigridlayout(app.ParamPanel, [10, 2]);
grid.RowHeight = {40, 40, 40, 40, 40, 40, 40, 40, 50, 60};
grid.ColumnWidth = {140, '1x'};
grid.RowSpacing = 12;
grid.Padding = [15 15 15 15];
grid.Scrollable = 'on';

% Store UI elements
if ~isfield(app.Data, 'step3UI')
    app.Data.step3UI = struct();
end

% Row 1: Sigma
lbl1 = uilabel(grid);
lbl1.Text = 'Sigma (px):';
lbl1.Layout.Row = 1;
lbl1.Layout.Column = 1;
lbl1.HorizontalAlignment = 'right';
lbl1.FontWeight = 'bold';

app.Data.step3UI.sigmaEdit = uieditfield(grid, 'numeric');
app.Data.step3UI.sigmaEdit.Value = app.Params.sigma;
app.Data.step3UI.sigmaEdit.Limits = [0.5, 5];
app.Data.step3UI.sigmaEdit.Layout.Row = 1;
app.Data.step3UI.sigmaEdit.Layout.Column = 2;
app.Data.step3UI.sigmaEdit.ValueChangedFcn = @(~,~) updateDetection();

% Row 2: Threshold
lbl2 = uilabel(grid);
lbl2.Text = 'Threshold:';
lbl2.Layout.Row = 2;
lbl2.Layout.Column = 1;
lbl2.HorizontalAlignment = 'right';
lbl2.FontWeight = 'bold';

app.Data.step3UI.thrEdit = uieditfield(grid, 'numeric');
app.Data.step3UI.thrEdit.Value = app.Params.threshold;
app.Data.step3UI.thrEdit.Limits = [0, 3];
app.Data.step3UI.thrEdit.Layout.Row = 2;
app.Data.step3UI.thrEdit.Layout.Column = 2;
app.Data.step3UI.thrEdit.ValueChangedFcn = @(~,~) updateDetection();

% Row 3: Min Mean Intensity
lbl3 = uilabel(grid);
lbl3.Text = 'Min Mean I:';
lbl3.Layout.Row = 3;
lbl3.Layout.Column = 1;
lbl3.HorizontalAlignment = 'right';
lbl3.FontWeight = 'bold';

app.Data.step3UI.minIEdit = uieditfield(grid, 'numeric');
app.Data.step3UI.minIEdit.Value = app.Params.minMeanI;
app.Data.step3UI.minIEdit.Layout.Row = 3;
app.Data.step3UI.minIEdit.Layout.Column = 2;
app.Data.step3UI.minIEdit.ValueChangedFcn = @(~,~) updateDetection();

% Row 4: Min Area
lbl4 = uilabel(grid);
lbl4.Text = 'Min Area:';
lbl4.Layout.Row = 4;
lbl4.Layout.Column = 1;
lbl4.HorizontalAlignment = 'right';
lbl4.FontWeight = 'bold';

app.Data.step3UI.minAreaEdit = uieditfield(grid, 'numeric');
app.Data.step3UI.minAreaEdit.Value = app.Params.minArea;
app.Data.step3UI.minAreaEdit.Layout.Row = 4;
app.Data.step3UI.minAreaEdit.Layout.Column = 2;
app.Data.step3UI.minAreaEdit.ValueChangedFcn = @(~,~) updateDetection();

% Row 5: Min Roundness
lbl5 = uilabel(grid);
lbl5.Text = 'Min Roundness:';
lbl5.Layout.Row = 5;
lbl5.Layout.Column = 1;
lbl5.HorizontalAlignment = 'right';
lbl5.FontWeight = 'bold';

app.Data.step3UI.minRoundEdit = uieditfield(grid, 'numeric');
app.Data.step3UI.minRoundEdit.Value = app.Params.minRound;
app.Data.step3UI.minRoundEdit.Layout.Row = 5;
app.Data.step3UI.minRoundEdit.Layout.Column = 2;
app.Data.step3UI.minRoundEdit.ValueChangedFcn = @(~,~) updateDetection();

% Row 6: Max Roundness
lbl6 = uilabel(grid);
lbl6.Text = 'Max Roundness:';
lbl6.Layout.Row = 6;
lbl6.Layout.Column = 1;
lbl6.HorizontalAlignment = 'right';
lbl6.FontWeight = 'bold';

app.Data.step3UI.maxRoundEdit = uieditfield(grid, 'numeric');
app.Data.step3UI.maxRoundEdit.Value = app.Params.maxRound;
app.Data.step3UI.maxRoundEdit.Layout.Row = 6;
app.Data.step3UI.maxRoundEdit.Layout.Column = 2;
app.Data.step3UI.maxRoundEdit.ValueChangedFcn = @(~,~) updateDetection();

% Row 7: Min Center Distance
lbl7 = uilabel(grid);
lbl7.Text = 'Min Center Dist:';
lbl7.Layout.Row = 7;
lbl7.Layout.Column = 1;
lbl7.HorizontalAlignment = 'right';
lbl7.FontWeight = 'bold';

app.Data.step3UI.minDistEdit = uieditfield(grid, 'numeric');
app.Data.step3UI.minDistEdit.Value = app.Params.minCenterDist;
app.Data.step3UI.minDistEdit.Layout.Row = 7;
app.Data.step3UI.minDistEdit.Layout.Column = 2;
app.Data.step3UI.minDistEdit.ValueChangedFcn = @(~,~) updateDetection();

% Row 8: Result label
app.Data.step3UI.resultLbl = uilabel(grid);
app.Data.step3UI.resultLbl.Text = 'Detected: 0 dots';
app.Data.step3UI.resultLbl.Layout.Row = 8;
app.Data.step3UI.resultLbl.Layout.Column = [1, 2];
app.Data.step3UI.resultLbl.HorizontalAlignment = 'center';
app.Data.step3UI.resultLbl.FontSize = 13;
app.Data.step3UI.resultLbl.FontWeight = 'bold';
app.Data.step3UI.resultLbl.FontColor = [0.2 0.5 0.9];

% Row 9: Reset button
resetBtn = uibutton(grid, 'push');
resetBtn.Text = 'Reset to Defaults';
resetBtn.Layout.Row = 9;
resetBtn.Layout.Column = [1, 2];
resetBtn.ButtonPushedFcn = @resetDefaults;
resetBtn.FontSize = 11;

% Row 10: Info
infoLbl = uilabel(grid);
infoLbl.Text = '💡 Tip: Use zoom tool to inspect detected dots. Adjust parameters for optimal detection.';
infoLbl.Layout.Row = 10;
infoLbl.Layout.Column = [1, 2];
infoLbl.FontColor = [0.3 0.5 0.7];
infoLbl.WordWrap = 'on';

% Initial detection
updateDetection();

    function updateDetection()
        params = struct();
        params.sigma = app.Data.step3UI.sigmaEdit.Value;
        params.threshold = app.Data.step3UI.thrEdit.Value;
        params.minMeanI = app.Data.step3UI.minIEdit.Value;
        params.minArea = app.Data.step3UI.minAreaEdit.Value;
        params.minRound = app.Data.step3UI.minRoundEdit.Value;
        params.maxRound = app.Data.step3UI.maxRoundEdit.Value;
        params.minCenterDist = app.Data.step3UI.minDistEdit.Value;
        
        try
            [dots, ~] = detectNanodots(app.Data.baitImg, mask, params);
            
            app.Data.dots = dots;
            app.Params.sigma = params.sigma;
            app.Params.threshold = params.threshold;
            app.Params.minMeanI = params.minMeanI;
            app.Params.minArea = params.minArea;
            app.Params.minRound = params.minRound;
            app.Params.maxRound = params.maxRound;
            app.Params.minCenterDist = params.minCenterDist;
            
            % Display with keepHoldOn for circles
            displayImageCentered(app.ImageAxes, app.Data.baitImg, ...
                sprintf('Detected: %d dots', numel(dots)), true);
            
            % Enable zoom
            zoom(app.ImageAxes, 'on');
            
            % Draw circles - ROBUST CENTER EXTRACTION
            if ~isempty(dots)
                % Extract centers robustly
                centers = zeros(numel(dots), 2);
                for k = 1:numel(dots)
                    centers(k,:) = extractCenterAsArray(dots(k).center, k);
                end
                
                radii = [dots.radius]';
                viscircles(app.ImageAxes, centers, radii, ...
                    'Color', 'r', 'LineWidth', 1.5);
            end
            
            hold(app.ImageAxes, 'off');
            
            app.Data.step3UI.resultLbl.Text = sprintf('Detected: %d dots', numel(dots));
            
        catch ME
            uialert(app.Fig, sprintf('Detection error: %s', ME.message), 'Error');
        end
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

    function resetDefaults(~, ~)
        app.Data.step3UI.sigmaEdit.Value = 1.75;
        app.Data.step3UI.thrEdit.Value = 1.0;
        app.Data.step3UI.minIEdit.Value = 0;
        app.Data.step3UI.minAreaEdit.Value = 10;
        app.Data.step3UI.minRoundEdit.Value = 0.6;
        app.Data.step3UI.maxRoundEdit.Value = 1.3;
        app.Data.step3UI.minDistEdit.Value = 0;
        updateDetection();
    end
end
