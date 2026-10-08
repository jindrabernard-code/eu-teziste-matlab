%% Geographic centroid of the EU 2000-2025 by metric (states as points)
% Run: open the project folder in MATLAB and type `main` (or `run_all`).
% Data are downloaded into data/raw/ on the first run (offline afterwards).

clear; clc;
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
raw  = fullfile(root, 'data', 'raw');
out  = fullfile(root, 'results');

years = (2000:2025)';
countries = readtable(fullfile(root, 'data', 'countries.csv'), 'TextType', 'string');
votes = readtable(fullfile(root, 'data', 'council_votes.csv'), 'TextType', 'string');
seats = readtable(fullfile(root, 'data', 'ep_seats.csv'), 'TextType', 'string');
codes = countries.code;
nC = numel(codes);  nY = numel(years);

%% Data: population on 1 January, GDP and government debt (Eurostat),
%  military spending (SIPRI via the World Bank)
geoQ = strjoin("geo=" + codes, "&");
pop  = fetch_eurostat('demo_pjan', geoQ + "&sex=T&age=TOTAL", fullfile(raw, 'pop.csv'));
gdp  = fetch_eurostat('nama_10_gdp', geoQ + "&na_item=B1GQ&unit=CP_MEUR", fullfile(raw, 'gdp_eur.csv'));
pps  = fetch_eurostat('nama_10_gdp', geoQ + "&na_item=B1GQ&unit=CP_MPPS_EU27_2020", fullfile(raw, 'gdp_pps.csv'));
debt = fetch_eurostat('gov_10dd_edpt1', geoQ + "&na_item=GD&sector=S13&unit=MIO_EUR", fullfile(raw, 'debt_eur.csv'));

% military spending in current USD; the currency does not matter because the
% centroid only uses each country's share within a year
mil = fetch_worldbank('MS.MIL.XPND.CD', countries.iso3, fullfile(raw, 'mil_usd.csv'));
[~, ix] = ismember(mil.iso3, countries.iso3);
mil.geo = codes(ix);

POP  = to_matrix(pop, codes, years);   % [years x countries]
GDP  = to_matrix(gdp, codes, years);
PPS  = to_matrix(pps, codes, years);
MIL  = to_matrix(mil, codes, years);
DEBT = to_matrix(debt, codes, years);

% Eurostat no longer publishes UK debt: UK = IMF debt-to-GDP ratio x Eurostat GDP
imf = fetch_imf('GG_DEBT_GDP', "GBR", fullfile(raw, 'imf_debt_gbr.csv'));
uk = codes == "UK";
[okY, yi] = ismember(imf.year, years);
DEBT(yi(okY), uk) = imf.value(okY) / 100 .* GDP(yi(okY), uk);

%% Metrics: each is a weight matrix [years x countries]
M = is_member(countries, years);

W = struct();
W.states     = double(M);                                % one state = one vote (Commission)
W.area       = M .* countries.area_km2';
W.population = POP;
W.ep_seats   = ep_matrix(seats, codes, years);
W.gdp_eur    = GDP;                                      % composites and NUTS fallback only
W.gdp_pps    = PPS;
W.military   = MIL;                                      % nominal military spending
W.debt       = DEBT;                                     % general government gross debt
W.council_votes = zeros(nY, nC);

[~, vRow] = ismember(codes, votes.code);
for y = 1:nY
    m = M(y, :);
    if years(y) <= 2003, v = votes.w_eu15(vRow); else, v = votes.w_nice(vRow); end
    [~, w] = council_rule(years(y), v(m), POP(y, m));
    W.council_votes(y, m) = w;
end

%% Centroids
names = string(fieldnames(W))';
% GDP in EUR is kept in the CSV and in the saved weights (composite.m,
% main_nuts.m) but not in the charts
plotNames = names(names ~= "gdp_eur");
R = table(years, 'VariableNames', {'year'});
for k = names
    [R.(k + "_lat"), R.(k + "_lon")] = centroid_series(W.(k), M, countries.lat, countries.lon);
end
writetable(R, fullfile(out, 'centroids_by_year.csv'));

%% Summary: shift from 2000 to the last year with data
S = table('Size', [numel(names) 7], ...
    'VariableTypes', ["string" "double" "double" "double" "double" "double" "double"], ...
    'VariableNames', ["metric" "last_year" "lat_2000" "lon_2000" "lat_last" "lon_last" "shift_km"]);
S.bearing_deg = nan(numel(names), 1);
for i = 1:numel(names)
    la = R.(names(i) + "_lat");  lo = R.(names(i) + "_lon");
    last = find(~isnan(la), 1, 'last');
    S(i, 1:7) = {names(i), years(last), la(1), lo(1), la(last), lo(last), ...
        haversine_km(la(1), lo(1), la(last), lo(last))};
    S.bearing_deg(i) = bearing_deg(la(1), lo(1), la(last), lo(last));
end
disp(S)
writetable(S, fullfile(out, 'shift_summary.csv'));

% Jumps at enlargements / Brexit for the population metric
fprintf('\nYear-on-year shift of the population centroid (km):\n');
d = haversine_km(R.population_lat(1:end-1), R.population_lon(1:end-1), ...
                 R.population_lat(2:end),   R.population_lon(2:end));
for y = 1:numel(d), fprintf('  %d -> %d: %7.1f\n', years(y), years(y+1), d(y)); end

%% Charts + saved weights (results/weights_states.mat) for the follow-up scripts
plot_results(R, plotNames, years, out);
save(fullfile(out, 'weights_states.mat'), 'W', 'M', 'countries', 'years', 'R');

%% ---------------------------------------------------------------------
function E = ep_matrix(seats, codes, years)
% EP seat allocation valid on 31 December of each year
termStart = [1999 2004 2009 2014 2020 2024];
cols = "t" + termStart;
[~, row] = ismember(codes, seats.code);
E = zeros(numel(years), numel(codes));
for y = 1:numel(years)
    t = cols(find(termStart <= years(y), 1, 'last'));
    E(y, :) = seats.(t)(row);
end
end
