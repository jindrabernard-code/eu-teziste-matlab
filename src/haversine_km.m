function d = haversine_km(lat1, lon1, lat2, lon2)
%HAVERSINE_KM Great-circle distance in km (spherical Earth, R = 6371 km).
R = 6371;
p1 = deg2rad(lat1); p2 = deg2rad(lat2);
dp = p2 - p1; dl = deg2rad(lon2 - lon1);
a = sin(dp/2).^2 + cos(p1).*cos(p2).*sin(dl/2).^2;
d = 2*R*asin(sqrt(a));
end
