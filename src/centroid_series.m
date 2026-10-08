function [lat, lon] = centroid_series(W, M, ptLat, ptLon, method)
%CENTROID_SERIES Centroid for every year (row of W).
%   W [years x units] weights, M logical membership mask of the same size
%   (non-members are ignored), ptLat/ptLon coordinates of the units.
%   A year in which any member has NaN returns NaN (missing data).
%   method: 'mean' (centroid, default) or 'median' (geometric median).
if nargin < 5, method = 'mean'; end
nY = size(W, 1);
lat = nan(nY, 1);  lon = nan(nY, 1);
for y = 1:nY
    m = M(y, :);
    w = W(y, m);
    if ~any(m) || any(isnan(w)), continue, end
    if strcmp(method, 'median')
        [lat(y), lon(y)] = geometric_median(ptLat(m), ptLon(m), w');
    else
        [lat(y), lon(y)] = spherical_centroid(ptLat(m), ptLon(m), w');
    end
end
end
