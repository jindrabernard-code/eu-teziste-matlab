function [r, x, bestDist] = nuts_split(D, dataYears, hasRow, rowOf, G, c, year, onlyVer)
%NUTS_SPLIT Regions of country c and their values from the nearest year with full coverage.
%   Searches the NUTS versions (only onlyVer unless it is NaN) for the year
%   closest to `year` in which every region of the country has data. On a
%   tie in distance the newer version wins.
r = [];  x = [];  bestDist = inf;
vs = sort(unique(G.version), 'descend')';
if ~isnan(onlyVer), vs = onlyVer; end
for v = vs
    rv = find(G.cntr == c & G.version == v);
    if isempty(rv) || ~all(hasRow(rv)), continue, end
    full = all(~isnan(D(rowOf(rv), :)), 1);
    yrs = dataYears(full);
    if isempty(yrs), continue, end
    [dist, ix] = min(abs(yrs - year));
    if dist < bestDist
        bestDist = dist;  r = rv;  x = D(rowOf(rv), dataYears == yrs(ix));
    end
end
end
