classdef SpotAnalyzerGUI < handle
    % SpotAnalyzerGUI Main GUI for SpotAnalyzer
    
    properties
        Fig
        CurrentStep = 1
        MaxSteps = 7  % Reduced from 9 (removed steps 5,6)
        
        Data = struct()
        Params = struct()
        
        MainPanel
        SidePanel
        ImagePanel
        ParamPanel
        
        ImageAxes
        StatusLabel
        StepButtons
        NextButton
        BackButton
        RunAllButton
    end
    
    methods
        function app = SpotAnalyzerGUI()
            try
                createUI(app);
                initializeDefaults(app);
            catch ME
                errordlg(sprintf('Error creating GUI: %s\n%s', ME.message, ME.stack(1).name));
                rethrow(ME);
            end
        end
        
        function createUI(app)
            app.Fig = uifigure('Name', 'SpotAnalyzer', ...
                'Position', [100, 100, 1400, 800], ...
                'CloseRequestFcn', @(~,~)app.closeApp());
            
            % Main grid: Workflow | Image Display | Parameters
            mainGrid = uigridlayout(app.Fig, [1, 3]);
            mainGrid.ColumnWidth = {220, '1x', 350};  % Workflow, Image (square), Parameters
            
            % Left: Workflow panel
            leftPanel = uipanel(mainGrid, 'Title', 'Workflow');
            leftPanel.Layout.Row = 1;
            leftPanel.Layout.Column = 1;
            
            % Middle: Image display (square)
            middlePanel = uipanel(mainGrid, 'Title', 'Image Display');
            middlePanel.Layout.Row = 1;
            middlePanel.Layout.Column = 2;
            
            % Right: Parameters panel
            rightPanel = uipanel(mainGrid, 'Title', 'Parameters');
            rightPanel.Layout.Row = 1;
            rightPanel.Layout.Column = 3;
            
            % Create sub-layouts
            createWorkflowPanel(app, leftPanel);
            createImagePanel(app, middlePanel);
            createParameterPanel(app, rightPanel);
        end
        
        function createWorkflowPanel(app, parent)
            g = uigridlayout(parent, [9, 1]);
            g.RowHeight = {40, 40, 40, 40, 40, 40, 40, '1x', 50};
            g.Padding = [5 5 5 5];
            g.RowSpacing = 5;
            
            stepNames = {'Load Images', 'Define ROI', 'Detect Dots', ...
                'Define Ring', 'Analyze', 'Visualize', 'Export'};
            
            app.StepButtons = gobjects(7, 1);
            
            for i = 1:7
                btn = uibutton(g, 'push');
                btn.Text = sprintf('%d. %s', i, stepNames{i});
                btn.ButtonPushedFcn = @(~,~)app.goToStep(i);
                btn.Layout.Row = i;
                btn.Layout.Column = 1;
                app.StepButtons(i) = btn;
            end
            
            % Status label
            app.StatusLabel = uilabel(g);
            app.StatusLabel.Text = 'Ready';
            app.StatusLabel.FontColor = [0.3 0.3 0.3];
            app.StatusLabel.HorizontalAlignment = 'center';
            app.StatusLabel.Layout.Row = 8;
            app.StatusLabel.Layout.Column = 1;
            
            % Navigation buttons
            navGrid = uigridlayout(g, [1, 2]);
            navGrid.Layout.Row = 9;
            navGrid.Layout.Column = 1;
            navGrid.ColumnWidth = {'1x', '1x'};
            navGrid.Padding = [0 0 0 0];
            
            app.BackButton = uibutton(navGrid, 'push');
            app.BackButton.Text = '◄ Back';
            app.BackButton.ButtonPushedFcn = @(~,~)app.previousStep();
            app.BackButton.Layout.Row = 1;
            app.BackButton.Layout.Column = 1;
            
            app.NextButton = uibutton(navGrid, 'push');
            app.NextButton.Text = 'Next ►';
            app.NextButton.ButtonPushedFcn = @(~,~)app.nextStep();
            app.NextButton.Layout.Row = 1;
            app.NextButton.Layout.Column = 2;
            
            updateStepButtons(app);
        end
        
        function createImagePanel(app, parent)
            % Create axes that fills the panel (square display)
            app.ImageAxes = uiaxes(parent);
            app.ImageAxes.Units = 'normalized';
            app.ImageAxes.Position = [0.01, 0.01, 0.98, 0.98];  % Fast vollflächig
            
            % Enable zoom and pan
            app.ImageAxes.Toolbar.Visible = 'on';
            
            % Set axis properties for full display
            axis(app.ImageAxes, 'image');  % Keep aspect ratio
            axis(app.ImageAxes, 'off');     % Hide ticks
            
            % Set background
            app.ImageAxes.Color = [0.94 0.94 0.94];
            
            % Initial message
            text(app.ImageAxes, 0.5, 0.5, 'Load images to begin', ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 14, 'Color', [0.5 0.5 0.5]);
            xlim(app.ImageAxes, [0 1]);
            ylim(app.ImageAxes, [0 1]);
        end
        
        function createParameterPanel(app, parent)
            % Scrollable parameter panel
            app.ParamPanel = uipanel(parent);
            app.ParamPanel.Position = [5, 5, parent.Position(3)-10, parent.Position(4)-10];
            app.ParamPanel.BorderType = 'none';
            app.ParamPanel.Scrollable = 'on';
        end
        
        function initializeDefaults(app)
            app.Params.pixelSize = 130;
            app.Params.offset = 400;
            app.Params.sigma = 1.75;
            app.Params.threshold = 1.0;
            app.Params.gap = 1.25;
            app.Params.width = 1.0;  % Fixed to 1 pixel
            app.Params.minMeanI = 0;
            app.Params.minArea = 10;
            app.Params.minRound = 0.6;
            app.Params.maxRound = 1.3;
            app.Params.minCenterDist = 0;
            
            goToStep(app, 1);
        end
        
        function goToStep(app, stepNum)
            app.CurrentStep = stepNum;
            updateStepButtons(app);
            updateStatus(app);
            executeStep(app, stepNum);
        end
        
        function nextStep(app)
            if app.CurrentStep < app.MaxSteps
                app.CurrentStep = app.CurrentStep + 1;
                updateStepButtons(app);
                updateStatus(app);
                executeStep(app, app.CurrentStep);
            end
        end
        
        function previousStep(app)
            if app.CurrentStep > 1
                app.CurrentStep = app.CurrentStep - 1;
                updateStepButtons(app);
                updateStatus(app);
                executeStep(app, app.CurrentStep);
            end
        end
        
        function updateStatus(app)
            stepNames = {'Loading...', 'Define ROI...', 'Detecting...', ...
                'Ring Analysis...', 'Analyzing...', 'Visualizing...', 'Exporting...'};
            app.StatusLabel.Text = stepNames{app.CurrentStep};
        end
        
        function executeStep(app, stepNum)
            clearParameterPanel(app);
            
            try
                switch stepNum
                    case 1, step1_LoadImages(app);
                    case 2, step2_DefineROI(app);
                    case 3, step3_DetectDots(app);
                    case 4, step4_DefineRing(app);
                    case 5, step5_Analyze(app);  % Combined analysis
                    case 6, step6_Visualize(app);
                    case 7, step7_Export(app);
                end
            catch ME
                uialert(app.Fig, sprintf('Error in Step %d: %s', stepNum, ME.message), ...
                    'Step Error');
                fprintf('ERROR in Step %d: %s\n', stepNum, ME.message);
                fprintf('Stack: %s\n', ME.stack(1).name);
            end
        end
        
        function updateStepButtons(app)
            for i = 1:7
                if i == app.CurrentStep
                    app.StepButtons(i).BackgroundColor = [0.2, 0.5, 0.9];
                    app.StepButtons(i).FontWeight = 'bold';
                    app.StepButtons(i).FontColor = [1 1 1];
                elseif i < app.CurrentStep
                    app.StepButtons(i).BackgroundColor = [0.7, 0.9, 0.7];
                    app.StepButtons(i).FontWeight = 'normal';
                    app.StepButtons(i).FontColor = [0 0 0];
                else
                    app.StepButtons(i).BackgroundColor = [0.96, 0.96, 0.96];
                    app.StepButtons(i).FontWeight = 'normal';
                    app.StepButtons(i).FontColor = [0 0 0];
                end
            end
            
            app.BackButton.Enable = app.CurrentStep > 1;
            app.NextButton.Enable = app.CurrentStep < app.MaxSteps;
        end
        
        function clearParameterPanel(app)
            delete(app.ParamPanel.Children);
        end
        
        function closeApp(app)
            delete(app.Fig);
        end
    end
    
    methods (Access = private)
        step1_LoadImages(app)
        step2_DefineROI(app)
        step3_DetectDots(app)
        step4_DefineRing(app)
        step5_Analyze(app)
        step6_Visualize(app)
        step7_Export(app)
    end
end
