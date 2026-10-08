function [lat, lon] = spherical_centroid(latDeg, lonDeg, w)
%SPHERICAL_CENTROID Weighted centroid of points on a sphere.
%   Points are converted to 3D unit vectors, averaged with weights w and the
%   result is projected back onto the surface. Unlike a plain average of
%   latitudes and longitudes this does not distort distances (one degree of
%   longitude is ~30 % longer at 35° N than at 64° N).
w = w(:) / sum(w(:));
la = deg2rad(latDeg(:));  lo = deg2rad(lonDeg(:));
xyz = [cos(la).*cos(lo), cos(la).*sin(lo), sin(la)];
m = w' * xyz;
lat = rad2deg(atan2(m(3), hypot(m(1), m(2))));
lon = rad2deg(atan2(m(2), m(1)));
end
