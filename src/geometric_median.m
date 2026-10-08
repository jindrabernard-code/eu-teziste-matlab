function [lat, lon] = geometric_median(latDeg, lonDeg, w, tol)
%GEOMETRIC_MEDIAN Weighted geometric median (Weber point) on a sphere.
%   The point minimising the sum of weighted great-circle distances, i.e.
%   where to put a "capital" so that the weighted population is closest to
%   it in total. Unlike the centroid it is not pulled by a few remote points.
%   Weiszfeld iteration in 3D: x <- normalize(sum w_i p_i / d_i).
if nargin < 4, tol = 1e-10; end
w = w(:) / sum(w(:));
la = deg2rad(latDeg(:));  lo = deg2rad(lonDeg(:));
P = [cos(la).*cos(lo), cos(la).*sin(lo), sin(la)];
x = w' * P;  x = x / norm(x);                     % start at the centroid
for it = 1:1000
    d = acos(min(1, P * x'));                      % angular distance
    at = d < 1e-12;                                % x sits on a data point
    T = (w(~at) ./ d(~at))' * P(~at, :);
    if any(at)
        % Vardi-Zhang: leave a data point only if the pull of the other
        % points outweighs its own weight (otherwise it is the optimum).
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
