function dataExport(resultsDir, analysisData, params)
% exportResults Export analysis results to structured Excel files
%
% INPUTS:
%   resultsDir   - Output directory
%   analysisData - Structure containing all results
%   params       - Analysis parameters

if ~isfolder(resultsDir), mkdir(resultsDir); end

xlsFile = fullfile(resultsDir, 'SpotAnalyzer_Results.xlsx');
offset = params.offset;

if isfield(analysisData, 'baitResults')
    baitData = analysisData.baitResults;
    baitData.I_dot_corr = baitData.I_dot - offset;
    baitData.I_bg_corr = baitData.I_bg - offset;
    writetable(baitData, xlsFile, 'Sheet', 'Bait');
end

if isfield(analysisData, 'preyResults')
    preyChannels = unique(analysisData.preyResults.channel);
    for i = 1:numel(preyChannels)
        ch = preyChannels(i);
        data = analysisData.preyResults(analysisData.preyResults.channel == ch, :);
        data.I_dot_corr = data.I_dot - offset;
        data.I_bg_corr = data.I_bg - offset;
        writetable(data, xlsFile, 'Sheet', char(ch));
    end
end

if isfield(analysisData, 'baitSpecResults')
    writetable(analysisData.baitSpecResults, xlsFile, ...
        'Sheet', 'Bait_Specific_Contrast');
end

if isfield(analysisData, 'baitPreyAnalysis')
    writetable(analysisData.baitPreyAnalysis.stats, xlsFile, ...
        'Sheet', 'Bait_Prey_Stats');
    writetable(analysisData.baitPreyAnalysis.dotResults, xlsFile, ...
        'Sheet', 'Bait_Prey_DotResults');
end

if isfield(analysisData, 'globalStats')
    writetable(analysisData.globalStats, xlsFile, 'Sheet', 'Summary');
end

paramsFile = fullfile(resultsDir, 'analysis_parameters.txt');
fid = fopen(paramsFile, 'w');
fprintf(fid, 'SpotAnalyzer Analysis Parameters\n');
fprintf(fid, '================================\n\n');
fprintf(fid, 'Date: %s\n', datestr(now));
fprintf(fid, 'Pixel Size: %.2f nm/px\n', params.pixelSize);
fprintf(fid, 'Offset: %.2f\n', params.offset);
fprintf(fid, '\nDetection Parameters:\n');
fprintf(fid, '  Sigma: %.2f px\n', params.sigma);
fprintf(fid, '  Threshold: %.2f\n', params.threshold);
fprintf(fid, '\nRing Parameters:\n');
fprintf(fid, '  Gap: %.2f px\n', params.gap);
fprintf(fid, '  Width: %.2f px\n', params.width);
if isfield(params, 'minMeanI')
    fprintf(fid, '\nFiltering Parameters:\n');
    fprintf(fid, '  Min Mean I: %.2f\n', params.minMeanI);
    fprintf(fid, '  Min Area: %.2f px^2\n', params.minArea);
    fprintf(fid, '  Min Roundness: %.2f\n', params.minRound);
    fprintf(fid, '  Max Roundness: %.2f\n', params.maxRound);
    fprintf(fid, '  Min Center Distance: %.2f px\n', params.minCenterDist);
end
fclose(fid);

save(fullfile(resultsDir, 'SpotAnalyzer_Data.mat'), 'analysisData', 'params');
end

function exportBatchSummary(outputDir, batchResults)
% exportBatchSummary Export summary of batch analysis
%
% INPUTS:
%   outputDir    - Output directory
%   batchResults - Cell array of analysis results

if ~isfolder(outputDir), mkdir(outputDir); end

nFiles = numel(batchResults);
summaryTable = table();

for i = 1:nFiles
    res = batchResults{i};
    if isempty(res), continue; end
    
    row = table();
    row.FileName = string(res.fileName);
    row.NumDots = res.numDots;
    row.MeanK_Bait = mean(res.baitResults.K, 'omitnan');
    row.StdK_Bait = std(res.baitResults.K, 'omitnan');
    
    if isfield(res, 'preyResults') && ~isempty(res.preyResults)
        preyChannels = unique(res.preyResults.channel);
        for j = 1:numel(preyChannels)
            ch = preyChannels(j);
            preyK = res.preyResults.K(res.preyResults.channel == ch);
            varName = sprintf('MeanK_%s', matlab.lang.makeValidName(char(ch)));
            row.(varName) = mean(preyK, 'omitnan');
        end
    end
    
    summaryTable = [summaryTable; row];
end

writetable(summaryTable, fullfile(outputDir, 'Batch_Summary.xlsx'));
end
