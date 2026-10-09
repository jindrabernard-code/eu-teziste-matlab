function plot_results(R, names, years, out)
%PLOT_RESULTS Map of centroid tracks + longitude/latitude time series.
cols = [lines(7); 0 0 0; 0.55 0.55 0.55; 0.6 0.3 0.1];   % lines() has only 7 colours
cols = cols(1:numel(names), :);
labels = metric_labels();

% 1) map
f = figure('Visible', 'off', 'Position', [100 100 1100 800]);
mp = EuMap(f, [34 71], [-11 35], false, 'plain');   % grey countries, no EU highlight
for i = 1:numel(names)
    la = R.(names(i) + "_lat");  lo = R.(names(i) + "_lon");
    mp.line(la, lo, '-', 'Color', cols(i, :), 'LineWidth', 1.8, ...
        'DisplayName', labels.(names(i)));
    first = find(~isnan(la), 1);  last = find(~isnan(la), 1, 'last');
    mp.scatter(la(first), lo(first), 30, cols(i, :), 'o', 'HandleVisibility', 'off');
    mp.scatter(la(last),  lo(last),  50, cols(i, :), 'filled', 'HandleVisibility', 'off');
end
mp.limits([46.5 52], [5 17]);
legend(mp.Ax, 'Location', 'southoutside', 'NumColumns', 4);
title(mp.Ax, sprintf('EU centroid %d–%d by metric (ring = %d, filled dot = last year)', ...
    years(1), years(end), years(1)));
exportgraphics(f, fullfile(out, 'centroid_map.png'), 'Resolution', 150);
close(f);

% 2) longitude and latitude over time
f = figure('Visible', 'off', 'Position', [100 100 1100 700]);
tl = tiledlayout(f, 2, 1, 'TileSpacing', 'compact');
for p = 1:2
    ax = nexttile(tl);  hold(ax, 'on');  grid(ax, 'on');
    suffix = ["_lon" "_lat"];
    for i = 1:numel(names)
        plot(ax, years, R.(names(i) + suffix(p)), '-', 'Color', cols(i, :), ...
            'LineWidth', 1.6, 'DisplayName', labels.(names(i)));
    end
    xline(ax, [2004 2007 2013 2020], ':', {'EU-25', 'EU-27', 'HR', 'Brexit'}, ...
        'HandleVisibility', 'off');
    ylabels = ["Longitude (°E)" "Latitude (°N)"];
    ylabel(ax, ylabels(p));
end
legend(ax, 'Location', 'southoutside', 'NumColumns', 4);
xlabel(tl, 'Year');
exportgraphics(f, fullfile(out, 'time_series.png'), 'Resolution', 150);
close(f);
end
