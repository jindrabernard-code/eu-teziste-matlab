%% Whole project: states -> composite index -> NUTS regions -> budget -> maps
main             % centroids by individual metric, saves results/weights_states.mat
composite        % composite indices at state level
main_nuts        % NUTS-2 / NUTS-3 (the first run downloads tens of MB, ~5 MB is cached)
budget           % net payers / receivers of the EU budget (standalone outputs)
shift_maps       % year-by-year shift maps for the three variants
shift_animations % the same as animated GIFs
