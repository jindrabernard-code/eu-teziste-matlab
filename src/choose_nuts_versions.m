function refVer = choose_nuts_versions(Tlist, G, countries, years, M)
%CHOOSE_NUTS_VERSIONS One shared NUTS version per country and year.
%   Tlist is a cell array of long tables, one per metric. The chosen version
%   is the one in which the metrics have complete data in a year as close
%   as possible to the given year (sum of distances in years over metrics).
%   A metric with no data in any version (UK GDP) is left out of the sum.
%   On a tie the newer version wins.
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
            if all(isinf(dk)), continue, end            % metric has nothing -> proxy
            cost = cost + min(dk, 99);                  % missing version = large penalty
        end
        [best, ix] = min(cost);
        if best < 99 * numel(Tlist), refVer(y, j) = versions(ix); end
    end
end
end

function d = dist_of(D, dy, hr, ro, G, c, year, v)
[~, ~, d] = nuts_split(D, dy, hr, ro, G, c, year, v);
end
