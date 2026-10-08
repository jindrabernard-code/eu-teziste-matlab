function G = load_nuts_geometry(version, level, cacheDir)
%LOAD_NUTS_GEOMETRY Centroids and areas of NUTS regions from GISCO (scale 1:20M).
%   G = load_nuts_geometry(2021, 3, 'data/raw/nuts') returns a table
%   code, cntr, version, lat, lon, area_km2. The result is cached as CSV,
%   the GeoJSON is downloaded only once.
%   Centre = centroid of the polygon (polyshape) in a local equirectangular
%   projection around the region; at NUTS-3 size the projection error is
%   negligible.
cacheFile = fullfile(cacheDir, sprintf('nuts%d_%d.csv', level, version));
if isfile(cacheFile)
    G = readtable(cacheFile, 'TextType', 'string');
    return
end
url = sprintf(['https://gisco-services.ec.europa.eu/distribution/v2/nuts/geojson/' ...
    'NUTS_RG_20M_%d_4326_LEVL_%d.geojson'], version, level);
js = jsondecode(webread(url, weboptions('Timeout', 120, 'ContentType', 'text')));
F = js.features;
if iscell(F), F = [F{:}]; end

n = numel(F);
code = strings(n, 1); cntr = strings(n, 1);
lat = nan(n, 1); lon = nan(n, 1); area = nan(n, 1);
ws = warning('off', 'MATLAB:polyshape:repairedBySimplify');
for i = 1:n
    code(i) = F(i).properties.NUTS_ID;
    cntr(i) = F(i).properties.CNTR_CODE;
    rings = geojson_rings(F(i).geometry.coordinates);
    allp = vertcat(rings{:});
    lat0 = mean(allp(:, 2));  lon0 = mean(allp(:, 1));
    k = cosd(lat0);
    xs = cellfun(@(r) [(r(:, 1) - lon0) * k; NaN], rings, 'UniformOutput', false);
    ys = cellfun(@(r) [r(:, 2) - lat0; NaN], rings, 'UniformOutput', false);
    ps = polyshape(vertcat(xs{:}), vertcat(ys{:}));
    [cx, cy] = centroid(ps);
    lon(i) = lon0 + cx / k;  lat(i) = lat0 + cy;
    area(i) = ps.area * 111.32 * 110.57;          % deg^2 -> km^2
end
warning(ws);
G = table(code, cntr, repmat(version, n, 1), lat, lon, area, ...
    'VariableNames', {'code', 'cntr', 'version', 'lat', 'lon', 'area_km2'});
writetable(G, cacheFile);
end
