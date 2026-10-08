function plot_yearly_tracks(T, series, ttl, file)
%PLOT_YEARLY_TRACKS Statická mapa posunů těžiště rok po roku.
%   Vlevo nahoře přehled celé EU (všechny řady, obdélník = výřez), pak jeden
%   přiblížený panel na řadu: každý rok je bod obarvený rokem, sousední roky
%   spojuje úsečka (= posun během roku), popsané jsou první a poslední rok
%   a skoky nad 25 km (rozšíření, brexit, změna pravidel).
%   Animace stejného obrázku: animate_tracks.m.
H = tracks_figure(T, series, ttl);
tracks_set_year(H, H.years(end));
exportgraphics(H.fig, file, 'Resolution', 110);
close(H.fig);
end
