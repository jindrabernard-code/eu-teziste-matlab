function rings = geojson_rings(c)
%GEOJSON_RINGS Kruhy (Multi)Polygonu z jsondecode.
% jsondecode vrací souřadnice (Multi)Polygonu buď jako numerické pole
% [... x N x 2] (když mají kruhy stejnou délku), nebo jako vnořené cell.
% Výsledek: cell sloupcových matic [lon lat], jedna na kruh.
if iscell(c)
    rings = {};
    for j = 1:numel(c), rings = [rings, geojson_rings(c{j})]; end %#ok<AGROW>
    return
end
sz = size(c);
if numel(sz) == 2 && sz(2) == 2                   % jediný kruh N x 2
    rings = {c};
    return
end
npts = sz(end - 1);
X = reshape(c, [], npts, 2);
rings = cell(1, size(X, 1));
for r = 1:size(X, 1), rings{r} = reshape(X(r, :, :), npts, 2); end
end
