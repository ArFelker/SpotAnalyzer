function step2_DefineROI(app)
if ~isfield(app.Data, 'baitImg') || isempty(app.Data.baitImg)
    uialert(app.Fig, 'Please load bait image first (Step 1).', 'No Data');
    return;
end

% Create parameter grid
grid = uigridlayout(app.ParamPanel, [4, 2]);
grid.RowHeight = {35, 40, 40, '1x'};
grid.ColumnWidth = {130, '1x'};
grid.RowSpacing = 10;
grid.Padding = [10 10 10 10];
grid.Scrollable = 'on';

% Row 1: Contrast method
lbl1 = uilabel(grid);
lbl1.Text = 'Contrast Method:';
lbl1.Layout.Row = 1;
lbl1.Layout.Column = 1;
lbl1.HorizontalAlignment = 'right';
lbl1.FontWeight = 'bold';
lbl1.FontSize = 11;

methodDropdown = uidropdown(grid);
methodDropdown.Items = {'Stretch (1-99.9%)', 'CLAHE', 'None'};
methodDropdown.Value = 'Stretch (1-99.9%)';
methodDropdown.ValueChangedFcn = @updatePreview;
methodDropdown.Layout.Row = 1;
methodDropdown.Layout.Column = 2;

% Row 2: Draw ROI button
btn1 = uibutton(grid, 'push');
btn1.Text = 'Draw Polygon ROI';
btn1.ButtonPushedFcn = @drawROI;
btn1.Layout.Row = 2;
btn1.Layout.Column = [1, 2];
btn1.BackgroundColor = [0.2, 0.5, 0.9];
btn1.FontWeight = 'bold';
btn1.FontColor = [1 1 1];

% Row 3: Clear ROI button
btn2 = uibutton(grid, 'push');
btn2.Text = 'Clear ROI';
btn2.ButtonPushedFcn = @clearROI;
btn2.Layout.Row = 3;
btn2.Layout.Column = [1, 2];

% Row 4: Info
infoLbl = uilabel(grid);
infoLbl.Text = '💡 Tip: Draw a polygon around your region of interest. Double-click to finish.';
infoLbl.Layout.Row = 4;
infoLbl.Layout.Column = [1, 2];
infoLbl.FontColor = [0.3 0.5 0.7];
infoLbl.FontSize = 10;
infoLbl.WordWrap = 'on';
infoLbl.VerticalAlignment = 'top';

app.Data.roiMethod = 'stretch';
updatePreview();

    function updatePreview(~, ~)
        method = methodDropdown.Value;
        
        % Apply contrast enhancement
        if strcmp(method, 'CLAHE')
            app.Data.roiMethod = 'clahe';
            adjImg = applyContrastEnhancement(app.Data.baitImg, 'clahe');
        elseif strcmp(method, 'None')
            app.Data.roiMethod = 'none';
            adjImg = mat2gray(double(app.Data.baitImg));
        else
            app.Data.roiMethod = 'stretch';
            adjImg = applyContrastEnhancement(app.Data.baitImg, 'stretch');
        end
        
        app.Data.baitAdjusted = adjImg;
        
        % Check if ROI overlay is needed
        hasROI = isfield(app.Data, 'roiMask') && ~isempty(app.Data.roiMask);
        
        % Display image with keepHoldOn=true if ROI exists
        displayImageCentered(app.ImageAxes, adjImg, 'Draw Polygon ROI', hasROI);
        
        % Overlay ROI if exists (hold on ist aktiv wenn hasROI=true)
        if hasROI
            roiOverlay = cat(3, ones(size(app.Data.roiMask)), ...
                zeros(size(app.Data.roiMask)), zeros(size(app.Data.roiMask)));
            overlay = imshow(roiOverlay, 'Parent', app.ImageAxes);
            set(overlay, 'AlphaData', 0.3 * double(app.Data.roiMask));
            hold(app.ImageAxes, 'off');
        end
    end

    function drawROI(~, ~)
        title(app.ImageAxes, 'Draw Polygon (double-click to finish)', ...
            'FontSize', 13, 'FontWeight', 'bold');
        
        % Create ROI
        roi = drawpolygon(app.ImageAxes, 'LineWidth', 2.5, 'Color', 'r');
        
        if ~isempty(roi) && isvalid(roi)
            % Wait for user to finish drawing
            wait(roi);
            
            % Check if ROI is still valid after wait
            if ~isvalid(roi)
                return;
            end
            
            % Create mask IMMEDIATELY while ROI is still valid
            try
                app.Data.roiMask = createMask(roi);
                app.Data.roiPoints = roi.Position;
                
                % Delete ROI object before updating display
                delete(roi);
                
                % Now update display
                updatePreview();
            catch ME
                if isvalid(roi)
                    delete(roi);
                end
            end
        end
    end

    function clearROI(~, ~)
        if isfield(app.Data, 'roiMask')
            app.Data = rmfield(app.Data, 'roiMask');
        end
        if isfield(app.Data, 'roiPoints')
            app.Data = rmfield(app.Data, 'roiPoints');
        end
        updatePreview();
    end
end

function imgOut = applyContrastEnhancement(img, method)
    img = double(img);
    
    switch lower(method)
        case 'stretch'
            imgMin = prctile(img(:), 1);
            imgMax = prctile(img(:), 99.9);
            if imgMax > imgMin
                imgOut = (img - imgMin) / (imgMax - imgMin);
                imgOut = max(0, min(1, imgOut));
            else
                imgOut = mat2gray(img);
            end
            
        case 'clahe'
            imgNorm = mat2gray(img);
            imgOut = adapthisteq(imgNorm, 'NumTiles', [8, 8], 'ClipLimit', 0.01);
            
        otherwise
            imgOut = mat2gray(img);
    end
end
