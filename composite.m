%% Composite index of the EU centroid (states as points)
% Requires a previous run of main.m (results/weights_states.mat).
% Every metric is turned into shares (sum over the EU = 1), then the shares
% are combined into one weight per country. Compared here:
%   - hand-set weight presets (political / economic / balanced)
%   - objective weights (entropy, PCA)
%   - linear vs. geometric mean
%   - centroid vs. geometric median

clear; clc;
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
out = fullfile(root, 'results');
load(fullfile(out, 'weights_states.mat'), 'W', 'M', 'countries', 'years', 'R');

S = structfun(@(w) shares(w, M), W, 'UniformOutput', false);

%% Weight presets (need not sum to 1, they are normalised)
P.political = struct('council_votes', 0.4, 'ep_seats', 0.3, 'states', 0.3);
P.economic  = struct('gdp_eur', 0.5, 'gdp_pps', 0.5);
P.balanced  = struct('population', 1/3, ...
    'council_votes', 0.4/3, 'ep_seats', 0.3/3, 'states', 0.3/3, ...  % 1/3 politics
    'gdp_eur', 0.5/3, 'gdp_pps', 0.5/3);                            % 1/3 economy

% Variants: {name, weights, method}
V = {
    'political',      P.political, 'linear'
    'economic',       P.economic,  'linear'
    'balanced',       P.balanced,  'linear'
    'balanced_geom',  P.balanced,  'geometric'
    'entropy',        'entropy',   'linear'
    'pca',            'pca',       'linear'
};
% objective weights (entropy, PCA) without Council votes: from 2014 they equal
% population, which would then be counted twice
SP = rmfield(S, 'council_votes');

K = table(years, 'VariableNames', {'year'});
fprintf('Metric weights in each variant:\n');
for i = 1:size(V, 1)
    if ischar(V{i, 2}), Si = SP; else, Si = S; end
    [Wc, a] = composite_weights(Si, V{i, 2}, V{i, 3});
    [K.(V{i, 1} + "_lat"), K.(V{i, 1} + "_lon")] = ...
        centroid_series(Wc, M, countries.lat, countries.lon);
    fprintf('  %-14s %s\n', V{i, 1}, format_alpha(a));
end

% Geometric median (Weber point) for population and the balanced composite
[K.population_median_lat, K.population_median_lon] = ...
    centroid_series(W.population, M, countries.lat, countries.lon, 'median');
Wb = composite_weights(S, P.balanced, 'linear');
[K.balanced_median_lat, K.balanced_median_lon] = ...
    centroid_series(Wb, M, countries.lat, countries.lon, 'median');

writetable(K, fullfile(out, 'composite_centroids.csv'));

%% Summary of the shift 2000 -> last year
variants = erase(string(K.Properties.VariableNames(endsWith(K.Properties.VariableNames, '_lat'))), "_lat");
fprintf('\n%-18s %16s %16s %8s\n', 'variant', '2000', 'last', 'km');
for v = variants
    la = K.(v + "_lat");  lo = K.(v + "_lon");  e = find(~isnan(la), 1, 'last');
    fprintf('%-18s %6.2f N %5.2f E %6.2f N %5.2f E %8.0f\n', v, la(1), lo(1), la(e), lo(e), ...
        haversine_km(la(1), lo(1), la(e), lo(e)));
end

%% Map: individual metrics in grey, composites in colour
f = figure('Visible', 'off', 'Position', [100 100 1100 800]);
mp = EuMap(f, [34 71], [-11 35], true);
for k = string(fieldnames(S))'
    mp.line(R.(k + "_lat"), R.(k + "_lon"), '-', 'Color', [0.6 0.6 0.6], ...
        'LineWidth', 0.8, 'HandleVisibility', 'off');
end
cols = [lines(7); 0 0 0];
for i = 1:numel(variants)
    v = variants(i);  la = K.(v + "_lat");  lo = K.(v + "_lon");
    ls = '-';  if contains(v, 'median'), ls = '--'; end
    mp.line(la, lo, ls, 'Color', cols(i, :), 'LineWidth', 2, 'DisplayName', strrep(v, '_', ' '));
    e = find(~isnan(la), 1, 'last');
    mp.scatter(la(e), lo(e), 50, cols(i, :), 'filled', 'HandleVisibility', 'off');
end
mp.limits([46.5 52], [5 16]);
legend(mp.Ax, 'Location', 'southoutside', 'NumColumns', 4);
title(mp.Ax, 'EU composite centroids 2000–2025 (grey = individual metrics)');
exportgraphics(f, fullfile(out, 'composite_map.png'), 'Resolution', 150);
close(f);

function s = format_alpha(a)
k = string(fieldnames(a))';
v = cellfun(@(x) a.(x), cellstr(k));
s = strjoin(compose("%s %.2f", k(v > 0.005)', v(v > 0.005)'), ', ');
end
