%% Animace posunu těžiště rok po roku (GIF) pro všechny tři varianty
% Vyžaduje výsledky z main.m, kompozit.m a main_nuts.m (run_all).
% Varianty a řady jsou stejné jako v mapy_posunu.m.
clear; clc;
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
out = fullfile(root, 'results');
V = varianty_posunu(out);
for v = 1:numel(V)
    fprintf('Animace %d/%d: %s\n', v, numel(V), V(v).file);
    animate_tracks(V(v).T, V(v).series, V(v).title, fullfile(out, "animace_" + V(v).file + ".gif"));
end
