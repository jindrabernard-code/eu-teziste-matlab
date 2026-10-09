function plot_nuts(Rn, Rstat, W3, U3, Mr3, years, out)
%PLOT_NUTS Resolution comparison (state / NUTS-2 / NUTS-3) and a map of NUTS-3 regions.

% 1) tracks by resolution
f = figure('Visible', 'off', 'Position', [100 100 1100 800]);
mp = EuMap(f, [34 71], [-11 35], true);
cols = lines(4);
series = {   % label, lat, lon, colour, line style
    'Population – states',  Rstat.population_lat, Rstat.population_lon, cols(1, :), ':'
    'Population – NUTS-2',  Rn.n2_population_lat, Rn.n2_population_lon, cols(1, :), '--'
    'Population – NUTS-3',  Rn.n3_population_lat, Rn.n3_population_lon, cols(1, :), '-'
    'GDP EUR – states',     Rstat.gdp_eur_lat,    Rstat.gdp_eur_lon,    cols(2, :), ':'
    'GDP EUR – NUTS-2',     Rn.n2_gdp_eur_lat,    Rn.n2_gdp_eur_lon,    cols(2, :), '--'
    'GDP EUR – NUTS-3',     Rn.n3_gdp_eur_lat,    Rn.n3_gdp_eur_lon,    cols(2, :), '-'
    'Balanced composite – NUTS-3', Rn.n3_c_balanced_lat, Rn.n3_c_balanced_lon, cols(3, :), '-'
    'Population median – NUTS-3',  Rn.n3_population_median_lat, Rn.n3_population_median_lon, cols(4, :), '-'
};
for i = 1:size(series, 1)
    la = series{i, 2};  lo = series{i, 3};
    mp.line(la, lo, series{i, 5}, 'Color', series{i, 4}, 'LineWidth', 1.8, 'DisplayName', series{i, 1});
    e = find(~isnan(la), 1, 'last');
    mp.scatter(la(e), lo(e), 45, series{i, 4}, 'filled', 'HandleVisibility', 'off');
end
mp.limits([46.5 52], [4.5 13]);
legend(mp.Ax, 'Location', 'southoutside', 'NumColumns', 3);
title(mp.Ax, 'Effect of resolution: states vs. NUTS-2 vs. NUTS-3 (filled dot = last year)');
exportgraphics(f, fullfile(out, 'nuts_resolution.png'), 'Resolution', 150);
close(f);

% 2) NUTS-3 regions in the last year with GDP: size = population, colour = GDP PPS per capita
y = find(all(~isnan(W3.gdp_pps), 2) & all(~isnan(W3.population), 2), 1, 'last');
sel = Mr3(y, :) & W3.population(y, :) > 0 & W3.gdp_pps(y, :) > 0;
pc = W3.gdp_pps(y, sel) ./ W3.population(y, sel) * 1e6;      % PPS per capita
sz = 4 + 400 * W3.population(y, sel) / max(W3.population(y, sel));
% centres of the three key metrics in that year
mk = {'population', [0.85 0.10 0.10], 'Population centroid'
      'gdp_eur',    [0 0 0],          'GDP (EUR) centroid'
      'c_balanced', [0.80 0.00 0.80], 'Balanced composite centroid'};
cla_ = arrayfun(@(i) Rn.("n3_" + mk{i, 1} + "_lat")(y), 1:size(mk, 1));
clo_ = arrayfun(@(i) Rn.("n3_" + mk{i, 1} + "_lon")(y), 1:size(mk, 1));
% the centres are only a few pixels apart on a map of Europe, so they are
% shown in a zoomed panel on the right; the left map marks the zoom
zLat = mean(cla_) + [-1.6 1.6];  zLon = mean(clo_) + [-2.6 2.6];

f = figure('Visible', 'off', 'Position', [100 100 1500 900], 'Color', 'w');
tl = tiledlayout(f, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, sprintf('EU NUTS-3 regions %d (bubble size = population, colour = GDP in PPS per capita)', ...
    years(y)), 'FontWeight', 'bold', 'FontSize', 14);
t = [10 15 20 30 40 60 80 120] * 1e3;

mp = EuMap(tl, [34 71], [-11 35], true);
mp.Ax.Layout.Tile = 1;
draw_regions(mp, U3.lat(sel), U3.lon(sel), sz, log10(pc), t);
mp.line(zLat([1 2 2 1 1]), zLon([1 1 2 2 1]), 'k--', 'LineWidth', 1.2, 'DisplayName', 'Zoom (right panel)');
legend(mp.Ax, 'Location', 'northwest');
title(mp.Ax, 'All NUTS-3 regions');

mz = EuMap(tl, zLat, zLon, false);
mz.Ax.Layout.Tile = 2;
inZ = U3.lat(sel) > zLat(1) - 1 & U3.lat(sel) < zLat(2) + 1 & U3.lon(sel) > zLon(1) - 1 & U3.lon(sel) < zLon(2) + 1;
s3 = sz(inZ);  pcz = pc(inZ);  la3 = U3.lat(sel);  lo3 = U3.lon(sel);
draw_regions(mz, la3(inZ), lo3(inZ), s3, log10(pcz), t);
cb = colorbar(mz.Ax);
cb.Ticks = log10(t);  cb.TickLabels = compose('%dk', t / 1e3);
cb.Label.String = 'GDP in PPS per capita';
% coloured crosses with a white halo (contrast against the blue countries
% and the bubbles); the size is chosen from the pixel distance of the
% closest pair so that the crosses never overlap
drawnow;
pos = getpixelposition(mz.Ax);
scale = min(pos(3) / diff(mz.Ax.XLim), pos(4) / diff(mz.Ax.YLim));   % axis equal
P = [clo_' * EuMap.K, cla_'] * scale;
D = squareform_min(P);
msPx = min(22, 0.6 * D);                                  % cross size in px
ms = msPx * 72 / 96;                                      % px -> points
for i = 1:size(mk, 1)
    mz.line(cla_(i), clo_(i), '+', 'Color', 'w', 'MarkerSize', ms, 'LineWidth', 6, ...
        'HandleVisibility', 'off');
    mz.line(cla_(i), clo_(i), '+', 'Color', mk{i, 2}, 'MarkerSize', ms, 'LineWidth', 2.6, ...
        'DisplayName', mk{i, 3});
end
legend(mz.Ax, 'Location', 'southoutside');
title(mz.Ax, 'Zoom: centres of population, GDP and the balanced composite');
fprintf('NUTS-3 map: closest centres %.1f px apart in the zoom, cross size %.1f px\n', D, msPx);
exportgraphics(f, fullfile(out, 'nuts3_map.png'), 'Resolution', 150);
close(f);
end

function draw_regions(m, la, lo, sz, c, t)
% NUTS-3 regions as bubbles coloured by log GDP per capita
m.scatter(la, lo, sz, c, 'filled', 'MarkerFaceAlpha', 0.7, 'MarkerEdgeColor', 'none', ...
    'HandleVisibility', 'off');
colormap(m.Ax, parula);
clim(m.Ax, log10(t([1 end])));
end

function d = squareform_min(P)
% smallest distance between any two rows of P
d = inf;
for i = 1:size(P, 1) - 1
    for j = i + 1:size(P, 1)
        d = min(d, norm(P(i, :) - P(j, :)));
    end
end
end
