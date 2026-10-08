%% Mapy posunů těžiště rok po roku pro všechny tři varianty
% Vyžaduje výsledky z main.m, kompozit.m a main_nuts.m (run_all).
% Řady jednotlivých variant jsou v src/varianty_posunu.m.
clear; clc;
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'src'));
out = fullfile(root, 'results');
V = varianty_posunu(out);
for v = 1:numel(V)
    plot_yearly_tracks(V(v).T, V(v).series, V(v).title + " 2000–2025", ...
        fullfile(out, "posuny_" + V(v).file + ".png"));
end
