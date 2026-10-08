function refVer = choose_nuts_versions(Tlist, G, countries, years, M)
%CHOOSE_NUTS_VERSIONS Společná verze NUTS pro každý stát a rok.
%   Tlist je cell long tabulek metrik. Vybere se verze, ve které mají
%   metriky kompletní data v roce co nejbližším danému roku (součet
%   vzdáleností v letech přes metriky). Metrika, která nemá data v žádné
%   verzi (UK u HDP), se do součtu nepočítá. Při shodě vyhrává novější verze.
refVer = nan(numel(years), height(countries));
versions = sort(unique(G.version), 'descend')';
for k = 1:numel(Tlist)
    [D{k}, ~, dy{k}, hr{k}, ro{k}] = nuts_index_data(Tlist{k}, G); %#ok<AGROW>
end
for j = 1:height(countries)
    c = countries.code(j);
    for y = find(M(:, j))'
        cost = zeros(size(versions));
        for k = 1:numel(Tlist)
            dk = arrayfun(@(v) dist_of(D{k}, dy{k}, hr{k}, ro{k}, G, c, years(y), v), versions);
            if all(isinf(dk)), continue, end            % metrika nemá nic -> proxy
            cost = cost + min(dk, 99);                  % chybějící verze = velká penalizace
        end
        [best, ix] = min(cost);
        if best < 99 * numel(Tlist), refVer(y, j) = versions(ix); end
    end
end
end

function d = dist_of(D, dy, hr, ro, G, c, year, v)
[~, ~, d] = nuts_split(D, dy, hr, ro, G, c, year, v);
end
