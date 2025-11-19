function step7_Export(app)
if ~isfield(app.Data, 'baitResults')
    uialert(app.Fig, 'No results to export. Run analysis first.', 'No Data');
    return;
end

% Clear parameter panel
delete(app.ParamPanel.Children);

% Create export options panel
gridLayout = uigridlayout(app.ParamPanel, [5, 1]);
gridLayout.RowHeight = {50, 70, 70, '1x', 70};
gridLayout.RowSpacing = 15;
gridLayout.Padding = [15 15 15 15];

% Header
lbl1 = uilabel(gridLayout);
lbl1.Text = 'Export Results';
lbl1.FontWeight = 'bold';
lbl1.FontSize = 15;
lbl1.Layout.Row = 1;
lbl1.HorizontalAlignment = 'center';
lbl1.FontColor = [0.2 0.5 0.9];

% Export button
btn1 = uibutton(gridLayout, 'push');
btn1.Text = '📊 Save Results to Excel';
btn1.ButtonPushedFcn = @saveResults;
btn1.Layout.Row = 2;
btn1.BackgroundColor = [0.2, 0.7, 0.3];
btn1.FontWeight = 'bold';
btn1.FontColor = [1 1 1];
btn1.FontSize = 13;

% New analysis button
btn2 = uibutton(gridLayout, 'push');
btn2.Text = '🔄 Start New Analysis';
btn2.ButtonPushedFcn = @newAnalysis;
btn2.Layout.Row = 3;
btn2.FontSize = 12;

% Close button
btn3 = uibutton(gridLayout, 'push');
btn3.Text = '✖ Close Application';
btn3.ButtonPushedFcn = @(~,~)close(app.Fig);
btn3.Layout.Row = 5;
btn3.BackgroundColor = [0.8 0.3 0.3];
btn3.FontColor = [1 1 1];
btn3.FontSize = 12;

% Info label
infoLbl = uilabel(gridLayout);
infoLbl.Text = generateInfoText(app);
infoLbl.Layout.Row = 4;
infoLbl.HorizontalAlignment = 'center';
infoLbl.FontSize = 11;
infoLbl.FontColor = [0.3 0.3 0.3];
infoLbl.WordWrap = 'on';
infoLbl.VerticalAlignment = 'top';

% Display completion message in image panel
showCompletionMessage(app);

    function txt = generateInfoText(app)
        nDots = numel(app.Data.dots);
        nPrey = 0;
        if isfield(app.Data, 'preyInfo')
            nPrey = numel(app.Data.preyInfo);
        end
        
        txt = sprintf(['Analysis Complete!\n\n' ...
            '✓ %d dots analyzed\n' ...
            '✓ %d prey channel(s)\n\n' ...
            'Ready to export results'], nDots, nPrey);
    end

    function showCompletionMessage(app)
        % Clear ImageAxes completely
        delete(app.ImageAxes.Children);
        cla(app.ImageAxes, 'reset');
        axis(app.ImageAxes, 'off');
        set(app.ImageAxes, 'Visible', 'off');
        app.ImageAxes.Color = [1 1 1];
        app.ImageAxes.XColor = 'none';
        app.ImageAxes.YColor = 'none';
        app.ImageAxes.Box = 'off';
        
        % Set limits
        xlim(app.ImageAxes, [0 1]);
        ylim(app.ImageAxes, [0 1]);
        
        % Generate summary statistics
        summaryText = generateSummaryText(app);
        
        % Display centered text
        text(app.ImageAxes, 0.5, 0.5, summaryText, ...
            'FontSize', 13, ...
            'VerticalAlignment', 'middle', ...
            'HorizontalAlignment', 'center', ...
            'FontWeight', 'bold', ...
            'Color', [0.2 0.7 0.3]);
        
        title(app.ImageAxes, 'Analysis Complete - Ready to Export', ...
            'FontSize', 15, 'FontWeight', 'bold');
    end

    function txt = generateSummaryText(app)
        txt = sprintf('✓ Analysis Complete!\n\n');
        txt = [txt sprintf('Dots analyzed: %d\n\n', numel(app.Data.dots))];
        txt = [txt sprintf('Bait Mean K: %.3f ± %.3f\n', ...
            mean(app.Data.baitResults.K), std(app.Data.baitResults.K))];
        
        if isfield(app.Data, 'preyResults') && ~isempty(app.Data.preyResults)
            channels = unique(app.Data.preyResults.channel);
            for i = 1:numel(channels)
                ch = channels(i);
                preyK = app.Data.preyResults.K(app.Data.preyResults.channel == ch);
                txt = [txt sprintf('%s Mean K: %.3f ± %.3f\n', ...
                    char(ch), mean(preyK), std(preyK))];
            end
        end
        
        txt = [txt sprintf('\n\nClick "Save Results to Excel" to export')];
    end

    function saveResults(~, ~)
        outputDir = uigetdir(pwd, 'Select Output Directory');
        if outputDir == 0, return; end
        
        timestamp = datestr(now, 'yyyy-mm-dd_HHMMSS');
        resultsDir = fullfile(outputDir, ['SpotAnalyzer_', timestamp]);
        
        try
            mkdir(resultsDir);
            
            % Call export function
            exportToExcel(app, resultsDir);
            
            uialert(app.Fig, sprintf('Results saved to:\n%s', resultsDir), ...
                'Export Complete', 'Icon', 'success');
            
        catch ME
            uialert(app.Fig, sprintf('Export error: %s\n%s', ME.message, ME.stack(1).name), 'Error');
        end
    end

    function newAnalysis(~, ~)
        answer = uiconfirm(app.Fig, 'Start a new analysis? Current data will be cleared.', ...
            'New Analysis', 'Options', {'Yes', 'No'}, 'DefaultOption', 2);
        
        if strcmp(answer, 'Yes')
            % Clear ImageAxes completely
            delete(app.ImageAxes.Children);
            cla(app.ImageAxes, 'reset');
            
            % Reset data
            app.Data = struct();
            app.CurrentStep = 1;
            updateStepButtons(app);
            executeStep(app, 1);
        end
    end
end

function exportToExcel(app, resultsDir)
% exportToExcel Export analysis results to Excel with specific structure
%
% Excel Structure:
% Sheet 1: Summary - Global statistics for whole image including bait_specific_contrast
% Sheet 2: Bait - Individual dot results
% Sheet 3+: PreyX - Individual dot results per prey channel
% Additional sheets: Bait_Specific_Contrast, Bait_Prey_Stats, Bait_Prey_DotResults

xlsFile = fullfile(resultsDir, 'SpotAnalyzer_Results.xlsx');
offset = app.Params.offset;

%% SHEET 1: Summary - WHOLE IMAGE STATISTICS
summaryTable = table();

% Bait summary for whole image
baitSummary = table();
baitSummary.channel = "bait";
baitSummary.GroupCount = height(app.Data.baitResults);
baitSummary.I_dot_mean = mean(app.Data.baitResults.I_dot);
baitSummary.I_dot_std = std(app.Data.baitResults.I_dot);
baitSummary.I_bg_mean = mean(app.Data.baitResults.I_bg);
baitSummary.I_bg_std = std(app.Data.baitResults.I_bg);
baitSummary.K_mean = mean(app.Data.baitResults.K);
baitSummary.K_std = std(app.Data.baitResults.K);

% CRITICAL FIX: Add empty contrast columns to bait (only if prey exists)
% This ensures bait and prey rows have same number of columns for vertcat
if isfield(app.Data, 'preyResults') && ~isempty(app.Data.preyResults)
    baitSummary.C_bait_norm_mean = NaN;
    baitSummary.C_bait_norm_std = NaN;
    baitSummary.C_prey_spec_mean = NaN;
    baitSummary.C_prey_spec_std = NaN;
end

summaryTable = [summaryTable; baitSummary];

% Prey summaries for whole image
if isfield(app.Data, 'preyResults') && ~isempty(app.Data.preyResults)
    preyChannels = unique(app.Data.preyResults.channel);
    
    % Calculate bait-specific contrast for whole image FIRST
    roiMask = [];
    if isfield(app.Data, 'roiMask')
        roiMask = app.Data.roiMask;
    end
    
    baitSpecResults = calculateBaitSpecificContrast( ...
        app.Data.baitResults, app.Data.preyResults, app.Data.dots, roiMask);
    
    % Store for later sheets
    app.Data.baitSpecResults = baitSpecResults;
    
    for i = 1:numel(preyChannels)
        ch = preyChannels(i);
        preyData = app.Data.preyResults(app.Data.preyResults.channel == ch, :);
        
        preySummary = table();
        preySummary.channel = ch;
        preySummary.GroupCount = height(preyData);
        preySummary.I_dot_mean = mean(preyData.I_dot);
        preySummary.I_dot_std = std(preyData.I_dot);
        preySummary.I_bg_mean = mean(preyData.I_bg);
        preySummary.I_bg_std = std(preyData.I_bg);
        preySummary.K_mean = mean(preyData.K);
        preySummary.K_std = std(preyData.K);
        
        % Add bait-specific contrast for THIS prey channel
        chData = baitSpecResults(baitSpecResults.channel == ch, :);
        preySummary.C_bait_norm_mean = mean(chData.C_bait_norm, 'omitnan');
        preySummary.C_bait_norm_std = std(chData.C_bait_norm, 'omitnan');
        preySummary.C_prey_spec_mean = mean(chData.C_prey_spec, 'omitnan');
        preySummary.C_prey_spec_std = std(chData.C_prey_spec, 'omitnan');
        
        summaryTable = [summaryTable; preySummary];
    end
end

writetable(summaryTable, xlsFile, 'Sheet', 'Summary');

%% SHEET 2: Bait - Individual dot results
baitData = app.Data.baitResults;
baitData.I_dot_corr = baitData.I_dot - offset;
baitData.I_bg_corr = baitData.I_bg - offset;
writetable(baitData, xlsFile, 'Sheet', 'Bait');

%% SHEET 3+: PreyX - Individual dot results per prey channel
sheetNum = 3;
if isfield(app.Data, 'preyResults') && ~isempty(app.Data.preyResults)
    preyChannels = unique(app.Data.preyResults.channel);
    for i = 1:numel(preyChannels)
        ch = preyChannels(i);
        preyData = app.Data.preyResults(app.Data.preyResults.channel == ch, :);
        preyData.I_dot_corr = preyData.I_dot - offset;
        preyData.I_bg_corr = preyData.I_bg - offset;
        
        sheetName = char(ch);
        writetable(preyData, xlsFile, 'Sheet', sheetName);
        sheetNum = sheetNum + 1;
    end
end

%% Additional Sheets (if prey exists)
if isfield(app.Data, 'preyResults') && ~isempty(app.Data.preyResults)
    if isfield(app.Data, 'baitSpecResults')
        writetable(app.Data.baitSpecResults, xlsFile, 'Sheet', 'Bait_Specific_Contrast');
        sheetNum = sheetNum + 1;
    end
    
    baitPreyAnalysis = calculateBaitPreyMetrics(app);
    writetable(baitPreyAnalysis.stats, xlsFile, 'Sheet', 'Bait_Prey_Stats');
    sheetNum = sheetNum + 1;
    
    writetable(baitPreyAnalysis.dotResults, xlsFile, 'Sheet', 'Bait_Prey_DotResults');
    sheetNum = sheetNum + 1;
end

%% Export Parameters
paramsFile = fullfile(resultsDir, 'analysis_parameters.txt');
fid = fopen(paramsFile, 'w');
fprintf(fid, 'SpotAnalyzer Analysis Parameters\n');
fprintf(fid, '================================\n\n');
fprintf(fid, 'Date: %s\n', datestr(now));
fprintf(fid, 'Pixel Size: %.2f nm/px\n', app.Params.pixelSize);
fprintf(fid, 'Offset: %.2f\n', app.Params.offset);
fprintf(fid, '\nDetection Parameters:\n');
fprintf(fid, '  Sigma: %.2f px\n', app.Params.sigma);
fprintf(fid, '  Threshold: %.2f\n', app.Params.threshold);
fprintf(fid, '\nRing Parameters:\n');
fprintf(fid, '  Gap: %.2f px\n', app.Params.gap);
fprintf(fid, '  Width: %.2f px\n', app.Params.width);
fprintf(fid, '\nFiltering Parameters:\n');
fprintf(fid, '  Min Mean I: %.2f\n', app.Params.minMeanI);
fprintf(fid, '  Min Area: %.2f px^2\n', app.Params.minArea);
fprintf(fid, '  Min Roundness: %.2f\n', app.Params.minRound);
fprintf(fid, '  Max Roundness: %.2f\n', app.Params.maxRound);
fprintf(fid, '  Min Center Distance: %.2f px\n', app.Params.minCenterDist);
fclose(fid);

Data = app.Data;
Params = app.Params;
save(fullfile(resultsDir, 'SpotAnalyzer_Data.mat'), 'Data', 'Params');
end

function bpAnalysis = calculateBaitPreyMetrics(app)
% Calculate bait-prey recruitment metrics

baitK = app.Data.baitResults.K;
baitI = app.Data.baitResults.I_dot;

preyChannels = unique(app.Data.preyResults.channel);

statsTable = table();
dotResultsTable = table();

for i = 1:numel(preyChannels)
    ch = preyChannels(i);
    preyData = app.Data.preyResults(app.Data.preyResults.channel == ch, :);
    
    RR_I = preyData.I_dot ./ baitI;
    RR_K = preyData.K ./ baitK;
    RR_Z = (RR_K - mean(RR_K, 'omitnan')) / std(RR_K, 'omitnan');
    
    rho = corr(preyData.I_dot, baitI, 'Rows', 'pairwise');
    
    statsRow = table(ch, rho, mean(RR_I, 'omitnan'), std(RR_I, 'omitnan'), ...
        mean(RR_K, 'omitnan'), std(RR_K, 'omitnan'), ...
        'VariableNames', {'channel', 'Pearson', 'RR_I_mean', 'RR_I_std', ...
        'RR_K_mean', 'RR_K_std'});
    statsTable = [statsTable; statsRow];
    
    dotRows = table(app.Data.baitResults.dotID, repmat(ch, height(preyData), 1), ...
        RR_I, RR_K, RR_Z, repmat(rho, height(preyData), 1), ...
        'VariableNames', {'dotID', 'channel', 'RR_I', 'RR_K', 'RR_Z', 'Pearson'});
    dotResultsTable = [dotResultsTable; dotRows];
end

bpAnalysis.stats = statsTable;
bpAnalysis.dotResults = dotResultsTable;
end