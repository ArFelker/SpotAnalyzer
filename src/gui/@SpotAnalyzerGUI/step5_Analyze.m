function step5_Analyze(app)
if ~isfield(app.Data, 'dots') || isempty(app.Data.dots)
    uialert(app.Fig, 'Please complete previous steps first.', 'No Data');
    return;
end

% Create simple info panel
grid = uigridlayout(app.ParamPanel, [4, 1]);
grid.RowHeight = {60, 60, '1x', 60};
grid.RowSpacing = 15;
grid.Padding = [15 15 15 15];

% Info labels
lbl1 = uilabel(grid);
lbl1.Text = 'Running comprehensive analysis...';
lbl1.Layout.Row = 1;
lbl1.FontSize = 14;
lbl1.FontWeight = 'bold';
lbl1.HorizontalAlignment = 'center';
lbl1.FontColor = [0.2 0.5 0.9];

progressLbl = uilabel(grid);
progressLbl.Text = 'Initializing...';
progressLbl.Layout.Row = 2;
progressLbl.FontSize = 12;
progressLbl.HorizontalAlignment = 'center';
progressLbl.FontColor = [0.4 0.4 0.4];

% Run analysis button
runBtn = uibutton(grid, 'push');
runBtn.Text = 'Start Analysis';
runBtn.Layout.Row = 4;
runBtn.ButtonPushedFcn = @runAnalysis;
runBtn.BackgroundColor = [0.2, 0.7, 0.3];
runBtn.FontWeight = 'bold';
runBtn.FontColor = [1 1 1];
runBtn.FontSize = 14;

% Auto-run if not already done
if ~isfield(app.Data, 'baitResults')
    pause(0.1);
    drawnow;
    runAnalysis();
end

    function runAnalysis(~, ~)
        try
            % Step 1: Background calculation
            progressLbl.Text = '1/3: Calculating background...';
            drawnow;
            
            calculateBackgroundStep(app);
            
            % Step 2: Quantify bait
            progressLbl.Text = '2/3: Quantifying bait channel...';
            drawnow;
            
            quantifyBaitStep(app);
            
            % Step 3: Analyze prey (if exists)
            if isfield(app.Data, 'preyInfo') && ~isempty(app.Data.preyInfo) && ...
                    ~isempty(app.Data.preyInfo(1).path)
                
                progressLbl.Text = '3/3: Analyzing prey channels...';
                drawnow;
                
                analyzePreyStep(app);
            else
                progressLbl.Text = '3/3: No prey channels (skipped)';
                drawnow;
            end
            
            % Done
            progressLbl.Text = '✓ Analysis complete!';
            progressLbl.FontColor = [0.2 0.7 0.3];
            progressLbl.FontWeight = 'bold';
            
            runBtn.Text = 'Analysis Complete ✓';
            runBtn.Enable = 'off';
            runBtn.BackgroundColor = [0.7 0.9 0.7];
            
            showCompletionMessage(app);
            
        catch ME
            uialert(app.Fig, sprintf('Analysis error: %s', ME.message), 'Error');
            progressLbl.Text = sprintf('Error: %s', ME.message);
            progressLbl.FontColor = [0.8 0.2 0.2];
        end
    end

    function calculateBackgroundStep(app)
        % Calculate background for all dots
        imgBait = double(app.Data.baitImg);
        
        for k = 1:numel(app.Data.dots)
            if isfield(app.Data.dots(k), 'bgMask') && ~isempty(app.Data.dots(k).bgMask)
                bgPixels = imgBait(app.Data.dots(k).bgMask);
                app.Data.dots(k).I_bg = mean(bgPixels);
            else
                app.Data.dots(k).I_bg = 0;
            end
        end
    end

    function quantifyBaitStep(app)
        % Quantify bait signals
        % CRITICAL: quantifySignals expects (img, dots, offset, channelName, driftXY)
        offset = app.Params.offset;  % Extract scalar offset!
        
        app.Data.baitResults = quantifySignals(app.Data.baitImg, ...
            app.Data.dots, offset, 'bait', [0, 0]);
    end

    function analyzePreyStep(app)
        % Analyze all prey channels with drift correction
        preyResults = table();
        
        for i = 1:numel(app.Data.preyInfo)
            if isempty(app.Data.preyInfo(i).img)
                continue;
            end
            
            % Use drift from Step 1 if available, otherwise calculate
            if isfield(app.Data.preyInfo(i), 'drift') && ...
                    ~isempty(app.Data.preyInfo(i).drift) && ...
                    any(app.Data.preyInfo(i).drift ~= 0)
                drift = app.Data.preyInfo(i).drift;
            else
                mask = [];
                if isfield(app.Data, 'roiMask')
                    mask = app.Data.roiMask;
                end
                
                [driftXY, confidence] = estimateDrift(app.Data.baitImg, ...
                    app.Data.preyInfo(i).img, mask, 'crosscorr');
                
                drift = driftXY;
                app.Data.preyInfo(i).drift = drift;
            end
            
            % Ensure drift is a 1x2 numeric array
            if ~isnumeric(drift) || numel(drift) ~= 2
                error('Drift must be a 1x2 numeric array, got: %s with %d elements', ...
                    class(drift), numel(drift));
            end
            drift = reshape(drift, 1, 2);  % Ensure row vector [dx, dy]
            
            % Quantify prey directly with drift correction
            % quantifySignals will handle the drift correction internally
            offset = app.Params.offset;  % Extract scalar offset!
            
            preyRes = quantifySignals(app.Data.preyInfo(i).img, ...
                app.Data.dots, offset, app.Data.preyInfo(i).name, drift);
            
            preyResults = [preyResults; preyRes];
        end
        
        app.Data.preyResults = preyResults;
    end

    function showCompletionMessage(app)
        % Display completion message instead of heatmap
        cla(app.ImageAxes);
        axis(app.ImageAxes, 'off');
        
        % Create success message
        text(app.ImageAxes, 0.5, 0.5, ...
            {'✓ Analysis Complete!', '', ...
            sprintf('Analyzed %d dots', numel(app.Data.dots)), ...
            '', ...
            'Go to Step 6 (Visualize) to view results'}, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 16, ...
            'FontWeight', 'bold', ...
            'Color', [0.2 0.7 0.3]);
        
        xlim(app.ImageAxes, [0 1]);
        ylim(app.ImageAxes, [0 1]);
    end
end
