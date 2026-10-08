function tracks_set_year(H, y, animated)
%TRACKS_SET_YEAR Show the tracks up to year y in a figure from tracks_figure.
%   animated = true: title with the year and EU size, countries that were
%   members in that year in blue (the UK as a former member from 2020),
%   current point highlighted. false: static map of the whole period.
if nargin < 3, animated = false; end
K = EuMap.K;
yi = find(H.years == y);
for i = 1:H.n
    la = H.la{i};  lo = H.lo{i};
    ok = find(~isnan(la) & H.years <= y);
    H.ovLine(i).XData = lo(ok) * K;  H.ovLine(i).YData = la(ok);
    if animated && ~isempty(ok)
        H.ovPt(i).XData = lo(ok(end)) * K;  H.ovPt(i).YData = la(ok(end));
    end
    set(H.seg{i}, 'Visible', 'off');
    set(H.seg{i}(H.segYear{i} <= y), 'Visible', 'on');
    set(H.pts(i), 'LatitudeData', la(ok), 'LongitudeData', lo(ok), 'CData', H.years(ok));
    gx = H.gx(i);
    delete(findobj(gx, 'Tag', 'yrlabel'));
    if isempty(ok)
        set(H.cur(i), 'LatitudeData', NaN, 'LongitudeData', NaN);
        title(gx, sprintf('%s  (no data)', H.labels{i}), 'FontSize', 10);
        continue
    end
    year_labels(gx, H.px{i}, la, lo, H.years, ok, H.labelKm(i));
    d = haversine_km(la(ok(1)), lo(ok(1)), la(ok(end)), lo(ok(end)));
    if animated
        set(H.cur(i), 'LatitudeData', la(ok(end)), 'LongitudeData', lo(ok(end)));
        step = 0;
        if numel(ok) > 1 && H.years(ok(end)) == y
            step = haversine_km(la(ok(end-1)), lo(ok(end-1)), la(ok(end)), lo(ok(end)));
        end
        title(gx, sprintf('%s%s  (since %d: %.0f km, this year: %.0f km)', H.labels{i}, own_note(H, i), ...
            H.years(ok(1)), d, step), 'FontSize', 10);
    else
        set(H.cur(i), 'LatitudeData', NaN, 'LongitudeData', NaN);
        title(gx, sprintf('%s%s  (%d–%d: %.0f km)', H.labels{i}, own_note(H, i), H.years(ok(1)), ...
            H.years(ok(end)), d), 'FontSize', 10);
    end
end
if animated
    mem = H.codes(H.member(yi, :));
    former = H.codes(any(H.member(1:yi, :), 1) & ~H.member(yi, :));
    H.map.showMembers(mem, former);
    H.map.LegEU.DisplayName = sprintf('EU members in %d (%d)', y, numel(mem));
    H.map.LegFormer.DisplayName = 'Former member (UK from 2020)';
    title(H.tl, sprintf('%s — %d (EU-%d)', H.ttl, y, numel(mem)), ...
        'FontWeight', 'bold', 'FontSize', 16);
end
end

function year_labels(gx, px, la, lo, years, ok, thr)
% Label the first year, jumps > thr km (25 km in the shared zoom, at most
% the 6 largest) and the last year. Points closer than 0.8*thr km to the
% previous label are merged into it as a range ("2020–25").
% place_labels positions them so they do not cover the track.
d = [inf; haversine_km(la(ok(1:end-1)), lo(ok(1:end-1)), la(ok(2:end)), lo(ok(2:end)))];
big = ok(d > thr);
if numel(big) > 6                       % noisy series: only the 6 largest jumps
    [~, ord] = sort(d(d > thr), 'descend');
    big = sort(big(ord(1:6)));
end
lab = unique([ok(1); big; ok(end)]);
txt = strings(0);  at = [];
for k = lab'
    if ~isempty(at) && haversine_km(la(at(end)), lo(at(end)), la(k), lo(k)) < 0.8 * thr
        txt(end) = extractBefore(txt(end) + "–", 5) + "–" + mod(years(k), 100);
    else
        txt(end+1) = string(years(k));  at(end+1) = k; %#ok<AGROW>
    end
end
place_labels(gx, px, la(at), lo(at), txt, la(ok), lo(ok), 8);
end

function s = own_note(H, i)
s = '';
if H.own(i), s = ' [own zoom]'; end
end
