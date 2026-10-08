function H = tracks_figure(T, series, ttl, figWidth)
%TRACKS_FIGURE Sestaví obrázek posunů těžiště (přehled EU + výřezy po řadách).
%   Nic nevykreslí "do roku": data se doplní přes tracks_set_year(H, rok),
%   takže stejný obrázek slouží pro statickou mapu i pro animaci.
%   T      tabulka se sloupcem year a sloupci <prefix>_lat / <prefix>_lon
%   series cell {popisek, prefix}
%   Přehled je EuMap (státy EU modře), výřezy jsou geoaxes s podkladem
%   grayland (bez zvýraznění států, ať trajektorie vyniknou).
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

% společný výřez pro všechny panely, ať jsou posuny srovnatelné
LA = vertcat(H.la{:});  LO = vertcat(H.lo{:});
pad = 0.35;
H.latLim = [min(LA) max(LA)] + [-pad pad];
H.lonLim = [min(LO) max(LO)] + [-pad pad] * 1.5;

nCol = 4;  nRow = 2 + ceil(max(n - 4, 0) / nCol);
H.fig = figure('Visible', 'off', 'Position', [50 50 figWidth 430 * nRow * figWidth / 1900], 'Color', 'w');
H.tl = tiledlayout(H.fig, nRow, nCol, 'TileSpacing', 'compact', 'Padding', 'compact');
title(H.tl, ttl, 'FontWeight', 'bold', 'FontSize', 16);

% přehled EU
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
title(H.map.Ax, 'Přehled EU (čárkovaně = výřez v panelech)');

% výřezy po řadách
free = setdiff(1:nRow * nCol, [1 2 nCol+1 nCol+2]);
for i = 1:n
    gx = geoaxes(H.tl);  gx.Layout.Tile = free(i);
    try, geobasemap(gx, 'grayland'); catch, geobasemap(gx, 'darkwater'); end
    hold(gx, 'on');
    geolimits(gx, H.latLim, H.lonLim);
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
    H.cur(i) = geoscatter(gx, NaN, NaN, 140, 'k', 'LineWidth', 1.8);   % aktuální rok
    colormap(gx, H.cmap);  clim(gx, [H.years(1) H.years(end)]);
    H.gx(i) = gx;
end
cb = colorbar(H.gx(end));  cb.Label.String = 'rok';
% převod na pixely pro rozmisťování popisků (až po vykreslení rozvržení)
drawnow;
for i = 1:n, H.px{i} = geo_pixel_map(H.gx(i)); end
end

function c = yr2col(H, y)
c = H.cmap(round(1 + 255 * (y - H.years(1)) / (H.years(end) - H.years(1))), :);
end
