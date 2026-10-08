%% Kompozitní index těžiště EU (úroveň států)
% Vyžaduje předchozí běh main.m (results/vahy_staty.mat).
% Každá metrika se převede na podíly (součet přes EU = 1), pak se podíly
% složí do jedné váhy státu. Porovnává se:
%   - ruční předvolby vah (politická / ekonomická / vyvážená)
%   - objektivní váhy (entropie, PCA)
%   - lineární vs. geometrický průměr
%   - těžiště vs. geometrický medián

clear; clc;
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
out = fullfile(root, 'results');
load(fullfile(out, 'vahy_staty.mat'), 'W', 'M', 'countries', 'years', 'R');

S = structfun(@(w) shares(w, M), W, 'UniformOutput', false);

%% Předvolby vah (součet nemusí být 1, normalizuje se)
P.politicky  = struct('rada_hlasy', 0.4, 'ep', 0.3, 'staty', 0.3);
P.ekonomicky = struct('hdp_eur', 0.5, 'hdp_pps', 0.5);
P.vyvazeny   = struct('populace', 1/3, ...
    'rada_hlasy', 0.4/3, 'ep', 0.3/3, 'staty', 0.3/3, ...  % 1/3 politika
    'hdp_eur', 0.5/3, 'hdp_pps', 0.5/3);                   % 1/3 ekonomika

% Varianty: {název, váhy, metoda}
V = {
    'politicky',          P.politicky,  'linear'
    'ekonomicky',         P.ekonomicky, 'linear'
    'vyvazeny',           P.vyvazeny,   'linear'
    'vyvazeny_geom',      P.vyvazeny,   'geometric'
    'entropie',           'entropy',    'linear'
    'pca',                'pca',        'linear'
};
% objektivní váhy (entropie, PCA) bez hlasů v Radě: od 2014 = populace,
% takže by populace dostala dvojí váhu
SP = rmfield(S, 'rada_hlasy');

K = table(years, 'VariableNames', {'year'});
fprintf('Váhy metrik v jednotlivých variantách:\n');
for i = 1:size(V, 1)
    if ischar(V{i, 2}), Si = SP; else, Si = S; end
    [Wc, a] = composite_weights(Si, V{i, 2}, V{i, 3});
    [K.(V{i, 1} + "_lat"), K.(V{i, 1} + "_lon")] = ...
        centroid_series(Wc, M, countries.lat, countries.lon);
    fprintf('  %-14s %s\n', V{i, 1}, format_alpha(a));
end

% Geometrický medián (Weberův bod) pro populaci a vyvážený kompozit
[K.populace_median_lat, K.populace_median_lon] = ...
    centroid_series(W.populace, M, countries.lat, countries.lon, 'median');
Wv = composite_weights(S, P.vyvazeny, 'linear');
[K.vyvazeny_median_lat, K.vyvazeny_median_lon] = ...
    centroid_series(Wv, M, countries.lat, countries.lon, 'median');

writetable(K, fullfile(out, 'kompozit_teziste.csv'));

%% Souhrn posunu 2000 -> konec
variants = erase(string(K.Properties.VariableNames(endsWith(K.Properties.VariableNames, '_lat'))), "_lat");
fprintf('\n%-18s %16s %16s %8s\n', 'varianta', '2000', 'konec', 'km');
for v = variants
    la = K.(v + "_lat");  lo = K.(v + "_lon");  e = find(~isnan(la), 1, 'last');
    fprintf('%-18s %6.2f N %5.2f E %6.2f N %5.2f E %8.0f\n', v, la(1), lo(1), la(e), lo(e), ...
        haversine_km(la(1), lo(1), la(e), lo(e)));
end

%% Mapa: jednotlivé metriky šedě, kompozity barevně
f = figure('Visible', 'off', 'Position', [100 100 1100 800]);
mp = EuMap(f, [34 71], [-11 35], true);
for k = string(fieldnames(W))'
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
title(mp.Ax, 'Kompozitní těžiště EU 2000–2025 (šedě = jednotlivé metriky)');
exportgraphics(f, fullfile(out, 'kompozit_mapa.png'), 'Resolution', 150);
close(f);

function s = format_alpha(a)
k = string(fieldnames(a))';
v = cellfun(@(x) a.(x), cellstr(k));
s = strjoin(compose("%s %.2f", k(v > 0.005)', v(v > 0.005)'), ', ');
end
