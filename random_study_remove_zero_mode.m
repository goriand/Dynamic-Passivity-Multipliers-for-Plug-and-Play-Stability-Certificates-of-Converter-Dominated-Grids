%% Simple Random GFM Location Study
% This script runs multi_machine_example multiple times with random GFM locations
% The original script has the gfm_conn_buses line commented out
% This version allows one unstable real eigenvalue

clear all
close all

warning('off', 'all');


% Configuration
num_simulations = 50;  % Number of random allocations to test
num_gfms = 8;          % Number of GFM inverters

% IEEE 39 bus system has buses 1-39
all_buses = 1:39;
% Remove buses that might cause issues (typically slack bus, generator buses)
excluded_buses = [30:39];  % Generator buses typically
all_buses = setdiff(all_buses, excluded_buses);

% Storage for results
all_eigenvalues = {};  % Use cell array to handle variable sizes
all_allocations = [];
stability_status = [];
simulation_success = [];

fprintf('Running %d simulations with random GFM allocations...\n', num_simulations);
fprintf('Make sure gfm_conn_buses line is commented out in multi_machine_example.m\n\n');

for sim = 1:num_simulations
    fprintf('Simulation %d/%d: ', sim, num_simulations);
    
    try
        % Randomly select 8 buses from available buses
        random_buses = randperm(length(all_buses), num_gfms);
        gfm_conn_buses = sort(all_buses(random_buses))';  % Sort for consistency
        
        fprintf('GFM buses [%s] -> ', num2str(gfm_conn_buses'));
        
        % Store the allocation
        all_allocations = [all_allocations; gfm_conn_buses'];
        
        % Set the variable in workspace and run the script
        assignin('base', 'gfm_conn_buses', gfm_conn_buses);
        
        % Run the analysis
        run('multi_machine_example.m');
        
        % Get eigenvalues from workspace
        mode_system = evalin('base', 'mode_system');
        
        % Store eigenvalues
        all_eigenvalues{sim} = mode_system;
        
        % Check stability
        % Check stability - allow one unstable real eigenvalue
        real_parts = real(mode_system);
        imag_parts = imag(mode_system);
        unstable_real_eigs = sum(real_parts > 0);
        % Allow real unstable eigenvalues
        unstable_imag_eigs = sum(real_parts > 0 & imag_parts > 0);
        % is_stable = unstable_real_eigs <= 1;
        is_stable = unstable_imag_eigs == 0;
        stability_status = [stability_status; is_stable];
        simulation_success = [simulation_success; 1];
        
        fprintf('✓ Stable: %s\n', string(is_stable));
        
    catch ME
        fprintf('✗ Error: %s\n', ME.message);
        % Store empty for failed simulations
        all_eigenvalues{sim} = [];
        stability_status = [stability_status; 0];
        simulation_success = [simulation_success; 0];
    end
end

fprintf('\n=== ANALYSIS COMPLETE ===\n');

%% Analysis and Plotting
successful_sims = find(simulation_success == 1);
fprintf('Total simulations: %d\n', num_simulations);
fprintf('Successful simulations: %d\n', length(successful_sims));

if ~isempty(successful_sims)
    successful_stability = stability_status(successful_sims);
    successful_allocations = all_allocations(successful_sims, :);
    
    fprintf('Stable cases: %d/%d (%.1f%%)\n', sum(successful_stability), ...
        length(successful_sims), 100*sum(successful_stability)/length(successful_sims));
    
    %% Plot eigenvalues
    figure(1);
    clf;
    hold on;
    
    % Collect all eigenvalues for plotting
    stable_eigs = [];
    unstable_eigs = [];
    
    for i = 1:length(successful_sims)
        sim_idx = successful_sims(i);
        eigs = all_eigenvalues{sim_idx};
        
        if successful_stability(i) == 1
            stable_eigs = [stable_eigs; eigs(:)];
        else
            unstable_eigs = [unstable_eigs; eigs(:)];
        end
    end
    
    % Plot eigenvalues
    if ~isempty(stable_eigs)
        plot(real(stable_eigs), imag(stable_eigs), 'g.', 'MarkerSize', 3, 'DisplayName', 'Stable');
    end
    
    if ~isempty(unstable_eigs)
        plot(real(unstable_eigs), imag(unstable_eigs), 'r.', 'MarkerSize', 3, 'DisplayName', 'Unstable');
    end
    
    % Add stability boundary
    xline(0, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Stability Boundary');
    xlabel('Real Part');
    ylabel('Imaginary Part');
    title(sprintf('Eigenvalues for %d Random GFM Allocations', length(successful_sims)));
    legend('Location', 'best');
    grid on;
    
    %% Plot stability statistics
    figure(2);
    subplot(2,1,1);
    bar([sum(successful_stability), sum(~successful_stability)]);
    set(gca, 'XTickLabel', {'Stable', 'Unstable'});
    ylabel('Number of Cases');
    title('Stability Statistics');
    grid on;
    
    subplot(2,1,2);
    plot(1:length(successful_stability), successful_stability, 'bo-', 'MarkerSize', 4);
    xlabel('Successful Simulation Number');
    ylabel('Stable (1) / Unstable (0)');
    title('Stability vs Simulation');
    ylim([-0.1, 1.1]);
    grid on;
    
    %% Display some allocation examples
    fprintf('\n=== SAMPLE ALLOCATIONS ===\n');
    num_examples = min(10, length(successful_sims));
    
    % Show some stable cases
    stable_indices = find(successful_stability == 1);
    if ~isempty(stable_indices)
        fprintf('STABLE cases:\n');
        for i = 1:min(5, length(stable_indices))
            idx = stable_indices(i);
            fprintf('  Sim %d: [%s]\n', successful_sims(idx), num2str(successful_allocations(idx,:)));
        end
    end
    
    % Show some unstable cases
    unstable_indices = find(successful_stability == 0);
    if ~isempty(unstable_indices)
        fprintf('UNSTABLE cases:\n');
        for i = 1:min(5, length(unstable_indices))
            idx = unstable_indices(i);
            fprintf('  Sim %d: [%s]\n', successful_sims(idx), num2str(successful_allocations(idx,:)));
        end
    end
    
else
    fprintf('No successful simulations to analyze.\n');
end

%% Save results
save('simple_random_results.mat', 'all_allocations', 'all_eigenvalues', ...
     'stability_status', 'simulation_success', 'num_simulations');

fprintf('\nResults saved to simple_random_results.mat\n');

%% Clean up workspace
clear gfm_conn_buses;  % Remove the variable we set
fprintf('Workspace variable gfm_conn_buses cleared.\n');