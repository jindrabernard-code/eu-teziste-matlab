function [r, x, bestDist] = nuts_split(D, dataYears, hasRow, rowOf, G, c, year, onlyVer)
%NUTS_SPLIT Regiony státu c a jejich hodnoty z nejbližšího roku, kdy je pro některou
% verzi NUTS pokrytí kompletní. Při shodě vzdálenosti vyhrává novější verze.
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
