function plot_results(R, names, years, out)
%PLOT_RESULTS Mapa trajektorií těžišť + časové řady zeměpisné délky.
cols = [lines(7); 0 0 0];                 % lines() má jen 7 barev, 8. metrika černě
cols = cols(1:numel(names), :);
labels = struct('staty', 'Státy (1:1)', 'plocha', 'Plocha', 'populace', 'Populace', ...
    'ep', 'Mandáty EP', 'hdp_eur', 'HDP (EUR)', 'hdp_pps', 'HDP (PPS)', ...
    'rada_hlasy', 'Hlasy v Radě', 'rada_sila', 'Banzhafova síla v Radě');

% 1) mapa
f = figure('Visible', 'off', 'Position', [100 100 1100 800]);
mp = EuMap(f, [34 71], [-11 35], true);
for i = 1:numel(names)
    la = R.(names(i) + "_lat");  lo = R.(names(i) + "_lon");
    mp.line(la, lo, '-', 'Color', cols(i, :), 'LineWidth', 1.8, ...
        'DisplayName', labels.(names(i)));
    first = find(~isnan(la), 1);  last = find(~isnan(la), 1, 'last');
    mp.scatter(la(first), lo(first), 30, cols(i, :), 'o', 'HandleVisibility', 'off');
    mp.scatter(la(last),  lo(last),  50, cols(i, :), 'filled', 'HandleVisibility', 'off');
end
mp.limits([46.5 52], [6 17]);
legend(mp.Ax, 'Location', 'southoutside', 'NumColumns', 4);
title(mp.Ax, sprintf('Těžiště EU %d–%d (kroužek = %d, plný bod = konec)', ...
    years(1), years(end), years(1)));
exportgraphics(f, fullfile(out, 'mapa_teziste.png'), 'Resolution', 150);
close(f);

% 2) zeměpisná délka a šířka v čase
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
    ylabels = ["Zeměpisná délka (°E)" "Zeměpisná šířka (°N)"];
    ylabel(ax, ylabels(p));
end
legend(ax, 'Location', 'southoutside', 'NumColumns', 4);
xlabel(tl, 'Rok');
exportgraphics(f, fullfile(out, 'casove_rady.png'), 'Resolution', 150);
close(f);
end
