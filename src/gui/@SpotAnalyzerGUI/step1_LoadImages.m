function step1_LoadImages(app)
% Create scrollable parameter grid in right panel
grid = uigridlayout(app.ParamPanel, [6, 2]);
grid.RowHeight = {35, 35, 40, 35, 45, '1x'};
grid.ColumnWidth = {130, '1x'};
grid.RowSpacing = 10;
grid.Padding = [10 10 10 10];
grid.Scrollable = 'on';

% Initialize storage
if ~isfield(app.Data, 'preyInfo')
    app.Data.preyInfo = struct('name', {}, 'path', {}, 'img', {}, 'drift', {});
end
if ~isfield(app.Data, 'step1UI')
    app.Data.step1UI = struct();
end

% Row 1: Pixel Size
lbl1 = uilabel(grid);
lbl1.Text = 'Pixel Size (nm/px):';
lbl1.Layout.Row = 1;
lbl1.Layout.Column = 1;
lbl1.HorizontalAlignment = 'right';
lbl1.FontWeight = 'bold';
lbl1.FontSize = 11;

app.Data.step1UI.pixSizeEdit = uieditfield(grid, 'numeric');
app.Data.step1UI.pixSizeEdit.Value = app.Params.pixelSize;
app.Data.step1UI.pixSizeEdit.Layout.Row = 1;
app.Data.step1UI.pixSizeEdit.Layout.Column = 2;
app.Data.step1UI.pixSizeEdit.ValueChangedFcn = @(~,~) updateParams(app);

% Row 2: Offset
lbl2 = uilabel(grid);
lbl2.Text = 'Offset:';
lbl2.Layout.Row = 2;
lbl2.Layout.Column = 1;
lbl2.HorizontalAlignment = 'right';
lbl2.FontWeight = 'bold';
lbl2.FontSize = 11;

app.Data.step1UI.offsetEdit = uieditfield(grid, 'numeric');
app.Data.step1UI.offsetEdit.Value = app.Params.offset;
app.Data.step1UI.offsetEdit.Layout.Row = 2;
app.Data.step1UI.offsetEdit.Layout.Column = 2;
app.Data.step1UI.offsetEdit.ValueChangedFcn = @(~,~) updateParams(app);

% Row 3: Bait Channel
lbl3 = uilabel(grid);
lbl3.Text = 'Bait Channel:';
lbl3.Layout.Row = 3;
lbl3.Layout.Column = 1;
lbl3.HorizontalAlignment = 'right';
lbl3.FontWeight = 'bold';
lbl3.FontSize = 11;

app.Data.step1UI.baitBtn = uibutton(grid, 'push');
app.Data.step1UI.baitBtn.Text = 'Select Bait File...';
app.Data.step1UI.baitBtn.ButtonPushedFcn = @(~,~) selectBaitCallback(app);
app.Data.step1UI.baitBtn.Layout.Row = 3;
app.Data.step1UI.baitBtn.Layout.Column = 2;
app.Data.step1UI.baitBtn.BackgroundColor = [0.96 0.96 0.96];

% Row 4: Number of Prey
lbl4 = uilabel(grid);
lbl4.Text = 'Number of Prey:';
lbl4.Layout.Row = 4;
lbl4.Layout.Column = 1;
lbl4.HorizontalAlignment = 'right';
lbl4.FontWeight = 'bold';
lbl4.FontSize = 11;

app.Data.step1UI.nPreyEdit = uieditfield(grid, 'numeric');
app.Data.step1UI.nPreyEdit.Value = 0;
app.Data.step1UI.nPreyEdit.Limits = [0, 5];
app.Data.step1UI.nPreyEdit.RoundFractionalValues = 'on';
app.Data.step1UI.nPreyEdit.ValueChangedFcn = @(~,~) updatePreyFieldsCallback(app);
app.Data.step1UI.nPreyEdit.Layout.Row = 4;
app.Data.step1UI.nPreyEdit.Layout.Column = 2;

% Row 5: Channel Alignment Button
alignBtn = uibutton(grid, 'push');
alignBtn.Text = '🔄 Align Channels';
alignBtn.ButtonPushedFcn = @(~,~) alignChannelsCallback(app);
alignBtn.Layout.Row = 5;
alignBtn.Layout.Column = [1, 2];
alignBtn.BackgroundColor = [0.9, 0.7, 0.3];
alignBtn.FontWeight = 'bold';
alignBtn.FontSize = 12;

% Row 6: Info
infoLbl = uilabel(grid);
infoLbl.Text = '💡 Tip: Load bait and prey channels, then use "Align Channels" to correct drift.';
infoLbl.Layout.Row = 6;
infoLbl.Layout.Column = [1, 2];
infoLbl.FontColor = [0.3 0.5 0.7];
infoLbl.FontSize = 10;
infoLbl.WordWrap = 'on';
infoLbl.VerticalAlignment = 'top';

app.Data.step1UI.preyFields = struct('nameEdit', {}, 'pathBtn', {});
end

function updateParams(app)
    app.Params.pixelSize = app.Data.step1UI.pixSizeEdit.Value;
    app.Params.offset = app.Data.step1UI.offsetEdit.Value;
end

function selectBaitCallback(app)
    [file, path] = uigetfile({'*.tif;*.tiff', 'TIFF Files (*.tif, *.tiff)'}, ...
        'Select Bait Channel');
    
    if file == 0, return; end
    
    try
        app.Data.baitPath = fullfile(path, file);
        app.Data.baitImg = imread(app.Data.baitPath);
        
        % Display in square image panel
        displayImageCentered(app.ImageAxes, app.Data.baitImg, 'Bait Channel');
        
        % Update button
        if length(file) > 20
            app.Data.step1UI.baitBtn.Text = ['...' file(end-19:end)];
        else
            app.Data.step1UI.baitBtn.Text = file;
        end
        app.Data.step1UI.baitBtn.BackgroundColor = [0.7, 0.9, 0.7];
        
        updateParams(app);
    catch ME
        uialert(app.Fig, sprintf('Error loading image: %s', ME.message), 'Load Error');
    end
end

function updatePreyFieldsCallback(app)
    nPrey = round(app.Data.step1UI.nPreyEdit.Value);
    
    if nPrey == 0
        app.Data.preyInfo = struct('name', {}, 'path', {}, 'img', {}, 'drift', {});
        return;
    end
    
    % Create prey configuration dialog
    preyFig = uifigure('Name', sprintf('Configure %d Prey Channel(s)', nPrey), ...
        'Position', [250, 250, 550, 80 + nPrey*50]);
    
    preyGrid = uigridlayout(preyFig, [nPrey+1, 3]);
    preyGrid.ColumnWidth = {100, 180, '1x'};
    preyGrid.RowHeight = [repmat({45}, 1, nPrey), {50}];
    preyGrid.RowSpacing = 10;
    preyGrid.Padding = [15 15 15 15];
    
    app.Data.preyInfo = struct('name', {}, 'path', {}, 'img', {}, 'drift', {});
    app.Data.step1UI.preyFields = struct('nameEdit', {}, 'pathBtn', {});
    
    for i = 1:nPrey
        % Label
        lbl = uilabel(preyGrid);
        lbl.Text = sprintf('Prey %d:', i);
        lbl.Layout.Row = i;
        lbl.Layout.Column = 1;
        lbl.HorizontalAlignment = 'right';
        lbl.FontWeight = 'bold';
        
        % Name input
        app.Data.step1UI.preyFields(i).nameEdit = uieditfield(preyGrid, 'text');
        app.Data.step1UI.preyFields(i).nameEdit.Value = sprintf('Prey%d', i);
        app.Data.step1UI.preyFields(i).nameEdit.Layout.Row = i;
        app.Data.step1UI.preyFields(i).nameEdit.Layout.Column = 2;
        
        % Select button
        app.Data.step1UI.preyFields(i).pathBtn = uibutton(preyGrid, 'push');
        app.Data.step1UI.preyFields(i).pathBtn.Text = 'Select File...';
        app.Data.step1UI.preyFields(i).pathBtn.Layout.Row = i;
        app.Data.step1UI.preyFields(i).pathBtn.Layout.Column = 3;
        app.Data.step1UI.preyFields(i).pathBtn.ButtonPushedFcn = @(~,~) selectPreyCallback(app, i, preyFig);
        
        % Initialize
        app.Data.preyInfo(i).name = sprintf('Prey%d', i);
        app.Data.preyInfo(i).path = '';
        app.Data.preyInfo(i).img = [];
        app.Data.preyInfo(i).drift = [0, 0];
    end
    
    % OK button
    okBtn = uibutton(preyGrid, 'push');
    okBtn.Text = '✓ OK - Close';
    okBtn.Layout.Row = nPrey + 1;
    okBtn.Layout.Column = [1, 3];
    okBtn.ButtonPushedFcn = @(~,~) close(preyFig);
    okBtn.BackgroundColor = [0.2, 0.5, 0.9];
    okBtn.FontWeight = 'bold';
    okBtn.FontColor = [1 1 1];
    okBtn.FontSize = 12;
end

function selectPreyCallback(app, idx, parentFig)
    [file, path] = uigetfile({'*.tif;*.tiff', 'TIFF Files (*.tif, *.tiff)'}, ...
        sprintf('Select Prey Channel %d', idx));
    
    if file == 0, return; end
    
    try
        preyName = app.Data.step1UI.preyFields(idx).nameEdit.Value;
        
        app.Data.preyInfo(idx).name = preyName;
        app.Data.preyInfo(idx).path = fullfile(path, file);
        app.Data.preyInfo(idx).img = imread(app.Data.preyInfo(idx).path);
        app.Data.preyInfo(idx).drift = [0, 0];
        
        if length(file) > 18
            app.Data.step1UI.preyFields(idx).pathBtn.Text = ['...' file(end-17:end)];
        else
            app.Data.step1UI.preyFields(idx).pathBtn.Text = file;
        end
        app.Data.step1UI.preyFields(idx).pathBtn.BackgroundColor = [0.7 0.9 0.7];
    catch ME
        uialert(parentFig, sprintf('Error loading prey: %s', ME.message), 'Error');
    end
end

function alignChannelsCallback(app)
    % Prüfe ob Bait geladen ist
    if ~isfield(app.Data, 'baitImg') || isempty(app.Data.baitImg)
        uialert(app.Fig, 'Please load bait channel first.', 'No Bait');
        return;
    end
    
    % Prüfe ob Prey geladen ist
    if ~isfield(app.Data, 'preyInfo') || isempty(app.Data.preyInfo) || ...
            isempty(app.Data.preyInfo(1).img)
        uialert(app.Fig, 'Please load at least one prey channel.', 'No Prey');
        return;
    end
    
    % Create alignment dialog
    alignFig = uifigure('Name', 'Channel Alignment', ...
        'Position', [300, 300, 600, 150 + numel(app.Data.preyInfo)*100]);
    
    mainGrid = uigridlayout(alignFig, [numel(app.Data.preyInfo)+2, 1]);
    mainGrid.RowHeight = [50, repmat({100}, 1, numel(app.Data.preyInfo)), {60}];
    mainGrid.Padding = [20 20 20 20];
    mainGrid.RowSpacing = 15;
    
    % Title
    titleLbl = uilabel(mainGrid);
    titleLbl.Text = 'Channel Alignment: Bait ↔ Prey (Live Preview)';
    titleLbl.Layout.Row = 1;
    titleLbl.FontSize = 16;
    titleLbl.FontWeight = 'bold';
    titleLbl.HorizontalAlignment = 'center';
    titleLbl.FontColor = [0.2 0.5 0.9];
    
    % Store UI elements for each prey
    preyPanels = cell(numel(app.Data.preyInfo), 1);
    
    % For each prey channel
    for i = 1:numel(app.Data.preyInfo)
        preyPanel = uipanel(mainGrid);
        preyPanel.Title = sprintf('Prey %d: %s', i, app.Data.preyInfo(i).name);
        preyPanel.FontWeight = 'bold';
        preyPanel.Layout.Row = i + 1;
        
        preyGrid = uigridlayout(preyPanel, [3, 4]);
        preyGrid.ColumnWidth = {120, 120, '1x', 120};
        preyGrid.RowHeight = {35, 35, 30};
        preyGrid.Padding = [10 10 10 10];
        
        % Row 1: Auto and Manual buttons
        autoBtn = uibutton(preyGrid, 'push');
        autoBtn.Text = '🤖 Auto';
        autoBtn.Layout.Row = 1;
        autoBtn.Layout.Column = 1;
        autoBtn.ButtonPushedFcn = @(~,~) autoAlignCallback(app, i);
        autoBtn.BackgroundColor = [0.2, 0.7, 0.3];
        autoBtn.FontColor = [1 1 1];
        autoBtn.FontWeight = 'bold';
        
        manualBtn = uibutton(preyGrid, 'push');
        manualBtn.Text = '✋ Manual';
        manualBtn.Layout.Row = 1;
        manualBtn.Layout.Column = 2;
        manualBtn.ButtonPushedFcn = @(~,~) manualAlignCallback(app, i);
        manualBtn.BackgroundColor = [0.9, 0.7, 0.3];
        manualBtn.FontColor = [1 1 1];
        manualBtn.FontWeight = 'bold';
        
        % Drift label
        driftLbl = uilabel(preyGrid);
        driftLbl.Text = sprintf('Drift: [%.2f, %.2f] px', ...
            app.Data.preyInfo(i).drift(1), app.Data.preyInfo(i).drift(2));
        driftLbl.Layout.Row = 1;
        driftLbl.Layout.Column = 3;
        driftLbl.FontSize = 11;
        driftLbl.HorizontalAlignment = 'center';
        driftLbl.Tag = sprintf('driftLbl_%d', i);
        
        % Preview button
        previewBtn = uibutton(preyGrid, 'push');
        previewBtn.Text = '👁 Preview';
        previewBtn.Layout.Row = 1;
        previewBtn.Layout.Column = 4;
        previewBtn.ButtonPushedFcn = @(~,~) previewAlignmentCallback(app, i);
        
        % Row 2: Manual input fields (LIVE UPDATE)
        lbl1 = uilabel(preyGrid);
        lbl1.Text = 'dx (px):';
        lbl1.Layout.Row = 2;
        lbl1.Layout.Column = 1;
        lbl1.HorizontalAlignment = 'right';
        
        dxEdit = uieditfield(preyGrid, 'numeric');
        dxEdit.Value = app.Data.preyInfo(i).drift(1);
        dxEdit.Limits = [-50, 50];
        dxEdit.Layout.Row = 2;
        dxEdit.Layout.Column = 2;
        dxEdit.Tag = sprintf('dxEdit_%d', i);
        dxEdit.ValueChangedFcn = @(~,~) liveUpdateDrift(app, i, 'dx', dxEdit.Value);
        
        lbl2 = uilabel(preyGrid);
        lbl2.Text = 'dy (px):';
        lbl2.Layout.Row = 2;
        lbl2.Layout.Column = 3;
        lbl2.HorizontalAlignment = 'right';
        
        dyEdit = uieditfield(preyGrid, 'numeric');
        dyEdit.Value = app.Data.preyInfo(i).drift(2);
        dyEdit.Limits = [-50, 50];
        dyEdit.Layout.Row = 2;
        dyEdit.Layout.Column = 4;
        dyEdit.Tag = sprintf('dyEdit_%d', i);
        dyEdit.ValueChangedFcn = @(~,~) liveUpdateDrift(app, i, 'dy', dyEdit.Value);
        
        % Row 3: Info
        infoLbl = uilabel(preyGrid);
        infoLbl.Text = 'Tip: Type drift values for live preview, or use Auto/Manual buttons.';
        infoLbl.Layout.Row = 3;
        infoLbl.Layout.Column = [1, 4];
        infoLbl.FontColor = [0.4 0.4 0.4];
        infoLbl.FontSize = 10;
        
        preyPanels{i} = preyPanel;
    end
    
    % Close button
    closeBtn = uibutton(mainGrid, 'push');
    closeBtn.Text = '✓ Done';
    closeBtn.Layout.Row = numel(app.Data.preyInfo) + 2;
    closeBtn.ButtonPushedFcn = @(~,~) close(alignFig);
    closeBtn.BackgroundColor = [0.2, 0.5, 0.9];
    closeBtn.FontColor = [1 1 1];
    closeBtn.FontWeight = 'bold';
    closeBtn.FontSize = 14;
    
    % Initial preview of first prey
    previewAlignmentCallback(app, 1);
end

function liveUpdateDrift(app, preyIdx, axis, value)
    % Update drift value
    if strcmp(axis, 'dx')
        app.Data.preyInfo(preyIdx).drift(1) = value;
    else
        app.Data.preyInfo(preyIdx).drift(2) = value;
    end
    
    % Update drift label
    driftLbl = findobj(groot, 'Tag', sprintf('driftLbl_%d', preyIdx));
    if ~isempty(driftLbl)
        driftLbl.Text = sprintf('Drift: [%.2f, %.2f] px', ...
            app.Data.preyInfo(preyIdx).drift(1), ...
            app.Data.preyInfo(preyIdx).drift(2));
    end
    
    % Live preview update
    previewAlignmentCallback(app, preyIdx);
end

function autoAlignCallback(app, preyIdx)
    try
        mask = [];
        if isfield(app.Data, 'roiMask')
            mask = app.Data.roiMask;
        end
        
        [driftXY, confidence] = estimateDrift(app.Data.baitImg, ...
            app.Data.preyInfo(preyIdx).img, mask, 'crosscorr');
        
        app.Data.preyInfo(preyIdx).drift = driftXY;
        
        % Update UI elements
        driftLbl = findobj(groot, 'Tag', sprintf('driftLbl_%d', preyIdx));
        if ~isempty(driftLbl)
            driftLbl.Text = sprintf('Drift: [%.2f, %.2f] px (Conf: %.3f)', ...
                driftXY(1), driftXY(2), confidence);
        end
        
        % Update edit fields
        dxEdit = findobj(groot, 'Tag', sprintf('dxEdit_%d', preyIdx));
        dyEdit = findobj(groot, 'Tag', sprintf('dyEdit_%d', preyIdx));
        if ~isempty(dxEdit)
            dxEdit.Value = driftXY(1);
        end
        if ~isempty(dyEdit)
            dyEdit.Value = driftXY(2);
        end
        
        previewAlignmentCallback(app, preyIdx);
        
    catch ME
        uialert(app.Fig, sprintf('Auto-alignment error: %s', ME.message), 'Error');
    end
end

function manualAlignCallback(app, preyIdx)
    % Just show a message - manual input is already available in the main dialog
    uialert(app.Fig, sprintf(['Manual drift editing enabled.\n\n' ...
        'Current drift: [%.2f, %.2f] px\n\n' ...
        'Use the dx/dy input fields in the dialog for live adjustment.'], ...
        app.Data.preyInfo(preyIdx).drift(1), ...
        app.Data.preyInfo(preyIdx).drift(2)), ...
        'Manual Mode', 'Icon', 'info');
end

function previewAlignmentCallback(app, preyIdx)
    try
        % Get drift
        drift = app.Data.preyInfo(preyIdx).drift;
        
        % Normalize images
        baitImg = mat2gray(double(app.Data.baitImg));
        preyImg = mat2gray(double(app.Data.preyInfo(preyIdx).img));
        
        % Apply drift correction to prey image
        preyShifted = imtranslate(preyImg, -drift, 'FillValues', 0);
        
        % Create RGB overlay (Bait=Red, Prey=Green)
        overlayImg = zeros([size(baitImg), 3]);
        overlayImg(:,:,1) = baitImg;        % Bait in red
        overlayImg(:,:,2) = preyShifted;    % Prey (shifted) in green
        
        % Display
        displayImageCentered(app.ImageAxes, overlayImg, ...
            sprintf('Alignment: %s | Drift: [%.2f, %.2f] px', ...
            app.Data.preyInfo(preyIdx).name, drift(1), drift(2)));
        
    catch ME
        % Silent error handling
    end
end
