%% EU budget: centroids of net payers and net receivers (standalone outputs)
% The operating budgetary balance is signed (payers < 0, receivers > 0) and
% sums to zero over the EU, so it cannot give a single centroid. Two are
% computed instead: net payers weighted by what they pay, net receivers by
% what they receive. They are kept out of the main shift maps and have their
% own files:
%   results/budget_centroids.csv   centroids by year + distance between them
%   results/budget_axis.png        map of both tracks, distance, volume
%   results/budget_shifts.png      year-by-year shift map (as shift_maps.m)
%   results/budget_animation.gif   the same as an animation

clear; clc;
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
raw  = fullfile(root, 'data', 'raw');
out  = fullfile(root, 'results');

years = (2000:2025)';
countries = readtable(fullfile(root, 'data', 'countries.csv'), 'TextType', 'string');
codes = countries.code;
M = is_member(countries, years);

bud = eu_budget_balance(raw);
OBB = to_matrix(table(bud.code, bud.year, bud.obb, 'VariableNames', {'geo', 'year', 'value'}), codes, years);
Wp = max(-OBB, 0);  Wp(isnan(OBB)) = NaN;          % net payers: what they pay
Wr = max(OBB, 0);   Wr(isnan(OBB)) = NaN;          % net receivers: what they receive

B = table(years, 'VariableNames', {'year'});
[B.net_payers_lat, B.net_payers_lon] = centroid_series(Wp, M, countries.lat, countries.lon);
[B.net_receivers_lat, B.net_receivers_lon] = centroid_series(Wr, M, countries.lat, countries.lon);
B.distance_km = haversine_km(B.net_payers_lat, B.net_payers_lon, B.net_receivers_lat, B.net_receivers_lon);
O = OBB;  O(~M) = NaN;
B.redistribution_eur_bn = sum(max(O, 0), 2, 'omitnan') / 1e3;
writetable(B, fullfile(out, 'budget_centroids.csv'));
disp(B)

plot_budget_axis(B, OBB, M, years, out);
series = {
    'Net payers',     'net_payers',    false
    'Net receivers',  'net_receivers', true};    % ~1,250 km from Spain to Hungary: own zoom
plot_yearly_tracks(B, series, "EU budget: net payers and net receivers 2000–2025", ...
    fullfile(out, 'budget_shifts.png'));
animate_tracks(B, series, "EU budget: net payers and net receivers", ...
    fullfile(out, 'budget_animation.gif'));
