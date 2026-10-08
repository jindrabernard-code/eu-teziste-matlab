function H = tracks_figure(T, series, ttl, figWidth)
%TRACKS_FIGURE Build the centroid-shift figure (EU overview + one zoomed panel per series).
%   Draws no data yet: tracks_set_year(H, year) fills it "up to a year", so
%   the same figure serves the static map and every animation frame.
%   T      table with a year column and <prefix>_lat / <prefix>_lon columns
%   series cell {label, prefix} or {label, prefix, ownExtent}: a series
%          with ownExtent = true gets its own zoom (it is much longer than
%          the others, e.g. net receivers of the EU budget) and is left out
%          of the shared zoom of the other panels
%   The overview is an EuMap (EU members in blue), the panels are geoaxes
%   on the 'grayland' basemap (no highlighting, so the tracks stand out).
if nargin < 4, figWidth = 1900; end
H.years = T.year;
H.ttl = ttl;
n = size(series, 1);
H.n = n;
H.labels = series(:, 1);
H.cmap = turbo(256);
for i = 1:n
    H.la{i} = T.(series{i, 2} + "_lat");
    H.lo{i} = T.(series{i, 2} + "_lon");
end
countries = readtable(fullfile(EuMap.root(), 'data', 'countries.csv'), 'TextType', 'string');
H.codes = countries.code;
H.member = is_member(countries, H.years);

% shared zoom for all panels, so that shifts are comparable
H.own = false(1, n);
if size(series, 2) >= 3, H.own = cellfun(@(x) isequal(x, true), series(:, 3))'; end
[H.latLim, H.lonLim] = extent(H.la(~H.own), H.lo(~H.own));
H.panelLat = repmat({H.latLim}, 1, n);  H.panelLon = repmat({H.lonLim}, 1, n);
H.labelKm = 25 * ones(1, n);          % jump threshold for a year label (km), see tracks_set_year
for i = find(H.own)
    [H.panelLat{i}, H.panelLon{i}] = extent(H.la(i), H.lo(i));
    H.labelKm(i) = 25 * max(1, diff(H.panelLon{i}) / diff(H.lonLim));
end

nCol = 4;  nRow = 2 + ceil(max(n - 4, 0) / nCol);
H.fig = figure('Visible', 'off', 'Position', [50 50 figWidth 430 * nRow * figWidth / 1900], 'Color', 'w');
H.tl = tiledlayout(H.fig, nRow, nCol, 'TileSpacing', 'compact', 'Padding', 'compact');
title(H.tl, ttl, 'FontWeight', 'bold', 'FontSize', 16);

% EU overview
H.map = EuMap(H.tl, [34 71], [-11 35], true);
H.map.Ax.Layout.Tile = 1;  H.map.Ax.Layout.TileSpan = [2 2];
H.cols = [lines(7); 0 0 0; 0.5 0.5 0.5; 0.6 0.3 0.1; 0.2 0.6 0.6; 0.8 0.5 0.8; 0.4 0.4 0.9];
for i = 1:n
    H.ovLine(i) = H.map.line(NaN, NaN, '-', 'Color', H.cols(i, :), 'LineWidth', 2, ...
        'DisplayName', series{i, 1});
end
for i = 1:n
    H.ovPt(i) = H.map.scatter(NaN, NaN, 36, H.cols(i, :), 'filled', ...
        'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
end
H.map.line(H.latLim([1 2 2 1 1]), H.lonLim([1 1 2 2 1]), 'k--', 'LineWidth', 1, 'HandleVisibility', 'off');
legend(H.map.Ax, 'Location', 'northwest', 'FontSize', 8);
title(H.map.Ax, 'EU overview (dashed = zoom used in the panels)');

% zoomed panels, one per series
free = setdiff(1:nRow * nCol, [1 2 nCol+1 nCol+2]);
span = [1 1];
if n <= 2, free = [3 4];  span = [2 1]; end    % two series: panels span both rows
for i = 1:n
    gx = geoaxes(H.tl);  gx.Layout.Tile = free(i);  gx.Layout.TileSpan = span;
    try, geobasemap(gx, 'grayland'); catch, geobasemap(gx, 'darkwater'); end
    hold(gx, 'on');
    geolimits(gx, H.panelLat{i}, H.panelLon{i});
    gx.Scalebar.Visible = 'off';
    gx.LatitudeLabel.String = '';  gx.LongitudeLabel.String = '';
    la = H.la{i};  lo = H.lo{i};
    seg = gobjects(0);  segYear = [];
    ok = find(~isnan(la));
    for s = 1:numel(ok) - 1
        a = ok(s);  b = ok(s + 1);
        seg(end+1) = geoplot(gx, la([a b]), lo([a b]), '-', 'Color', yr2col(H, H.years(b)), ...
            'LineWidth', 2.2, 'Visible', 'off'); %#ok<AGROW>
        segYear(end+1) = H.years(b); %#ok<AGROW>
    end
    H.seg{i} = seg;  H.segYear{i} = segYear;
    H.pts(i) = geoscatter(gx, NaN, NaN, 28, NaN, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.3);
    H.cur(i) = geoscatter(gx, NaN, NaN, 140, 'k', 'LineWidth', 1.8);   % current year
    colormap(gx, H.cmap);  clim(gx, [H.years(1) H.years(end)]);
    H.gx(i) = gx;
end
cb = colorbar(H.gx(end));  cb.Label.String = 'year';
% pixel mapping for label placement (only once the layout is drawn)
drawnow;
for i = 1:n, H.px{i} = geo_pixel_map(H.gx(i)); end
end

function [latLim, lonLim] = extent(la, lo)
LA = vertcat(la{:});  LO = vertcat(lo{:});
pad = 0.35 + 0.05 * (max(LO) - min(LO));
latLim = [min(LA) max(LA)] + [-pad pad];
lonLim = [min(LO) max(LO)] + [-pad pad] * 1.5;
end

function c = yr2col(H, y)
c = H.cmap(round(1 + 255 * (y - H.years(1)) / (H.years(end) - H.years(1))), :);
end
