% ------------------------------------------------------------------------
% Step 1: Set directory paths
inputFolder  = '';    % Raw CSV data folder
tempFolder   = fullfile(inputFolder, 'temp_scr_only');                % Temporary folder for SCR data as txt
outputFolder = '';      % Output folder for PsPM .mat files

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end
if ~exist(tempFolder, 'dir')
    mkdir(tempFolder);
end

% ------------------------------------------------------------------------
% Step 2: Batch process all CSV files in input folder
fileList = dir(fullfile(inputFolder, '*.csv')); 
datatype = 'txt';  
options = struct();
options.overwrite = 1;

for i = 1:length(fileList)
    original_csv = fullfile(inputFolder, fileList(i).name);

    % Read CSV and extract 'EDA_Clean' column
    T = readtable(original_csv);
    if ~ismember('EDA_Clean', T.Properties.VariableNames)
        warning('EDA_Clean column not found in file: %s\n', fileList(i).name);
        continue;
    end
    scr_data = T.EDA_Clean;

    % Save SCR column as temporary txt file
    [~, baseName, ~] = fileparts(fileList(i).name);
    temp_txt_file = fullfile(tempFolder, [baseName, '.txt']);
    writematrix(scr_data, temp_txt_file);

    % Create import structure
    importStruct = struct();
    importStruct.type = 'scr';
    importStruct.sr = 2000;  % Sampling rate
    importStruct.channel = 1;
    importCell = {importStruct};

    % Import SCR data into PsPM format
    [sts, outfile] = pspm_import(temp_txt_file, datatype, importCell, options);

    % Move output file to final output folder
    if sts == 1
        [~, name, ext] = fileparts(outfile);
        movefile(outfile, fullfile(outputFolder, [name, ext]));
        fprintf('Successfully imported and saved: %s\n', fileList(i).name);
    else
        warning('Failed to import file: %s\n', fileList(i).name);
    end
end
