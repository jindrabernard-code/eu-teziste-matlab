function animate_tracks(T, series, ttl, file, delay)
%ANIMATE_TRACKS Animated GIF of the centroid shift, year by year.
%   Same figure as plot_yearly_tracks, one frame per year. Enlargement and
%   Brexit years are held longer, the last frame longer still.
if nargin < 5, delay = 0.7; end
H = tracks_figure(T, series, ttl, 1500);
events = [2004 2007 2013 2014 2020];
frames = {};
for y = H.years'
    tracks_set_year(H, y, true);
    drawnow;
    frames{end+1} = print(H.fig, '-RGBImage', '-r96'); %#ok<AGROW>
end
close(H.fig);
% one palette for all frames (from the last one, which contains every colour)
[~, map] = rgb2ind(frames{end}, 255, 'nodither');
for k = 1:numel(frames)
    X = rgb2ind(frames{k}, map, 'nodither');
    d = delay;
    if ismember(H.years(k), events), d = 2 * delay; end
    if k == numel(frames), d = 4; end
    if k == 1
        imwrite(X, map, file, 'gif', 'LoopCount', Inf, 'DelayTime', d);
    else
        imwrite(X, map, file, 'gif', 'WriteMode', 'append', 'DelayTime', d);
    end
end
end
