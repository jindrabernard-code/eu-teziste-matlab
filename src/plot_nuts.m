function plot_nuts(Rn, Rstat, W3, U3, Mr3, years, out)
%PLOT_NUTS Srovnání rozlišení (stát / NUTS-2 / NUTS-3) a mapa regionů NUTS-3.

% 1) trajektorie podle rozlišení
f = figure('Visible', 'off', 'Position', [100 100 1100 800]);
mp = EuMap(f, [34 71], [-11 35], true);
cols = lines(4);
series = {   % popisek, lat, lon, barva, styl
    'Populace – státy',   Rstat.populace_lat, Rstat.populace_lon, cols(1, :), ':'
    'Populace – NUTS-2',  Rn.n2_populace_lat, Rn.n2_populace_lon, cols(1, :), '--'
    'Populace – NUTS-3',  Rn.n3_populace_lat, Rn.n3_populace_lon, cols(1, :), '-'
    'HDP EUR – státy',    Rstat.hdp_eur_lat,  Rstat.hdp_eur_lon,  cols(2, :), ':'
    'HDP EUR – NUTS-2',   Rn.n2_hdp_eur_lat,  Rn.n2_hdp_eur_lon,  cols(2, :), '--'
    'HDP EUR – NUTS-3',   Rn.n3_hdp_eur_lat,  Rn.n3_hdp_eur_lon,  cols(2, :), '-'
    'Vyvážený kompozit – NUTS-3', Rn.n3_k_vyvazeny_lat, Rn.n3_k_vyvazeny_lon, cols(3, :), '-'
    'Populace – medián NUTS-3',   Rn.n3_populace_median_lat, Rn.n3_populace_median_lon, cols(4, :), '-'
};
for i = 1:size(series, 1)
    la = series{i, 2};  lo = series{i, 3};
    mp.line(la, lo, series{i, 5}, 'Color', series{i, 4}, 'LineWidth', 1.8, 'DisplayName', series{i, 1});
    e = find(~isnan(la), 1, 'last');
    mp.scatter(la(e), lo(e), 45, series{i, 4}, 'filled', 'HandleVisibility', 'off');
end
mp.limits([46.5 52], [4.5 13]);
legend(mp.Ax, 'Location', 'southoutside', 'NumColumns', 3);
title(mp.Ax, 'Vliv rozlišení: státy vs. NUTS-2 vs. NUTS-3 (plný bod = poslední rok)');
exportgraphics(f, fullfile(out, 'nuts_srovnani.png'), 'Resolution', 150);
close(f);

% 2) regiony NUTS-3 v posledním roce s HDP: velikost = populace, barva = HDP PPS / obyv.
y = find(all(~isnan(W3.hdp_pps), 2) & all(~isnan(W3.populace), 2), 1, 'last');
sel = Mr3(y, :) & W3.populace(y, :) > 0 & W3.hdp_pps(y, :) > 0;
pc = W3.hdp_pps(y, sel) ./ W3.populace(y, sel) * 1e6;      % PPS na obyvatele
sz = 4 + 400 * W3.populace(y, sel) / max(W3.populace(y, sel));
f = figure('Visible', 'off', 'Position', [100 100 1100 950]);
mp = EuMap(f, [34 71], [-11 35], true);
mp.scatter(U3.lat(sel), U3.lon(sel), sz, log10(pc), 'filled', ...
    'MarkerFaceAlpha', 0.7, 'MarkerEdgeColor', 'none', 'HandleVisibility', 'off');
colormap(mp.Ax, parula);
cb = colorbar(mp.Ax);
t = [10 15 20 30 40 60 80 120] * 1e3;
cb.Ticks = log10(t);  cb.TickLabels = compose('%d tis.', t / 1e3);
cb.Label.String = 'HDP v PPS na obyvatele';
mk = {'populace', 'p', 'Těžiště populace';  'hdp_eur', 'h', 'Těžiště HDP (EUR)'; ...
      'k_vyvazeny', 'd', 'Vyvážený kompozit'};
for i = 1:size(mk, 1)
    mp.scatter(Rn.("n3_" + mk{i, 1} + "_lat")(y), Rn.("n3_" + mk{i, 1} + "_lon")(y), 220, 'k', ...
        mk{i, 2}, 'filled', 'MarkerEdgeColor', 'w', 'DisplayName', mk{i, 3});
end
mp.limits([34 71], [-11 35]);
legend(mp.Ax, 'Location', 'northwest');
title(mp.Ax, sprintf('NUTS-3 regiony EU %d (velikost = počet obyvatel)', years(y)));
exportgraphics(f, fullfile(out, 'nuts3_mapa.png'), 'Resolution', 150);
close(f);
end
