%% Convert all available PEn data files
%% Set input and output paths
input_folder  = '';
output_folder = '';

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

%% Get all CSV files
csv_files = dir(fullfile(input_folder, '*_PEn.csv'));

for i = 1:length(csv_files)
    filename = csv_files(i).name;
    filepath = fullfile(input_folder, filename);

    % Read data from CSV file
    opts = detectImportOptions(filepath);
    opts.VariableNamingRule = 'preserve';
    data = readtable(filepath, opts);

    % Rename columns (if needed)
    data.Properties.VariableNames = {'trial_start', 'trial_stopp', 'PEn_start', 'PEn_duration', 'alpha_n'};

    % Create event structure for negative prediction error events (PEn)
    PEn_events = struct( ...
        'onset',    num2cell(data.PEn_start), ...
        'duration', num2cell(data.PEn_duration), ...
        'type',     repmat({'PEn'}, height(data), 1), ...
        'value',    num2cell(data.alpha_n) ...
    );

    % Save result using cleaned filename as prefix
    [~, name, ~] = fileparts(filename);
    short_name = erase(name, '_PEn');
    save(fullfile(output_folder, [short_name '_PEn_events.mat']), 'PEn_events');
end

disp('All PEn data files have been successfully converted and saved.');
