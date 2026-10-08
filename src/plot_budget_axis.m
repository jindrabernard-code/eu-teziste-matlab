function plot_budget_axis(R, OBB, M, years, out)
%PLOT_BUDGET_AXIS Osa přerozdělení: těžiště čistých plátců a příjemců EU.
%   Vlevo mapa obou trajektorií a spojnice plátci -> příjemci ve vybraných
%   letech, vpravo vzdálenost mezi těžišti a objem přerozdělení (součet
%   kladných sald = kolik čistí příjemci dostali).
la1 = R.platci_lat;  lo1 = R.platci_lon;
la2 = R.prijemci_lat;  lo2 = R.prijemci_lon;
red = [0.80 0.20 0.15];  green = [0.15 0.55 0.25];

f = figure('Visible', 'off', 'Position', [100 100 1500 720], 'Color', 'w');
tl = tiledlayout(f, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, 'Osa přerozdělení rozpočtu EU: kam platí čistí plátci a kde jsou čistí příjemci', ...
    'FontWeight', 'bold', 'FontSize', 14);

mp = EuMap(tl, [38 56], [-4 26], true);
mp.Ax.Layout.Tile = 1;  mp.Ax.Layout.TileSpan = [2 1];
show = [2000 2004 2007 2013 2020 2025];
for y = show
    i = find(years == y);
    if isnan(la1(i)) || isnan(la2(i)), continue, end
    mp.line([la1(i) la2(i)], [lo1(i) lo2(i)], ':', 'Color', [0.35 0.35 0.35], 'LineWidth', 1, ...
        'HandleVisibility', 'off');
end
mp.line(la1, lo1, '-o', 'Color', red, 'MarkerFaceColor', red, 'MarkerSize', 3, ...
    'LineWidth', 1.8, 'DisplayName', 'Těžiště čistých plátců');
mp.line(la2, lo2, '-o', 'Color', green, 'MarkerFaceColor', green, 'MarkerSize', 3, ...
    'LineWidth', 1.8, 'DisplayName', 'Těžiště čistých příjemců');
for y = [2000 2007 2025]               % víc popisků by se v shluku plátců překrývalo
    i = find(years == y);
    mp.text(la1(i), lo1(i), "  " + y, 'FontSize', 8, 'Color', red, 'FontWeight', 'bold');
    mp.text(la2(i), lo2(i), "  " + y, 'FontSize', 8, 'Color', green, 'FontWeight', 'bold');
end
legend(mp.Ax, 'Location', 'northwest');
title(mp.Ax, 'Tečkovaně = spojnice plátci → příjemci');

ax = nexttile(tl, 2);
d = haversine_km(la1, lo1, la2, lo2);
plot(ax, years, d, '-o', 'Color', [0.2 0.2 0.2], 'LineWidth', 1.8, 'MarkerSize', 4);
grid(ax, 'on');  ylabel(ax, 'km');
title(ax, 'Vzdálenost těžiště plátců a příjemců');
xline(ax, [2004 2007 2013 2020], ':', {'EU-25', 'EU-27', 'HR', 'Brexit'});

ax = nexttile(tl, 4);
O = OBB;  O(~M) = NaN;
vol = sum(max(O, 0), 2, 'omitnan') / 1e3;
vol(all(isnan(O), 2)) = NaN;
bar(ax, years, vol, 'FaceColor', green, 'EdgeColor', 'none');
grid(ax, 'on');  ylabel(ax, 'mld. EUR');
title(ax, 'Objem přerozdělení (součet čistých pozic příjemců, bez NGEU)');
exportgraphics(f, fullfile(out, 'rozpocet_osa.png'), 'Resolution', 130);
close(f);
end
