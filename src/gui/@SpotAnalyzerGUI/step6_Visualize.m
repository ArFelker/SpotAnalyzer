function step6_Visualize(app)
if ~isfield(app.Data, 'baitResults')
    uialert(app.Fig, 'No results to visualize. Run analysis first.', 'No Data');
    return;
end

% Clear parameter panel completely
delete(app.ParamPanel.Children);

% Create button grid in right panel for plot selection
gridLayout = uigridlayout(app.ParamPanel, [6, 1]);
gridLayout.RowHeight = {50, 50, 50, 50, 50, '1x'};
gridLayout.RowSpacing = 10;
gridLayout.Padding = [15 15 15 15];

% Title
lbl = uilabel(gridLayout);
lbl.Text = 'Select Plot Type:';
lbl.Layout.Row = 1;
lbl.FontSize = 14;
lbl.FontWeight = 'bold';
lbl.HorizontalAlignment = 'center';

% Button 1: Histograms
btn1 = uibutton(gridLayout, 'push');
btn1.Text = '📊 Histograms';
btn1.Layout.Row = 2;
btn1.ButtonPushedFcn = @(~,~) showHistograms();
btn1.BackgroundColor = [0.2 0.5 0.9];
btn1.FontColor = [1 1 1];
btn1.FontWeight = 'bold';
btn1.FontSize = 12;

% Button 2: ECDF
btn2 = uibutton(gridLayout, 'push');
btn2.Text = '📈 ECDF';
btn2.Layout.Row = 3;
btn2.ButtonPushedFcn = @(~,~) showECDF();
btn2.BackgroundColor = [0.3 0.6 0.8];
btn2.FontColor = [1 1 1];
btn2.FontWeight = 'bold';
btn2.FontSize = 12;

% Button 3: Bait-Prey
if isfield(app.Data, 'preyResults') && ~isempty(app.Data.preyResults)
    btn3 = uibutton(gridLayout, 'push');
    btn3.Text = '🔗 Bait-Prey';
    btn3.Layout.Row = 4;
    btn3.ButtonPushedFcn = @(~,~) showBaitPrey();
    btn3.BackgroundColor = [0.3 0.7 0.5];
    btn3.FontColor = [1 1 1];
    btn3.FontWeight = 'bold';
    btn3.FontSize = 12;
else
    btn3 = uibutton(gridLayout, 'push');
    btn3.Text = '🔗 Bait-Prey (N/A)';
    btn3.Layout.Row = 4;
    btn3.Enable = 'off';
    btn3.BackgroundColor = [0.8 0.8 0.8];
    btn3.FontSize = 12;
end

% Button 4: Statistics
btn4 = uibutton(gridLayout, 'push');
btn4.Text = '📋 Statistics';
btn4.Layout.Row = 5;
btn4.ButtonPushedFcn = @(~,~) showStatistics();
btn4.BackgroundColor = [0.6 0.4 0.7];
btn4.FontColor = [1 1 1];
btn4.FontWeight = 'bold';
btn4.FontSize = 12;

% Info
infoLbl = uilabel(gridLayout);
infoLbl.Text = '💡 Click buttons to view different visualizations in the main panel.';
infoLbl.Layout.Row = 6;
infoLbl.FontColor = [0.3 0.5 0.7];
infoLbl.FontSize = 10;
infoLbl.WordWrap = 'on';
infoLbl.VerticalAlignment = 'top';

% Show histograms by default
showHistograms();

    function showHistograms()
        % Clear everything in ImageAxes
        delete(app.ImageAxes.Children);
        cla(app.ImageAxes, 'reset');
        
        % Create temporary figure for plotting
        tempFig = figure('Visible', 'off', 'Position', [100 100 1200 800]);
        
        % Determine layout
        hasPrey = isfield(app.Data, 'preyResults') && ~isempty(app.Data.preyResults);
        
        if hasPrey
            % 2x2 layout
            t = tiledlayout(tempFig, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
            
            % Plot 1: Bait K
            nexttile(t);
            histogram(app.Data.baitResults.K, 30, 'FaceColor', [0.2 0.5 0.9], 'EdgeColor', 'k', 'LineWidth', 0.5);
            xlabel('Bait K', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel('Count', 'FontSize', 12, 'FontWeight', 'bold');
            title('Bait K Distribution', 'FontSize', 13, 'FontWeight', 'bold');
            grid('on');
            box on;
            set(gca, 'LineWidth', 1.2, 'FontSize', 11);
            
            % Plot 2: Bait I_dot
            nexttile(t);
            histogram(app.Data.baitResults.I_dot, 30, 'FaceColor', [0.7 0.3 0.3], 'EdgeColor', 'k', 'LineWidth', 0.5);
            xlabel('Bait I_{dot}', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel('Count', 'FontSize', 12, 'FontWeight', 'bold');
            title('Bait Intensity Distribution', 'FontSize', 13, 'FontWeight', 'bold');
            grid('on');
            box on;
            set(gca, 'LineWidth', 1.2, 'FontSize', 11);
            
            % Plot 3: Prey K
            nexttile(t);
            channels = unique(app.Data.preyResults.channel);
            preyK = app.Data.preyResults.K(app.Data.preyResults.channel == channels(1));
            histogram(preyK, 30, 'FaceColor', [0.3 0.7 0.3], 'EdgeColor', 'k', 'LineWidth', 0.5);
            xlabel(sprintf('%s K', char(channels(1))), 'FontSize', 12, 'FontWeight', 'bold');
            ylabel('Count', 'FontSize', 12, 'FontWeight', 'bold');
            title(sprintf('%s K Distribution', char(channels(1))), 'FontSize', 13, 'FontWeight', 'bold');
            grid('on');
            box on;
            set(gca, 'LineWidth', 1.2, 'FontSize', 11);
            
            % Plot 4: Background
            nexttile(t);
            histogram(app.Data.baitResults.I_bg, 30, 'FaceColor', [0.5 0.5 0.5], 'EdgeColor', 'k', 'LineWidth', 0.5);
            xlabel('Background Intensity', 'FontSize', 12, 'FontWeight', 'bold');
            ylabel('Count', 'FontSize', 12, 'FontWeight', 'bold');
            title('Background Distribution', 'FontSize', 13, 'FontWeight', 'bold');
            grid('on');
            box on;
            set(gca, 'LineWidth', 1.2, 'FontSize', 11);
        else
            % 1x2 layout
            t = tiledlayout(tempFig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
            
            % Plot 1: Bait K
            nexttile(t);
            histogram(app.Data.baitResults.K, 30, 'FaceColor', [0.2 0.5 0.9], 'EdgeColor', 'k', 'LineWidth', 0.5);
            xlabel('Bait K', 'FontSize', 13, 'FontWeight', 'bold');
            ylabel('Count', 'FontSize', 13, 'FontWeight', 'bold');
            title('Bait K Distribution', 'FontSize', 14, 'FontWeight', 'bold');
            grid('on');
            box on;
            set(gca, 'LineWidth', 1.2, 'FontSize', 12);
            
            % Plot 2: Bait I_dot
            nexttile(t);
            histogram(app.Data.baitResults.I_dot, 30, 'FaceColor', [0.7 0.3 0.3], 'EdgeColor', 'k', 'LineWidth', 0.5);
            xlabel('Bait I_{dot}', 'FontSize', 13, 'FontWeight', 'bold');
            ylabel('Count', 'FontSize', 13, 'FontWeight', 'bold');
            title('Bait Intensity Distribution', 'FontSize', 14, 'FontWeight', 'bold');
            grid('on');
            box on;
            set(gca, 'LineWidth', 1.2, 'FontSize', 12);
        end
        
        % Capture figure as image
        drawnow;
        frame = getframe(tempFig);
        close(tempFig);
        
        % Display as image - clear first!
        cla(app.ImageAxes, 'reset');
        imagesc(app.ImageAxes, frame.cdata);
        axis(app.ImageAxes, 'off');
        axis(app.ImageAxes, 'image');
        title(app.ImageAxes, 'Histograms', 'FontSize', 14, 'FontWeight', 'bold');
    end

    function showECDF()
        % COMPLETE CLEAR and reset to normal plot mode
        delete(app.ImageAxes.Children);
        cla(app.ImageAxes, 'reset');
        
        % Set axes to NORMAL plot mode (not image mode)
        axis(app.ImageAxes, 'normal');
        set(app.ImageAxes, 'Visible', 'on');
        set(app.ImageAxes, 'XColor', [0 0 0], 'YColor', [0 0 0], 'ZColor', [0 0 0]);
        app.ImageAxes.Color = [1 1 1];  % White background
        
        % Bait ECDF
        [f, x] = ecdf(app.Data.baitResults.K);
        plot(app.ImageAxes, x, f, 'LineWidth', 3, 'DisplayName', 'Bait', ...
            'Color', [0.2 0.5 0.9], 'Marker', 'none');
        hold(app.ImageAxes, 'on');
        
        % Prey ECDF (if available)
        if isfield(app.Data, 'preyResults') && ~isempty(app.Data.preyResults)
            channels = unique(app.Data.preyResults.channel);
            colors = lines(numel(channels));
            
            for i = 1:numel(channels)
                ch = channels(i);
                preyK = app.Data.preyResults.K(app.Data.preyResults.channel == ch);
                [f, x] = ecdf(preyK);
                plot(app.ImageAxes, x, f, 'LineWidth', 3, 'DisplayName', char(ch), ...
                    'Color', colors(i,:), 'Marker', 'none');
            end
        end
        
        hold(app.ImageAxes, 'off');
        
        % Format axes for publication-quality scientific plot
        xlabel(app.ImageAxes, 'K-value', 'FontSize', 14, 'FontWeight', 'bold');
        ylabel(app.ImageAxes, 'Cumulative Probability', 'FontSize', 14, 'FontWeight', 'bold');
        title(app.ImageAxes, 'Empirical Cumulative Distribution Function', 'FontSize', 15, 'FontWeight', 'bold');
        
        % Legend with better styling
        lgd = legend(app.ImageAxes, 'Location', 'southeast', 'FontSize', 12);
        lgd.Box = 'on';
        lgd.LineWidth = 1.2;
        
        % Grid and box
        grid(app.ImageAxes, 'on');
        box(app.ImageAxes, 'on');
        
        % Scientific plot styling
        app.ImageAxes.FontSize = 12;
        app.ImageAxes.FontName = 'Arial';
        app.ImageAxes.LineWidth = 1.5;
        app.ImageAxes.TickDir = 'out';
        app.ImageAxes.TickLength = [0.02 0.02];
        app.ImageAxes.GridAlpha = 0.15;
        app.ImageAxes.GridLineStyle = '-';
        
        % Set limits explicitly
        xlim(app.ImageAxes, 'auto');
        ylim(app.ImageAxes, [0 1]);
    end

    function showBaitPrey()
        if ~isfield(app.Data, 'preyResults') || isempty(app.Data.preyResults)
            return;
        end
        
        % Clear completely
        delete(app.ImageAxes.Children);
        cla(app.ImageAxes, 'reset');
        
        % Create temporary figure
        tempFig = figure('Visible', 'off', 'Position', [100 100 1200 800]);
        t = tiledlayout(tempFig, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
        
        baitK = app.Data.baitResults.K;
        channels = unique(app.Data.preyResults.channel);
        preyK = app.Data.preyResults.K(app.Data.preyResults.channel == channels(1));
        
        % 1. Bait vs Prey scatter
        nexttile(t);
        scatter(baitK, preyK, 50, 'filled', 'MarkerFaceAlpha', 0.6, ...
            'MarkerFaceColor', [0.3 0.6 0.8], 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
        xlabel('Bait K', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel(sprintf('%s K', char(channels(1))), 'FontSize', 12, 'FontWeight', 'bold');
        title('Bait vs Prey Correlation', 'FontSize', 13, 'FontWeight', 'bold');
        grid('on');
        box on;
        set(gca, 'LineWidth', 1.2, 'FontSize', 11);
        
        % 2. Recruitment Ratio
        nexttile(t);
        RR_K = preyK ./ baitK;
        histogram(RR_K, 30, 'FaceColor', [0.8 0.5 0.2], 'EdgeColor', 'k', 'LineWidth', 0.5);
        xlabel('Recruitment Ratio (K)', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel('Count', 'FontSize', 12, 'FontWeight', 'bold');
        title('Recruitment Ratio Distribution', 'FontSize', 13, 'FontWeight', 'bold');
        grid('on');
        box on;
        set(gca, 'LineWidth', 1.2, 'FontSize', 11);
        
        % 3. Bait vs Prey intensities
        nexttile(t);
        baitI = app.Data.baitResults.I_dot;
        preyI = app.Data.preyResults.I_dot(app.Data.preyResults.channel == channels(1));
        scatter(baitI, preyI, 50, 'filled', 'MarkerFaceAlpha', 0.6, ...
            'MarkerFaceColor', [0.6 0.3 0.7], 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
        xlabel('Bait I_{dot}', 'FontSize', 12, 'FontWeight', 'bold');
        ylabel(sprintf('%s I_{dot}', char(channels(1))), 'FontSize', 12, 'FontWeight', 'bold');
        title('Intensity Correlation', 'FontSize', 13, 'FontWeight', 'bold');
        grid('on');
        box on;
        set(gca, 'LineWidth', 1.2, 'FontSize', 11);
        
        % 4. RR statistics
        ax4 = nexttile(t);
        axis(ax4, 'off');
        
        statText = sprintf(['Recruitment Analysis\n\n' ...
            'Mean RR:   %.3f\n' ...
            'Median RR: %.3f\n' ...
            'Std RR:    %.3f\n\n' ...
            'Correlation:\n' ...
            'K:  %.3f\n' ...
            'I:  %.3f'], ...
            mean(RR_K), median(RR_K), std(RR_K), ...
            corr(baitK, preyK), corr(baitI, preyI));
        
        text(ax4, 0.1, 0.5, statText, 'FontSize', 14, 'FontWeight', 'bold', ...
            'VerticalAlignment', 'middle', 'Color', [0.2 0.2 0.2], ...
            'FontName', 'Courier');
        
        % Capture and display
        drawnow;
        frame = getframe(tempFig);
        close(tempFig);
        
        % Display
        cla(app.ImageAxes, 'reset');
        imagesc(app.ImageAxes, frame.cdata);
        axis(app.ImageAxes, 'off');
        axis(app.ImageAxes, 'image');
        title(app.ImageAxes, 'Bait-Prey Analysis', 'FontSize', 14, 'FontWeight', 'bold');
    end

    function showStatistics()
        % COMPLETE CLEAR - remove everything
        delete(app.ImageAxes.Children);
        cla(app.ImageAxes, 'reset');
        
        % Turn off axes completely - no box, no lines
        axis(app.ImageAxes, 'off');
        set(app.ImageAxes, 'Visible', 'off');
        app.ImageAxes.Color = [1 1 1];
        app.ImageAxes.XColor = 'none';
        app.ImageAxes.YColor = 'none';
        app.ImageAxes.ZColor = 'none';
        app.ImageAxes.Box = 'off';
        
        % Set fixed limits for consistent text positioning
        xlim(app.ImageAxes, [0 1]);
        ylim(app.ImageAxes, [0 1]);
        
        % Create text display
        statText = generateStatText();
        
        % Display CENTERED text with proper alignment
        text(app.ImageAxes, 0.5, 0.45, statText, ...
            'FontSize', 11, ...
            'VerticalAlignment', 'middle', ...
            'HorizontalAlignment', 'center', ...
            'FontName', 'FixedWidth', ...
            'Interpreter', 'none', ...
            'Color', [0.1 0.1 0.1]);
        
        % Add title at top
        text(app.ImageAxes, 0.5, 0.92, 'Analysis Statistics', ...
            'FontSize', 16, ...
            'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'top', ...
            'Color', [0.2 0.2 0.2]);
    end

    function txt = generateStatText()
        txt = sprintf('╔═══════════════════════════════════════╗\n');
        txt = [txt sprintf('║          BAIT STATISTICS              ║\n')];
        txt = [txt sprintf('╠═══════════════════════════════════════╣\n')];
        txt = [txt sprintf('║ Number of dots:      %6d          ║\n', height(app.Data.baitResults))];
        txt = [txt sprintf('║ Mean K:              %6.3f          ║\n', mean(app.Data.baitResults.K))];
        txt = [txt sprintf('║ Median K:            %6.3f          ║\n', median(app.Data.baitResults.K))];
        txt = [txt sprintf('║ Std K:               %6.3f          ║\n', std(app.Data.baitResults.K))];
        txt = [txt sprintf('║ Mean I_dot:          %6.1f          ║\n', mean(app.Data.baitResults.I_dot))];
        txt = [txt sprintf('║ Mean I_bg:           %6.1f          ║\n', mean(app.Data.baitResults.I_bg))];
        txt = [txt sprintf('║ Mean SNR:            %6.2f          ║\n', mean(app.Data.baitResults.SNR))];
        
        if isfield(app.Data, 'preyResults') && ~isempty(app.Data.preyResults)
            txt = [txt sprintf('╠═══════════════════════════════════════╣\n')];
            txt = [txt sprintf('║          PREY STATISTICS              ║\n')];
            txt = [txt sprintf('╠═══════════════════════════════════════╣\n')];
            
            channels = unique(app.Data.preyResults.channel);
            preyK = app.Data.preyResults.K(app.Data.preyResults.channel == channels(1));
            preyI = app.Data.preyResults.I_dot(app.Data.preyResults.channel == channels(1));
            
            txt = [txt sprintf('║ Channel:             %-6s          ║\n', char(channels(1)))];
            txt = [txt sprintf('║ Mean K:              %6.3f          ║\n', mean(preyK))];
            txt = [txt sprintf('║ Median K:            %6.3f          ║\n', median(preyK))];
            txt = [txt sprintf('║ Std K:               %6.3f          ║\n', std(preyK))];
            txt = [txt sprintf('║ Mean I_dot:          %6.1f          ║\n', mean(preyI))];
            
            baitK = app.Data.baitResults.K;
            RR = preyK ./ baitK;
            txt = [txt sprintf('║ Mean RR:             %6.3f          ║\n', mean(RR))];
            txt = [txt sprintf('║ Median RR:           %6.3f          ║\n', median(RR))];
        end
        
        txt = [txt sprintf('╚═══════════════════════════════════════╝')];
    end
end
