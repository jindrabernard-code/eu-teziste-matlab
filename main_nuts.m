%% Těžiště EU na úrovni regionů NUTS-2 / NUTS-3
% Vyžaduje předchozí běh main.m (results/vahy_staty.mat: členství, národní HDP).
% Metriky jsou jen demografické a ekonomické, politické váhy (Rada, EP)
% se na regiony rozpočítat nedají. Plocha je počítaná z polygonů GISCO.
%
% Zámořská území (francouzské DOM, Kanárské ostrovy, Azory, Madeira) se
% ze souřadnic vyřazují. Jejich váha zůstává státu a rozpočítá se na
% evropské regiony, stejně jako v main.m.

clear; clc;
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
raw  = fullfile(root, 'data', 'raw');
out  = fullfile(root, 'results');
load(fullfile(out, 'vahy_staty.mat'), 'W', 'M', 'countries', 'years', 'R');
Wstat = W;  Rstat = R;

LEVELS   = [2 3];
VERSIONS = [2024 2021 2016 2013 2010];          % UK je jen v NUTS 2016 a starších
OUTERMOST = ["FRY" "FR9" "FRA" "ES70" "PT20" "PT30"];

%% Regionální data Eurostatu (obsahují všechny úrovně NUTS najednou)
src = {   % metrika        dataset              dotaz                          národní záloha
    'populace',     'demo_r_pjanaggr3', 'sex=T&age=TOTAL',               Wstat.populace
    'pop_15_64',    'demo_r_pjanaggr3', 'sex=T&age=Y15-64',              []
    'zamestnanost', 'nama_10r_3empers', 'wstatus=EMP&nace_r2=TOTAL',     []
    'hdp_eur',      'nama_10r_3gdp',    'unit=MIO_EUR',                  Wstat.hdp_eur
    'hdp_pps',      'nama_10r_3gdp',    'unit=MIO_PPS_EU27_2020',        Wstat.hdp_pps
};
% národní zaměstnanost (tis. osob, domácí pojetí) jako záloha, hlavně pro UK
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
% pozn.: národní (nama_10_gdp) i regionální HDP jsou v mil. EUR / mil. PPS

presets.demograficky = struct('populace', 0.5, 'pop_15_64', 0.5);
presets.ekonomicky   = struct('hdp_eur', 0.4, 'hdp_pps', 0.3, 'zamestnanost', 0.3);
presets.vyvazeny     = struct('populace', 0.25, 'pop_15_64', 0.25, ...
    'hdp_eur', 0.2, 'hdp_pps', 0.15, 'zamestnanost', 0.15);
variants = {
    'demograficky',  presets.demograficky, 'linear'
    'ekonomicky',    presets.ekonomicky,   'linear'
    'vyvazeny',      presets.vyvazeny,     'linear'
    'vyvazeny_geom', presets.vyvazeny,     'geometric'
    'entropie',      'entropy',            'linear'
    'pca',           'pca',                'linear'
};

Rn = table(years, 'VariableNames', {'year'});
for L = LEVELS
    % geometrie všech verzí NUTS dané úrovně, jen státy EU, bez zámoří
    G = [];
    for v = VERSIONS
        G = [G; load_nuts_geometry(v, L, fullfile(raw, 'nuts'))]; %#ok<AGROW>
    end
    G = G(ismember(G.cntr, countries.code) & ~startsWith(G.code, OUTERMOST), :);

    % váhy regionů pro každou metriku na společné sadě sloupců
    % Všechny metriky musí pro daný stát a rok stát na stejné verzi NUTS
    % (kvůli kompozitům), viz choose_nuts_versions.m.
    ref = choose_nuts_versions(cellfun(@(k) Tdata.(k), src(:, 1), 'UniformOutput', false), ...
        G, countries, years, M);
    Wr = struct();  regs = struct();
    for i = 1:size(src, 1)
        [Wr.(src{i, 1}), regs.(src{i, 1}), px] = regional_weights( ...
            Tdata.(src{i, 1}), G, countries, years, M, src{i, 4}, Tdata.populace, ref);
        if ~isempty(px)
            fprintf('NUTS-%d %s: bez regionálních dat ve společné verzi NUTS, rozděleno podle populace: %s\n', ...
                L, src{i, 1}, strjoin(px, ', '));
        end
    end
    % plocha: konstantní v čase, z polygonů (u kódu ve více verzích platí nejnovější)
    [~, first] = unique(G.code, 'stable');           % G je seřazené od nejnovější verze
    Tarea = table(repelem(G.code(first), numel(years)), repmat(years, numel(first), 1), ...
        repelem(G.area_km2(first), numel(years)), 'VariableNames', {'geo', 'year', 'value'});
    [Wr.plocha, regs.plocha] = regional_weights(Tarea, G, countries, years, M, [], [], ref);

    % sjednotit sloupce (různé metriky mohou použít různé verze NUTS)
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
    Mr = M(:, cIx);           % region patří členovi; regiony jiné verze NUTS, než jakou
                              % daný rok použil, mají váhu 0, takže nevadí

    tag = "n" + L + "_";
    for k = string(fieldnames(Wr))'
        [Rn.(tag + k + "_lat"), Rn.(tag + k + "_lon")] = centroid_series(Wr.(k), Mr, U.lat, U.lon);
    end
    Sr = structfun(@(w) shares(w, Mr), rmfield(Wr, 'plocha'), 'UniformOutput', false);
    fprintf('\nNUTS-%d: %d regionů (všechny verze), váhy kompozitů:\n', L, height(U));
    for i = 1:size(variants, 1)
        [Wc, a] = composite_weights(Sr, variants{i, 2}, variants{i, 3});
        [Rn.(tag + "k_" + variants{i, 1} + "_lat"), Rn.(tag + "k_" + variants{i, 1} + "_lon")] = ...
            centroid_series(Wc, Mr, U.lat, U.lon);
        k = string(fieldnames(a))';  v = cellfun(@(x) a.(x), cellstr(k));
        fprintf('  %-14s %s\n', variants{i, 1}, strjoin(compose("%s %.2f", k', v'), ', '));
    end
    [Rn.(tag + "populace_median_lat"), Rn.(tag + "populace_median_lon")] = ...
        centroid_series(Wr.populace, Mr, U.lat, U.lon, 'median');

    if L == 3, W3 = Wr; U3 = U; Mr3 = Mr; end
end
writetable(Rn, fullfile(out, 'nuts_teziste.csv'));

%% Srovnání rozlišení: stát vs. NUTS-2 vs. NUTS-3
fprintf('\n%-28s %15s %15s %15s %15s\n', 'metrika', 'stát 2000', 'NUTS-3 2000', 'stát konec', 'NUTS-3 konec');
for k = ["populace" "hdp_eur" "hdp_pps" "plocha"]
    la3 = Rn.("n3_" + k + "_lat");  lo3 = Rn.("n3_" + k + "_lon");
    e = find(~isnan(la3), 1, 'last');  b = find(~isnan(la3), 1);
    fprintf('%-28s %6.2fN %5.2fE  %6.2fN %5.2fE  %6.2fN %5.2fE  %6.2fN %5.2fE  (%d-%d, rozdíl stát/NUTS-3 %3.0f km)\n', k, ...
        Rstat.(k + "_lat")(b), Rstat.(k + "_lon")(b), la3(b), lo3(b), ...
        Rstat.(k + "_lat")(e), Rstat.(k + "_lon")(e), la3(e), lo3(e), years(b), years(e), ...
        haversine_km(Rstat.(k + "_lat")(e), Rstat.(k + "_lon")(e), la3(e), lo3(e)));
end
fprintf('\nPosun 2000 -> konec na NUTS-3:\n');
for v = erase(string(Rn.Properties.VariableNames(startsWith(Rn.Properties.VariableNames, 'n3_') & endsWith(Rn.Properties.VariableNames, '_lat'))), ["n3_" "_lat"])
    la = Rn.("n3_" + v + "_lat");  lo = Rn.("n3_" + v + "_lon");
    b = find(~isnan(la), 1);  e = find(~isnan(la), 1, 'last');
    fprintf('  %-22s %d %6.2fN %5.2fE -> %d %6.2fN %5.2fE  %4.0f km\n', v, years(b), la(b), lo(b), ...
        years(e), la(e), lo(e), haversine_km(la(b), lo(b), la(e), lo(e)));
end

plot_nuts(Rn, Rstat, W3, U3, Mr3, years, out);
