%% Animated year-by-year centroid shifts (GIF) for all three variants
% Requires the results of main.m, composite.m and main_nuts.m (run_all).
% Variants and series are the same as in shift_maps.m.
clear; clc;
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
out = fullfile(root, 'results');
V = shift_variants(out);
for v = 1:numel(V)
    fprintf('Animation %d/%d: %s\n', v, numel(V), V(v).file);
    animate_tracks(V(v).T, V(v).series, V(v).title, fullfile(out, "animation_" + V(v).file + ".gif"));
end
