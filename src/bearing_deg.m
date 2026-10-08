function b = bearing_deg(lat1, lon1, lat2, lon2)
%BEARING_DEG Počáteční azimut z bodu 1 do bodu 2 (0 = sever, 90 = východ).
p1 = deg2rad(lat1); p2 = deg2rad(lat2); dl = deg2rad(lon2 - lon1);
b = mod(rad2deg(atan2(sin(dl).*cos(p2), cos(p1).*sin(p2) - sin(p1).*cos(p2).*cos(dl))), 360);
end
