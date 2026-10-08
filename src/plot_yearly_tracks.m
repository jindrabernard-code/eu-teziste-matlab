function plot_yearly_tracks(T, series, ttl, file)
%PLOT_YEARLY_TRACKS Static map of year-by-year centroid shifts.
%   Top left an overview of the EU (all series, rectangle = zoom), then one
%   zoomed panel per series: every year is a point coloured by year,
%   consecutive years are joined by a segment (= the shift during that
%   year), the first and last years and jumps over 25 km (enlargements,
%   Brexit, rule changes) are labelled. Animated version: animate_tracks.m.
H = tracks_figure(T, series, ttl);
tracks_set_year(H, H.years(end));
exportgraphics(H.fig, file, 'Resolution', 110);
close(H.fig);
end
