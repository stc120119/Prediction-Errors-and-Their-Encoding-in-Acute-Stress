%% Convert all available PEp data files
%% Set input and output paths
input_folder  = '';
output_folder = '';

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

%% Get all CSV files
csv_files = dir(fullfile(input_folder, '*_PEp.csv'));

for i = 1:length(csv_files)
    filename = csv_files(i).name;
    filepath = fullfile(input_folder, filename);

    % Read data from CSV file
    opts = detectImportOptions(filepath);
    opts.VariableNamingRule = 'preserve';
    data = readtable(filepath, opts);

    % Rename columns (if needed)
    data.Properties.VariableNames = {'trial_start', 'trial_stopp', 'PEp_start', 'PEp_duration', 'alpha_p'};

    % Create event structure for positive prediction error events (PEp)
    PEp_events = struct( ...
        'onset',    num2cell(data.PEp_start), ...
        'duration', num2cell(data.PEp_duration), ...
        'type',     repmat({'PEp'}, height(data), 1), ...
        'value',    num2cell(data.alpha_p) ...
    );

    % Save result using cleaned filename as prefix
    [~, name, ~] = fileparts(filename);
    short_name = erase(name, '_PEp');
    save(fullfile(output_folder, [short_name '_PEp_events.mat']), 'PEp_events');
end

disp('All PEp data files have been successfully converted and saved.');
