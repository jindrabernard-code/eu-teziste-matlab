function rings = geojson_rings(c)
%GEOJSON_RINGS Rings of a (Multi)Polygon decoded by jsondecode.
% jsondecode returns (Multi)Polygon coordinates either as a numeric array
% [... x N x 2] (when all rings have the same length) or as nested cells.
% Result: cell of column matrices [lon lat], one per ring.
if iscell(c)
    rings = {};
    for j = 1:numel(c), rings = [rings, geojson_rings(c{j})]; end %#ok<AGROW>
    return
end
sz = size(c);
if numel(sz) == 2 && sz(2) == 2                   % a single N x 2 ring
    rings = {c};
    return
end
npts = sz(end - 1);
X = reshape(c, [], npts, 2);
rings = cell(1, size(X, 1));
for r = 1:size(X, 1), rings{r} = reshape(X(r, :, :), npts, 2); end
end
