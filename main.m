%% Geografické těžiště EU 2000-2025 podle různých metrik
% Spuštění: v MATLABu otevřít složku projektu a dát `main`.
% Data z Eurostatu se při prvním běhu stáhnou do data/raw/ (pak offline).

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

%% Eurostat: obyvatelstvo k 1. 1. a HDP (nominální EUR, PPS)
geoQ = strjoin("geo=" + codes, "&");
pop = fetch_eurostat('demo_pjan', geoQ + "&sex=T&age=TOTAL", fullfile(raw, 'pop.csv'));
gdp = fetch_eurostat('nama_10_gdp', geoQ + "&na_item=B1GQ&unit=CP_MEUR", fullfile(raw, 'gdp_eur.csv'));
pps = fetch_eurostat('nama_10_gdp', geoQ + "&na_item=B1GQ&unit=CP_MPPS_EU27_2020", fullfile(raw, 'gdp_pps.csv'));

POP = to_matrix(pop, codes, years);   % [roky x státy]
GDP = to_matrix(gdp, codes, years);
PPS = to_matrix(pps, codes, years);

%% Metriky: každá je matice vah [roky x státy]
M = is_member(countries, years);

W = struct();
W.staty    = double(M);                                  % 1 stát = 1 hlas (Komise)
W.plocha   = M .* countries.area_km2';
W.populace = POP;
W.ep       = ep_matrix(seats, codes, years);
W.hdp_eur  = GDP;
W.hdp_pps  = PPS;
W.rada_hlasy = zeros(nY, nC);
W.rada_sila  = zeros(nY, nC);                            % Banzhafův index

[~, vRow] = ismember(codes, votes.code);
for y = 1:nY
    m = M(y, :);
    if years(y) <= 2003, v = votes.w_eu15(vRow); else, v = votes.w_nice(vRow); end
    [rule, w] = council_rule(years(y), v(m), POP(y, m));
    W.rada_hlasy(y, m) = w;
    W.rada_sila(y, m)  = banzhaf_mc(rule, nnz(m), 1e5, years(y));
end

%% Těžiště
names = string(fieldnames(W))';
R = table(years, 'VariableNames', {'year'});
for k = names
    [R.(k + "_lat"), R.(k + "_lon")] = centroid_series(W.(k), M, countries.lat, countries.lon);
end
writetable(R, fullfile(out, 'teziste_po_letech.csv'));

%% Souhrn: posun 2000 -> poslední rok s daty
S = table('Size', [numel(names) 7], ...
    'VariableTypes', ["string" "double" "double" "double" "double" "double" "double"], ...
    'VariableNames', ["metrika" "rok_do" "lat_2000" "lon_2000" "lat_konec" "lon_konec" "posun_km"]);
S.azimut_deg = nan(numel(names), 1);
for i = 1:numel(names)
    la = R.(names(i) + "_lat");  lo = R.(names(i) + "_lon");
    last = find(~isnan(la), 1, 'last');
    S(i, 1:7) = {names(i), years(last), la(1), lo(1), la(last), lo(last), ...
        haversine_km(la(1), lo(1), la(last), lo(last))};
    S.azimut_deg(i) = bearing_deg(la(1), lo(1), la(last), lo(last));
end
disp(S)
writetable(S, fullfile(out, 'souhrn_posunu.csv'));

% Skoky při rozšířeních / Brexitu pro populační metriku
fprintf('\nMeziroční posun populačního těžiště (km):\n');
d = haversine_km(R.populace_lat(1:end-1), R.populace_lon(1:end-1), ...
                 R.populace_lat(2:end),   R.populace_lon(2:end));
for y = 1:numel(d), fprintf('  %d -> %d: %7.1f\n', years(y), years(y+1), d(y)); end

%% Grafy + uložení vah (results/vahy_staty.mat) pro navazující analýzy
plot_results(R, names, years, out);
save(fullfile(out, 'vahy_staty.mat'), 'W', 'M', 'countries', 'years', 'R');

%% ---------------------------------------------------------------------
function X = to_matrix(T, codes, years)
% long tabulka (geo, year, value) -> matice [roky x státy], chybějící = NaN
X = nan(numel(years), numel(codes));
[okG, g] = ismember(T.geo, codes);
[okY, y] = ismember(T.year, years);
ok = okG & okY;
X(sub2ind(size(X), y(ok), g(ok))) = T.value(ok);
end

function E = ep_matrix(seats, codes, years)
% rozdělení mandátů EP platné k 31. 12. daného roku
termStart = [1999 2004 2009 2014 2020 2024];
cols = "t" + termStart;
[~, row] = ismember(codes, seats.code);
E = zeros(numel(years), numel(codes));
for y = 1:numel(years)
    t = cols(find(termStart <= years(y), 1, 'last'));
    E(y, :) = seats.(t)(row);
end
end
