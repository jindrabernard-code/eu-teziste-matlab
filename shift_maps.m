%% Year-by-year centroid shift maps for all three variants
% Requires the results of main.m, composite.m and main_nuts.m (run_all).
% The series of each variant are defined in src/shift_variants.m.
clear; clc;
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
out = fullfile(root, 'results');
V = shift_variants(out);
for v = 1:numel(V)
    plot_yearly_tracks(V(v).T, V(v).series, V(v).title + " 2000–2025", ...
        fullfile(out, "shifts_" + V(v).file + ".png"));
end
