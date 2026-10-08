function [lat, lon] = geometric_median(latDeg, lonDeg, w, tol)
%GEOMETRIC_MEDIAN Vážený geometrický medián (Weberův bod) na kouli.
%   Bod, který minimalizuje součet vážených vzdáleností po povrchu, tj.
%   kam umístit "hlavní město", aby to vážená populace měla v součtu
%   nejblíž. Na rozdíl od těžiště ho neodtáhne pár vzdálených bodů.
%   Weiszfeldova iterace ve 3D: x <- normalize(sum w_i p_i / d_i).
if nargin < 4, tol = 1e-10; end
w = w(:) / sum(w(:));
la = deg2rad(latDeg(:));  lo = deg2rad(lonDeg(:));
P = [cos(la).*cos(lo), cos(la).*sin(lo), sin(la)];
x = w' * P;  x = x / norm(x);                     % start v těžišti
for it = 1:1000
    d = acos(min(1, P * x'));                      % úhlová vzdálenost
    at = d < 1e-12;                                % x leží na datovém bodě
    T = (w(~at) ./ d(~at))' * P(~at, :);
    if any(at)
        % Vardi-Zhang: z datového bodu se odejde jen tehdy, když tah
        % ostatních bodů převáží jeho vlastní váhu (jinak je to optimum).
        tang = (P(~at, :) - (P(~at, :) * x') * x) ./ d(~at);
        r = norm(w(~at)' * tang);
        if r <= sum(w(at)), break, end
        T = T / sum(w(~at) ./ d(~at));
        xn = (1 - sum(w(at))/r) * T + (sum(w(at))/r) * x;
    else
        xn = T;
    end
    xn = xn / norm(xn);
    if norm(xn - x) < tol, x = xn; break, end
    x = xn;
end
lat = rad2deg(atan2(x(3), hypot(x(1), x(2))));
lon = rad2deg(atan2(x(2), x(1)));
end
