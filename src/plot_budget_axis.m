function plot_budget_axis(R, OBB, M, years, out)
%PLOT_BUDGET_AXIS Redistribution axis: centroids of EU net payers and net receivers.
%   Left: map of both tracks with payer -> receiver connectors in selected
%   years. Right: distance between the two centroids and the volume of
%   redistribution (sum of positive balances = what net receivers got).
la1 = R.net_payers_lat;     lo1 = R.net_payers_lon;
la2 = R.net_receivers_lat;  lo2 = R.net_receivers_lon;
red = [0.80 0.20 0.15];  green = [0.15 0.55 0.25];

f = figure('Visible', 'off', 'Position', [100 100 1500 720], 'Color', 'w');
tl = tiledlayout(f, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, 'EU budget redistribution axis: where net payers pay from and where net receivers are', ...
    'FontWeight', 'bold', 'FontSize', 14);

mp = EuMap(tl, [38 56], [-4 26], true);
mp.Ax.Layout.Tile = 1;  mp.Ax.Layout.TileSpan = [2 1];
for y = [2000 2004 2007 2013 2020 2025]
    i = find(years == y);
    if isnan(la1(i)) || isnan(la2(i)), continue, end
    mp.line([la1(i) la2(i)], [lo1(i) lo2(i)], ':', 'Color', [0.35 0.35 0.35], 'LineWidth', 1, ...
        'HandleVisibility', 'off');
end
mp.line(la1, lo1, '-o', 'Color', red, 'MarkerFaceColor', red, 'MarkerSize', 3, ...
    'LineWidth', 1.8, 'DisplayName', 'Net payers centroid');
mp.line(la2, lo2, '-o', 'Color', green, 'MarkerFaceColor', green, 'MarkerSize', 3, ...
    'LineWidth', 1.8, 'DisplayName', 'Net receivers centroid');
for y = [2000 2007 2025]               % more labels would overlap in the payers' cluster
    i = find(years == y);
    mp.text(la1(i), lo1(i), "  " + y, 'FontSize', 8, 'Color', red, 'FontWeight', 'bold');
    mp.text(la2(i), lo2(i), "  " + y, 'FontSize', 8, 'Color', green, 'FontWeight', 'bold');
end
legend(mp.Ax, 'Location', 'northwest');
title(mp.Ax, 'Dotted = payers → receivers connector');

ax = nexttile(tl, 2);
d = haversine_km(la1, lo1, la2, lo2);
plot(ax, years, d, '-o', 'Color', [0.2 0.2 0.2], 'LineWidth', 1.8, 'MarkerSize', 4);
grid(ax, 'on');  ylabel(ax, 'km');
title(ax, 'Distance between the payers'' and receivers'' centroids');
xline(ax, [2004 2007 2013 2020], ':', {'EU-25', 'EU-27', 'HR', 'Brexit'});

ax = nexttile(tl, 4);
O = OBB;  O(~M) = NaN;
vol = sum(max(O, 0), 2, 'omitnan') / 1e3;
vol(all(isnan(O), 2)) = NaN;
bar(ax, years, vol, 'FaceColor', green, 'EdgeColor', 'none');
grid(ax, 'on');  ylabel(ax, 'EUR billion');
title(ax, 'Volume of redistribution (sum of net receivers'' balances, excl. NGEU)');
exportgraphics(f, fullfile(out, 'budget_axis.png'), 'Resolution', 130);
close(f);
end
