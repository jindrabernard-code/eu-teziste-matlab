function h = place_labels(gx, px, lat, lon, txt, obsLat, obsLon, fontSize)
%PLACE_LABELS Label points on geoaxes without covering lines or points.
%   gx       geoaxes
%   px       pixel mapping of the panel (geo_pixel_map)
%   lat, lon coordinates of the labelled points, txt their texts (string)
%   obsLat/obsLon the track polyline: its segments and vertices are
%            obstacles a label must not cover
%   For every label 8 directions x 3 distances from the point are tried.
%   The position with the lowest penalty wins: crossing a segment, covering
%   a point, overlapping an already placed label, sticking out of the panel.
%   Ties are broken by a shorter distance and a preference for upper right.
if nargin < 8, fontSize = 8; end
[P(:, 1), P(:, 2)] = px.toPx(lat, lon);
[O(:, 1), O(:, 2)] = px.toPx(obsLat, obsLon);
O = O(all(~isnan(O), 2), :);
segA = O(1:end-1, :);  segB = O(2:end, :);

fontPx = fontSize * 96 / 72;                      % points -> pixels
hTxt = fontPx * 1.15;
angles = [30 -30 150 -150 90 -90 0 180];          % order = preference
dists = [6 12 20];
boxes = zeros(0, 4);                              % [xmin ymin xmax ymax]
h = gobjects(numel(txt), 1);
for k = 1:numel(txt)
    wTxt = fontPx * 0.62 * strlength(txt(k)) + 2;
    best = inf;
    for d = dists
        for a = 1:numel(angles)
            c = [cosd(angles(a)), sind(angles(a))];
            anchor = P(k, :) + d * c;
            [box, ha, va] = text_box(anchor, c, wTxt, hTxt);
            pen = 0;
            in = inflate(box, 2);
            pen = pen + 100 * sum(seg_hits_box(segA, segB, in));
            pen = pen + 80 * sum(points_in_box(O, inflate(box, 4)));
            if ~isempty(boxes), pen = pen + 200 * sum(box_overlap(boxes, in)); end
            if box(1) < 0 || box(2) < 0 || box(3) > px.w || box(4) > px.h, pen = pen + 500; end
            pen = pen + 0.3 * d + 0.5 * a;
            if pen < best
                best = pen;  bestBox = box;  bestAnchor = anchor;  bestHa = ha;  bestVa = va;
            end
        end
    end
    boxes(end+1, :) = bestBox; %#ok<AGROW>
    [la, lo] = px.toGeo(bestAnchor(1), bestAnchor(2));
    h(k) = text(gx, la, lo, txt(k), 'FontSize', fontSize, 'FontWeight', 'bold', ...
        'HorizontalAlignment', bestHa, 'VerticalAlignment', bestVa, 'Tag', 'yrlabel');
end
end

function [box, ha, va] = text_box(anchor, c, w, h)
% text box for a direction: right of the point -> left-aligned, etc.
if c(1) > 0.3,      x = [anchor(1), anchor(1) + w];          ha = 'left';
elseif c(1) < -0.3, x = [anchor(1) - w, anchor(1)];          ha = 'right';
else,               x = anchor(1) + [-w w] / 2;              ha = 'center';
end
if c(2) > 0.3,      y = [anchor(2), anchor(2) + h];          va = 'bottom';
elseif c(2) < -0.3, y = [anchor(2) - h, anchor(2)];          va = 'top';
else,               y = anchor(2) + [-h h] / 2;              va = 'middle';
end
box = [x(1) y(1) x(2) y(2)];
end

function b = inflate(b, m)
b = b + [-m -m m m];
end

function tf = points_in_box(P, b)
tf = P(:, 1) >= b(1) & P(:, 1) <= b(3) & P(:, 2) >= b(2) & P(:, 2) <= b(4);
end

function tf = box_overlap(B, b)
tf = B(:, 1) < b(3) & B(:, 3) > b(1) & B(:, 2) < b(4) & B(:, 4) > b(2);
end

function tf = seg_hits_box(A, B, b)
% does segment A-B intersect box b (Liang–Barsky clipping)
tf = false(size(A, 1), 1);
for i = 1:size(A, 1)
    p0 = A(i, :);  dlt = B(i, :) - p0;
    p = [-dlt(1), dlt(1), -dlt(2), dlt(2)];
    q = [p0(1) - b(1), b(3) - p0(1), p0(2) - b(2), b(4) - p0(2)];
    t0 = 0;  t1 = 1;  ok = true;
    for j = 1:4
        if p(j) == 0
            if q(j) < 0, ok = false; break, end
        else
            t = q(j) / p(j);
            if p(j) < 0, t0 = max(t0, t); else, t1 = min(t1, t); end
            if t0 > t1, ok = false; break, end
        end
    end
    tf(i) = ok;
end
end
