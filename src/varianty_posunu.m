function V = varianty_posunu(out)
%VARIANTY_POSUNU Řady pro mapy a animace posunů (sdílené mapy_posunu/animace_posunu).
V = struct('file', {}, 'title', {}, 'T', {}, 'series', {});
V(1).file = '1_metriky';
V(1).title = 'Varianta 1: těžiště EU podle jednotlivých metrik (státy)';
V(1).T = readtable(fullfile(out, 'teziste_po_letech.csv'));
V(1).series = {
    'Státy 1:1', 'staty';  'Plocha', 'plocha';  'Populace', 'populace'
    'Mandáty EP', 'ep';  'HDP (EUR)', 'hdp_eur';  'HDP (PPS)', 'hdp_pps'
    'Hlasy v Radě', 'rada_hlasy';  'Banzhafova síla v Radě', 'rada_sila'};

V(2).file = '2_kompozit';
V(2).title = 'Varianta 2: kompozitní indexy (státy)';
V(2).T = readtable(fullfile(out, 'kompozit_teziste.csv'));
V(2).series = {
    'Politický', 'politicky';  'Ekonomický', 'ekonomicky'
    'Vyvážený (lineární)', 'vyvazeny';  'Vyvážený (geometrický)', 'vyvazeny_geom'
    'Entropické váhy', 'entropie';  'PCA váhy', 'pca'
    'Medián populace', 'populace_median';  'Medián vyvážený', 'vyvazeny_median'};

V(3).file = '3_nuts3';
V(3).title = 'Varianta 3: regiony NUTS-3, demografie a ekonomika';
V(3).T = readtable(fullfile(out, 'nuts_teziste.csv'));
V(3).series = {
    'Populace', 'n3_populace';  'Populace 15–64', 'n3_pop_15_64'
    'Zaměstnanost', 'n3_zamestnanost';  'HDP (EUR)', 'n3_hdp_eur'
    'HDP (PPS)', 'n3_hdp_pps';  'Plocha', 'n3_plocha'
    'Kompozit demografický', 'n3_k_demograficky';  'Kompozit ekonomický', 'n3_k_ekonomicky'
    'Kompozit vyvážený', 'n3_k_vyvazeny';  'Kompozit geometrický', 'n3_k_vyvazeny_geom'
    'Kompozit entropie', 'n3_k_entropie';  'Kompozit PCA', 'n3_k_pca'
    'Medián populace', 'n3_populace_median'};
end
