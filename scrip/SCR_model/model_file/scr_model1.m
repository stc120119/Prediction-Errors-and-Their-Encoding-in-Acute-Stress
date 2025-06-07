%% Model 1: GLM with only noise-related events
clear

% -------------------- Set directory paths ---------------------
data_dir = '';
event_dir = '';
output_dir = fullfile('', 'model1_result');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% -------------------- Find all data files ---------------------
data_files = dir(fullfile(data_dir, 'pspm_*.mat'));
all_aic = [];
all_bic = [];

for i = 1:length(data_files)
    data_file = data_files(i).name;
    [~, base_name, ~] = fileparts(data_file); % e.g., pspm_4_segment
    suffix = erase(base_name, {'pspm_', '_eda_signals'}); % e.g., 4_segment

    % Build event filename
    event_file = fullfile(event_dir, [suffix '_noise_events.mat']);
    if ~isfile(event_file)
        warning('Event file %s not found, skipping.', event_file);
        continue;
    end

    % Load data
    data_path = fullfile(data_dir, data_file);
    [~, ~] = pspm_load_data(data_path);  % Load data into PsPM

    % Load events
    load(event_file);  % Load variable: noise_events
    if ~exist('noise_events', 'var')
        warning('Variable noise_events not found in file %s.', event_file);
        continue;
    end

    % Build event structure
    model_timing = struct();
    model_timing.names = {'Noise'};
    model_timing.onsets = { [noise_events(:).onset] };
    model_timing.durations = {0};

    % Build model structure
    model = struct();
    model.modelfile = fullfile(output_dir, ['glm_' suffix '.mat']);
    model.datafile = {data_path};
    model.timing = model_timing;
    model.timeunits = 'seconds';
    model.modality = 'scr';
    model.norm = 1;
    model.modelspec = 'scr';
    model.bf.fhandle = 'pspm_bf_scrf';
    model.bf.args = 2;   % Second-order basis function

    % Build options structure
    options = struct();
    options.overwrite = 1;

    % Run GLM
    fprintf('Processing: %s\n', data_file);
    pspm_glm(model, options);

    % Load GLM results
    load(model.modelfile, 'glm');

    % Compute AIC and BIC
    n = size(glm.YM, 1);                  % Number of observations
    RSS = sum((glm.YM - glm.Yhat).^2);    % Residual sum of squares
    sigma2 = RSS / n;                     % Estimated variance
    k = size(glm.X, 2);                   % Number of parameters (including intercept)

    % Log-likelihood for Gaussian model
    logL = -n/2 * log(2*pi*sigma2) - RSS / (2*sigma2);

    % Akaike Information Criterion
    AIC = -2 * logL + 2 * k;
    % Bayesian Information Criterion
    BIC = -2 * logL + k * log(n);
    
    all_aic(end+1) = AIC;
    all_bic(end+1) = BIC;
end

fprintf('All processing completed, results saved to: %s\n', output_dir);

% Compute total AIC and BIC
total_aic = sum(all_aic);
total_bic = sum(all_bic);
fprintf('Total AIC: %.2f\n', total_aic);
fprintf('Total BIC: %.2f\n', total_bic);
save(fullfile(output_dir, 'aic_results.mat'), 'all_aic', 'total_aic');
save(fullfile(output_dir, 'bic_results.mat'), 'all_bic', 'total_bic');
