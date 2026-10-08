function [lat, lon] = centroid_series(W, M, ptLat, ptLon)
%CENTROID_SERIES Těžiště pro každý rok (řádek W).
%   W [roky x jednotky] váhy, M stejně velká logická maska členství
%   (nečlenové se ignorují), ptLat/ptLon souřadnice jednotek.
%   Rok, kde některý člen má NaN, vrací NaN (chybí data).
nY = size(W, 1);
lat = nan(nY, 1);  lon = nan(nY, 1);
for y = 1:nY
    m = M(y, :);
    w = W(y, m);
    if ~any(m) || any(isnan(w)), continue, end
    [lat(y), lon(y)] = spherical_centroid(ptLat(m), ptLon(m), w');
end
end
