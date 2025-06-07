%% Convert all available data files
%% Set input and output paths
input_folder  = '';
output_folder = '';

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

%% Get all CSV files
csv_files = dir(fullfile(input_folder, '*_adjusted.csv'));

for i = 1:length(csv_files)
    filename = csv_files(i).name;
    filepath = fullfile(input_folder, filename);

    % Read data from CSV file
    opts = detectImportOptions(filepath);
    opts.VariableNamingRule = 'preserve';
    data = readtable(filepath, opts);

    % Rename columns (if needed)
    data.Properties.VariableNames = {'trial_start', 'trial_stopp', 'noise_start', 'noise_duration'};

    % Create event structure for noise events
    noise_events = struct( ...
        'onset',    num2cell(data.noise_start), ...
        'duration', num2cell(data.noise_duration), ...
        'type',     repmat({'noise'}, height(data), 1) ...
    );

    % Save result (use original filename as prefix)
    [~, name, ~] = fileparts(filename);
    save(fullfile(output_folder, [name '_noise_events.mat']), 'noise_events');
end

disp('All data files have been successfully converted and saved.');
