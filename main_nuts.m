%% EU centroid at the level of NUTS-2 / NUTS-3 regions
% Requires a previous run of main.m (results/weights_states.mat: membership,
% national GDP). Metrics are demographic and economic only: political weights
% (Council, EP) cannot be split into regions. Area comes from GISCO polygons.
%
% Outermost regions (French overseas departments, Canary Islands, Azores,
% Madeira) are dropped from the coordinates. Their weight stays with the
% country and is spread over its European regions, as in main.m.

clear; clc;
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
raw  = fullfile(root, 'data', 'raw');
out  = fullfile(root, 'results');
load(fullfile(out, 'weights_states.mat'), 'W', 'M', 'countries', 'years', 'R');
Wstat = W;  Rstat = R;

LEVELS   = [2 3];
VERSIONS = [2024 2021 2016 2013 2010];          % the UK exists only in NUTS 2016 and older
OUTERMOST = ["FRY" "FR9" "FRA" "ES70" "PT20" "PT30"];

%% Eurostat regional data (all NUTS levels at once)
src = {   % metric         dataset              query                          national fallback
    'population',   'demo_r_pjanaggr3', 'sex=T&age=TOTAL',               Wstat.population
    'pop_15_64',    'demo_r_pjanaggr3', 'sex=T&age=Y15-64',              []
    'employment',   'nama_10r_3empers', 'wstatus=EMP&nace_r2=TOTAL',     []
    'gdp_eur',      'nama_10r_3gdp',    'unit=MIO_EUR',                  Wstat.gdp_eur
    'gdp_pps',      'nama_10r_3gdp',    'unit=MIO_PPS_EU27_2020',        Wstat.gdp_pps
};
% national employment (thousand persons, domestic concept) as a fallback, mainly for the UK
geoQ = strjoin("geo=" + countries.code, "&");
emp = fetch_eurostat('nama_10_pe', geoQ + "&unit=THS_PER&na_item=EMP_DC", fullfile(raw, 'emp_national.csv'));
EMP = nan(numel(years), height(countries));
[okG, g] = ismember(emp.geo, countries.code);  [okY, yy] = ismember(emp.year, years);
EMP(sub2ind(size(EMP), yy(okG & okY), g(okG & okY))) = emp.value(okG & okY);
src{3, 4} = EMP;

Tdata = struct();
for i = 1:size(src, 1)
    Tdata.(src{i, 1}) = fetch_eurostat(src{i, 2}, src{i, 3}, ...
        fullfile(raw, "nuts_" + src{i, 1} + ".csv"));
end
% note: national (nama_10_gdp) and regional GDP are both in EUR / PPS million

presets.demographic = struct('population', 0.5, 'pop_15_64', 0.5);
presets.economic    = struct('gdp_eur', 0.4, 'gdp_pps', 0.3, 'employment', 0.3);
presets.balanced    = struct('population', 0.25, 'pop_15_64', 0.25, ...
    'gdp_eur', 0.2, 'gdp_pps', 0.15, 'employment', 0.15);
variants = {
    'demographic',   presets.demographic, 'linear'
    'economic',      presets.economic,    'linear'
    'balanced',      presets.balanced,    'linear'
    'balanced_geom', presets.balanced,    'geometric'
    'entropy',       'entropy',           'linear'
    'pca',           'pca',               'linear'
};

Rn = table(years, 'VariableNames', {'year'});
for L = LEVELS
    % geometry of every NUTS version at this level, EU countries only, no outermost regions
    G = [];
    for v = VERSIONS
        G = [G; load_nuts_geometry(v, L, fullfile(raw, 'nuts'))]; %#ok<AGROW>
    end
    G = G(ismember(G.cntr, countries.code) & ~startsWith(G.code, OUTERMOST), :);

    % regional weights for every metric. All metrics must use the same NUTS
    % version for a given country and year (because of the composites),
    % see choose_nuts_versions.m.
    ref = choose_nuts_versions(cellfun(@(k) Tdata.(k), src(:, 1), 'UniformOutput', false), ...
        G, countries, years, M);
    Wr = struct();  regs = struct();
    for i = 1:size(src, 1)
        [Wr.(src{i, 1}), regs.(src{i, 1}), px] = regional_weights( ...
            Tdata.(src{i, 1}), G, countries, years, M, src{i, 4}, Tdata.population, ref);
        if ~isempty(px)
            fprintf('NUTS-%d %s: no regional data in the shared NUTS version, split by population: %s\n', ...
                L, src{i, 1}, strjoin(px, ', '));
        end
    end
    % area: constant over time, from the polygons (for a code in several versions the newest wins)
    [~, first] = unique(G.code, 'stable');           % G is sorted newest version first
    Tarea = table(repelem(G.code(first), numel(years)), repmat(years, numel(first), 1), ...
        repelem(G.area_km2(first), numel(years)), 'VariableNames', {'geo', 'year', 'value'});
    [Wr.area, regs.area] = regional_weights(Tarea, G, countries, years, M, [], [], ref);

    % common set of columns (different metrics may use different NUTS versions)
    key = @(t) t.code + "@" + string(t.version);
    keys = struct2cell(structfun(key, regs, 'UniformOutput', false));
    allKeys = unique(vertcat(keys{:}));
    U = G(ismember(key(G), allKeys), :);
    for k = string(fieldnames(Wr))'
        Wfull = zeros(numel(years), height(U));
        [~, col] = ismember(key(regs.(k)), key(U));
        Wfull(:, col) = Wr.(k);
        Wfull(any(isnan(Wr.(k)), 2), :) = NaN;
        Wr.(k) = Wfull;
    end
    [~, cIx] = ismember(U.cntr, countries.code);
    Mr = M(:, cIx);           % region belongs to a member; regions of a NUTS version not
                              % used in that year have weight 0, so they do no harm

    tag = "n" + L + "_";
    for k = string(fieldnames(Wr))'
        [Rn.(tag + k + "_lat"), Rn.(tag + k + "_lon")] = centroid_series(Wr.(k), Mr, U.lat, U.lon);
    end
    Sr = structfun(@(w) shares(w, Mr), rmfield(Wr, 'area'), 'UniformOutput', false);
    fprintf('\nNUTS-%d: %d regions (all versions), composite weights:\n', L, height(U));
    for i = 1:size(variants, 1)
        [Wc, a] = composite_weights(Sr, variants{i, 2}, variants{i, 3});
        [Rn.(tag + "c_" + variants{i, 1} + "_lat"), Rn.(tag + "c_" + variants{i, 1} + "_lon")] = ...
            centroid_series(Wc, Mr, U.lat, U.lon);
        k = string(fieldnames(a))';  v = cellfun(@(x) a.(x), cellstr(k));
        fprintf('  %-14s %s\n', variants{i, 1}, strjoin(compose("%s %.2f", k', v'), ', '));
    end
    [Rn.(tag + "population_median_lat"), Rn.(tag + "population_median_lon")] = ...
        centroid_series(Wr.population, Mr, U.lat, U.lon, 'median');

    if L == 3, W3 = Wr; U3 = U; Mr3 = Mr; end
end
writetable(Rn, fullfile(out, 'nuts_centroids.csv'));

%% Resolution comparison: states vs. NUTS-2 vs. NUTS-3
fprintf('\n%-28s %15s %15s %15s %15s\n', 'metric', 'states 2000', 'NUTS-3 2000', 'states last', 'NUTS-3 last');
for k = ["population" "gdp_eur" "gdp_pps" "area"]
    la3 = Rn.("n3_" + k + "_lat");  lo3 = Rn.("n3_" + k + "_lon");
    e = find(~isnan(la3), 1, 'last');  b = find(~isnan(la3), 1);
    fprintf('%-28s %6.2fN %5.2fE  %6.2fN %5.2fE  %6.2fN %5.2fE  %6.2fN %5.2fE  (%d-%d, states vs. NUTS-3 %3.0f km)\n', k, ...
        Rstat.(k + "_lat")(b), Rstat.(k + "_lon")(b), la3(b), lo3(b), ...
        Rstat.(k + "_lat")(e), Rstat.(k + "_lon")(e), la3(e), lo3(e), years(b), years(e), ...
        haversine_km(Rstat.(k + "_lat")(e), Rstat.(k + "_lon")(e), la3(e), lo3(e)));
end
fprintf('\nShift 2000 -> last year at NUTS-3:\n');
for v = erase(string(Rn.Properties.VariableNames(startsWith(Rn.Properties.VariableNames, 'n3_') & endsWith(Rn.Properties.VariableNames, '_lat'))), ["n3_" "_lat"])
    la = Rn.("n3_" + v + "_lat");  lo = Rn.("n3_" + v + "_lon");
    b = find(~isnan(la), 1);  e = find(~isnan(la), 1, 'last');
    fprintf('  %-22s %d %6.2fN %5.2fE -> %d %6.2fN %5.2fE  %4.0f km\n', v, years(b), la(b), lo(b), ...
        years(e), la(e), lo(e), haversine_km(la(b), lo(b), la(e), lo(e)));
end

plot_nuts(Rn, Rstat, W3, U3, Mr3, years, out);
