function [lat, lon] = spherical_centroid(latDeg, lonDeg, w)
%SPHERICAL_CENTROID Vážené těžiště bodů na kouli.
%   Body se převedou na jednotkové 3D vektory, zprůměrují se s vahami w
%   a výsledek se promítne zpět na povrch. Na rozdíl od prostého průměru
%   zeměpisných souřadnic nezkresluje vzdálenosti (1° délky na 35° N je
%   o 30 % delší než na 64° N).
w = w(:) / sum(w(:));
la = deg2rad(latDeg(:));  lo = deg2rad(lonDeg(:));
xyz = [cos(la).*cos(lo), cos(la).*sin(lo), sin(la)];
m = w' * xyz;
lat = rad2deg(atan2(m(3), hypot(m(1), m(2))));
lon = rad2deg(atan2(m(2), m(1)));
end
