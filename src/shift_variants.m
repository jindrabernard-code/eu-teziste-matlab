function V = shift_variants(out)
%SHIFT_VARIANTS Series shown in the shift maps and animations (shift_maps.m, shift_animations.m).
%   Each series is {label, column prefix, ownZoom}; see tracks_figure.m.
V = struct('file', {}, 'title', {}, 'T', {}, 'series', {});

V(1).file = '1_metrics';
V(1).title = 'Variant 1: EU centroid by individual metric (states)';
V(1).T = readtable(fullfile(out, 'centroids_by_year.csv'));
V(1).series = {
    'States (1:1)',       'states',        false
    'Area',               'area',          false
    'Population',         'population',    false
    'EP seats',           'ep_seats',      false
    'GDP (PPS)',          'gdp_pps',       false
    'Council votes',      'council_votes', false
    'Military spending',  'military',      false
    'Government debt',    'debt',          false};

V(2).file = '2_composite';
V(2).title = 'Variant 2: composite indices (states)';
V(2).T = readtable(fullfile(out, 'composite_centroids.csv'));
V(2).series = {
    'Political',            'political',         false
    'Economic',             'economic',          false
    'Balanced (linear)',    'balanced',          false
    'Balanced (geometric)', 'balanced_geom',     false
    'Entropy weights',      'entropy',           false
    'PCA weights',          'pca',               false
    'Population median',    'population_median', false
    'Balanced median',      'balanced_median',   false};

V(3).file = '3_nuts3';
V(3).title = 'Variant 3: NUTS-3 regions, demography and economy';
V(3).T = readtable(fullfile(out, 'nuts_centroids.csv'));
V(3).series = {
    'Population',             'n3_population',         false
    'Population 15–64',       'n3_pop_15_64',          false
    'Employment',             'n3_employment',         false
    'GDP (EUR)',              'n3_gdp_eur',            false
    'GDP (PPS)',              'n3_gdp_pps',            false
    'Area',                   'n3_area',               false
    'Demographic composite',  'n3_c_demographic',      false
    'Economic composite',     'n3_c_economic',         false
    'Balanced composite',     'n3_c_balanced',         false
    'Geometric composite',    'n3_c_balanced_geom',    false
    'Entropy composite',      'n3_c_entropy',          false
    'PCA composite',          'n3_c_pca',              false
    'Population median',      'n3_population_median',  false};
end
