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
f = figure('Visible', 'off', 'Position', [100 100 1100 950]);
mp = EuMap(f, [34 71], [-11 35], true);
mp.scatter(U3.lat(sel), U3.lon(sel), sz, log10(pc), 'filled', ...
    'MarkerFaceAlpha', 0.7, 'MarkerEdgeColor', 'none', 'HandleVisibility', 'off');
colormap(mp.Ax, parula);
cb = colorbar(mp.Ax);
t = [10 15 20 30 40 60 80 120] * 1e3;
cb.Ticks = log10(t);  cb.TickLabels = compose('%dk', t / 1e3);
cb.Label.String = 'GDP in PPS per capita';
mk = {'population', 'p', 'Population centroid';  'gdp_eur', 'h', 'GDP (EUR) centroid'; ...
      'c_balanced', 'd', 'Balanced composite'};
for i = 1:size(mk, 1)
    mp.scatter(Rn.("n3_" + mk{i, 1} + "_lat")(y), Rn.("n3_" + mk{i, 1} + "_lon")(y), 220, 'k', ...
        mk{i, 2}, 'filled', 'MarkerEdgeColor', 'w', 'DisplayName', mk{i, 3});
end
mp.limits([34 71], [-11 35]);
legend(mp.Ax, 'Location', 'northwest');
title(mp.Ax, sprintf('EU NUTS-3 regions %d (size = population)', years(y)));
exportgraphics(f, fullfile(out, 'nuts3_map.png'), 'Resolution', 150);
close(f);
end
