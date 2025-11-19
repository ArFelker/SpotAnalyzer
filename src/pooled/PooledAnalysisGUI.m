classdef PooledAnalysisGUI < handle
    % PooledAnalysisGUI Tool for pooled analysis of multiple SpotAnalyzer runs
    
    properties
        Fig
        FolderList
        SelectedFolders = {}
        AnalysisType
    end
    
    methods
        function app = PooledAnalysisGUI()
            createUI(app);
        end
        
        function createUI(app)
            app.Fig = uifigure('Name', 'Pooled Analysis', ...
                'Position', [200, 200, 800, 600]);
            
            grid = uigridlayout(app.Fig, [3, 1]);
            grid.RowHeight = {50, '1x', 100};
            
            topPanel = uipanel(grid, 'BorderType', 'none');
            topPanel.Layout.Row = 1;
            
            mainPanel = uipanel(grid, 'Title', 'Selected Folders');
            mainPanel.Layout.Row = 2;
            
            bottomPanel = uipanel(grid, 'BorderType', 'none');
            bottomPanel.Layout.Row = 3;
            
            createTopPanel(app, topPanel);
            createMainPanel(app, mainPanel);
            createBottomPanel(app, bottomPanel);
        end
        
        function createTopPanel(app, parent)
            grid = uigridlayout(parent, [1, 4]);
            grid.ColumnWidth = {150, 150, '1x', 150};
            
            btn1 = uibutton(grid, 'push');
            btn1.Text = 'Add Folder';
            btn1.ButtonPushedFcn = @(~,~)app.addFolder();
            btn1.Layout.Column = 1;
            
            btn2 = uibutton(grid, 'push');
            btn2.Text = 'Add Multiple';
            btn2.ButtonPushedFcn = @(~,~)app.addMultipleFolders();
            btn2.Layout.Column = 2;
            
            btn3 = uibutton(grid, 'push');
            btn3.Text = 'Clear All';
            btn3.ButtonPushedFcn = @(~,~)app.clearAll();
            btn3.Layout.Column = 4;
        end
        
        function createMainPanel(app, parent)
            app.FolderList = uilistbox(parent, 'Multiselect', 'on');
            app.FolderList.Position = [10, 10, parent.Position(3)-20, ...
                parent.Position(4)-40];
        end
        
        function createBottomPanel(app, parent)
            grid = uigridlayout(parent, [2, 2]);
            grid.RowHeight = {25, 40};
            grid.ColumnWidth = {'1x', '1x'};
            
            lbl1 = uilabel(grid);
            lbl1.Text = 'Analysis Type:';
            lbl1.Layout.Row = 1;
            lbl1.Layout.Column = 1;
            app.AnalysisType = uidropdown(grid, ...
                'Items', {'Merge All Excel Files', 'Group by Filename'}, ...
                'Value', 'Merge All Excel Files');
            app.AnalysisType.Layout.Row = 1;
            app.AnalysisType.Layout.Column = 2;
            
            btn1 = uibutton(grid, 'push');
            btn1.Text = 'Run Pooled Analysis';
            btn1.ButtonPushedFcn = @(~,~)app.runAnalysis();
            btn1.Layout.Row = 2;
            btn1.Layout.Column = 1;
            
            btn2 = uibutton(grid, 'push');
            btn2.Text = 'Close';
            btn2.ButtonPushedFcn = @(~,~)close(app.Fig);
            btn2.Layout.Row = 2;
            btn2.Layout.Column = 2;
        end
        
        function addFolder(app)
            folder = uigetdir(pwd, 'Select Analysis Folder');
            if folder ~= 0
                if ~any(strcmp(app.SelectedFolders, folder))
                    app.SelectedFolders{end+1} = folder;
                    app.updateList();
                end
            end
        end
        
        function addMultipleFolders(app)
            answer = inputdlg({'Enter folder paths (one per line):'}, ...
                'Add Multiple Folders', [15, 80]);
            
            if ~isempty(answer) && ~isempty(answer{1})
                % Use splitlines for robust newline handling
                paths = splitlines(answer{1});
                for i = 1:numel(paths)
                    folder = strtrim(paths{i});
                    if ~isempty(folder) && isfolder(folder)
                        if ~any(strcmp(app.SelectedFolders, folder))
                            app.SelectedFolders{end+1} = folder;
                        end
                    end
                end
                app.updateList();
            end
        end
        
        function clearAll(app)
            app.SelectedFolders = {};
            app.updateList();
        end
        
        function updateList(app)
            app.FolderList.Items = app.SelectedFolders;
        end
        
        function runAnalysis(app)
            if isempty(app.SelectedFolders)
                uialert(app.Fig, 'Please select folders first.', 'No Folders');
                return;
            end
            
            outputDir = uigetdir(pwd, 'Select Output Directory');
            if outputDir == 0, return; end
            
            timestamp = datestr(now, 'yyyy-mm-dd_HHMMSS');
            
            switch app.AnalysisType.Value
                case 'Merge All Excel Files'
                    mergeExcelFiles(app, outputDir, timestamp);
                case 'Group by Filename'
                    groupByFilename(app, outputDir, timestamp);
            end
        end
        
        function mergeExcelFiles(app, outputDir, timestamp)
            allFiles = findExcelFilesInFolders(app.SelectedFolders);
            
            if isempty(allFiles)
                uialert(app.Fig, 'No Excel files found.', 'No Data');
                return;
            end
            
            [selectedFiles, ok] = listdlg('PromptString', 'Select files to merge:', ...
                'ListString', allFiles, 'ListSize', [500, 400]);
            
            if ~ok || isempty(selectedFiles)
                return;
            end
            
            files = allFiles(selectedFiles);
            
            sheets = {};
            for i = 1:numel(files)
                try
                    s = sheetnames(files{i});
                    sheets = [sheets; s];
                catch
                end
            end
            sheets = unique(sheets);
            
            if isempty(sheets)
                uialert(app.Fig, 'No sheets found.', 'Error');
                return;
            end
            
            [selectedSheets, ok] = listdlg('PromptString', 'Select sheets to merge:', ...
                'ListString', sheets, 'ListSize', [400, 300]);
            
            if ~ok || isempty(selectedSheets)
                return;
            end
            
            sheetsToMerge = sheets(selectedSheets);
            
            outputFile = fullfile(outputDir, ['Pooled_Analysis_', timestamp, '.xlsx']);
            
            for s = 1:numel(sheetsToMerge)
                sheet = sheetsToMerge{s};
                mergedTable = table();
                
                for f = 1:numel(files)
                    try
                        T = readtable(files{f}, 'Sheet', sheet);
                        mergedTable = [mergedTable; T];
                    catch
                    end
                end
                
                if ~isempty(mergedTable)
                    writetable(mergedTable, outputFile, 'Sheet', sheet);
                end
            end
            
            uialert(app.Fig, sprintf('Merged data saved to:\n%s', outputFile), ...
                'Complete');
        end
        
        function groupByFilename(app, outputDir, timestamp)
            allFiles = findExcelFilesInFolders(app.SelectedFolders);
            
            if isempty(allFiles)
                uialert(app.Fig, 'No Excel files found.', 'No Data');
                return;
            end
            
            groupDir = fullfile(outputDir, ['Grouped_Analysis_', timestamp]);
            mkdir(groupDir);
            
            fileGroups = containers.Map();
            
            for i = 1:numel(allFiles)
                [~, name, ~] = fileparts(allFiles{i});
                
                if fileGroups.isKey(name)
                    fileGroups(name) = [fileGroups(name); {allFiles{i}}];
                else
                    fileGroups(name) = {allFiles{i}};
                end
            end
            
            groupNames = keys(fileGroups);
            
            for i = 1:numel(groupNames)
                groupName = groupNames{i};
                files = fileGroups(groupName);
                
                subDir = fullfile(groupDir, groupName);
                mkdir(subDir);
                
                for j = 1:numel(files)
                    [sourcePath, ~, ext] = fileparts(files{j});
                    [~, parentDir] = fileparts(sourcePath);
                    
                    destName = [groupName, '_', parentDir, ext];
                    copyfile(files{j}, fullfile(subDir, destName));
                end
            end
            
            uialert(app.Fig, sprintf('Files grouped and saved to:\n%s', groupDir), ...
                'Complete');
        end
    end
end

function excelFiles = findExcelFilesInFolders(folders)
excelFiles = {};
extensions = {'.xls', '.xlsx', '.xlsm'};

for i = 1:numel(folders)
    files = dir(fullfile(folders{i}, '**', '*.xls*'));
    
    for j = 1:numel(files)
        [~, ~, ext] = fileparts(files(j).name);
        if any(strcmpi(ext, extensions))
            excelFiles{end+1} = fullfile(files(j).folder, files(j).name);
        end
    end
end
end
