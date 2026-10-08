function px = geo_pixel_map(gx)
%GEO_PIXEL_MAP Převod lat/lon <-> pixely uvnitř geoaxes (Web Mercator).
%   Volat po drawnow, kdy už geoaxes zná skutečné limity a velikost.
pos = getpixelposition(gx);
latL = gx.LatitudeLimits;  lonL = gx.LongitudeLimits;
merc = @(la) log(tand(45 + la / 2));
imerc = @(y) 2 * atand(exp(y)) - 90;
px.w = pos(3);  px.h = pos(4);
px.toPx = @(la, lo) deal((lo - lonL(1)) / diff(lonL) * pos(3), ...
    (merc(la) - merc(latL(1))) / (merc(latL(2)) - merc(latL(1))) * pos(4));
px.toGeo = @(x, y) deal(imerc(merc(latL(1)) + y / pos(4) * (merc(latL(2)) - merc(latL(1)))), ...
    lonL(1) + x / pos(3) * diff(lonL));
end
