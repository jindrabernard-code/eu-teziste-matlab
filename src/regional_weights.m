function [W, reg, proxyUsed, verUsed] = regional_weights(T, G, countries, years, M, natTot, Tproxy, refVer)
%REGIONAL_WEIGHTS Distribute a national metric over NUTS regions.
%   T      long Eurostat table (geo, year, value) with all NUTS levels
%   G      table of regions (load_nuts_geometry, several NUTS versions stacked)
%   natTot [years x countries] fallback national totals (NaN = unknown), e.g.
%          GDP from nama_10_gdp where regional data are not out yet
%   Tproxy optional table of another metric (typically population) used to
%          split the national total when a country has no regional data at
%          all (UK: Eurostat dropped its GDP and employment from the regional
%          accounts)
%   refVer [years x countries] NUTS version the country must use in that
%          year (NaN = any). Composites need every metric on the same
%          partition, otherwise a region missing in one metric would get
%          zero in the geometric mean. If the metric has no data in that
%          version, the proxy is used.
%   Output W [years x regions], reg (rows of G that were used), proxyUsed
%   (codes of countries where the proxy was used) and verUsed [years x countries].
%
%   Eurostat regional series have gaps and region codes change between
%   NUTS versions. So for every country and year:
%     1. national total = the country's row in T, else natTot, else the
%        sum of its regions
%     2. split within the country = regional shares from the nearest year
%        with complete coverage for some NUTS version (newer preferred)
%     3. region weight = total x share
%   Country totals therefore match national data, and an old and a new code
%   for the same territory can never be counted twice.
if nargin < 7, Tproxy = []; end
if nargin < 8 || isempty(refVer), refVer = nan(numel(years), height(countries)); end
verUsed = nan(numel(years), height(countries));
[D, dataCodes, dataYears, hasRow, rowOf] = nuts_index_data(T, G);
if ~isempty(Tproxy)
    [Dp, ~, pYears, pHas, pRow] = nuts_index_data(Tproxy, G);
end

W = zeros(numel(years), height(G));
bad = false(numel(years), 1);          % a year in which some member has no data
proxyUsed = strings(0);
for j = 1:height(countries)
    c = countries.code(j);
    [hasC, cRow] = ismember(c, dataCodes);
    for y = find(M(:, j))'
        % 1. national total
        tot = NaN;
        [~, ty] = ismember(years(y), dataYears);
        if hasC && ty > 0, tot = D(cRow, ty); end
        if isnan(tot) && ~isempty(natTot), tot = natTot(y, j); end
        % 2. split within the country
        [r, x, dist] = nuts_split(D, dataYears, hasRow, rowOf, G, c, years(y), refVer(y, j));
        if isempty(r) && ~isempty(Tproxy)
            [r, x] = nuts_split(Dp, pYears, pHas, pRow, G, c, years(y), refVer(y, j));
            dist = inf;                                % never take the total from the proxy
            if ~isempty(r), proxyUsed(end+1) = c; end %#ok<AGROW>
        end
        if isempty(r), bad(y) = true; continue, end
        if isnan(tot)
            if dist == 0, tot = sum(x); else, bad(y) = true; continue, end
        end
        W(y, r) = tot * x / sum(x);
        verUsed(y, j) = G.version(r(1));
    end
end
W(bad, :) = NaN;
proxyUsed = unique(proxyUsed);
used = any(W > 0, 1);
W = W(:, used);
reg = G(used, :);
end
