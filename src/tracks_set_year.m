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
    d = haversine_km(la(ok(1)), lo(ok(1)), la(ok(end)), lo(ok(end)));
    if animated
        set(H.cur(i), 'LatitudeData', la(ok(end)), 'LongitudeData', lo(ok(end)));
        title(gx, [H.labels{i} own_note(H, i)], 'FontSize', 10);
        ring = [la(ok(end)) lo(ok(end)) 9];          % current-year ring, ~9 px radius
    else
        set(H.cur(i), 'LatitudeData', NaN, 'LongitudeData', NaN);
        title(gx, sprintf('%s%s  (%d–%d: %.0f km)', H.labels{i}, own_note(H, i), H.years(ok(1)), ...
            H.years(ok(end)), d), 'FontSize', 10);
        ring = [];
    end
    year_labels(gx, H.px{i}, la, lo, H.years, ok, H.labelKm(i), ring);
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

function year_labels(gx, px, la, lo, years, ok, thr, ring)
% Candidates: the first year, jumps over thr km (25 km in the shared zoom,
% at most the 6 largest) and the last year. Candidates closer than 14 px
% to the previous one are merged into a range ("2020–25"). Labels are then
% placed by priority: the group with the last (current) year, the first
% year, then the largest jumps; place_labels drops any that would overlap.
d = [inf; haversine_km(la(ok(1:end-1)), lo(ok(1:end-1)), la(ok(2:end)), lo(ok(2:end)))];
big = ok(d > thr);
if numel(big) > 6                       % noisy series: only the 6 largest jumps
    [~, ord] = sort(d(d > thr), 'descend');
    big = sort(big(ord(1:6)));
end
lab = unique([ok(1); big; ok(end)]);
[x, y] = px.toPx(la(lab), lo(lab));
grp = cumsum([1; hypot(diff(x), diff(y)) >= 14]);   % chronological groups
nG = grp(end);
txt = strings(nG, 1);  at = zeros(nG, 1);  prio = zeros(nG, 1);
dOk = d;  dOk(1) = 0;
for g = 1:nG
    m = lab(grp == g);
    at(g) = m(1);
    txt(g) = string(years(m(1)));
    if numel(m) > 1, txt(g) = txt(g) + "–" + mod(years(m(end)), 100); end
    jump = max(dOk(ismember(ok, m)));
    prio(g) = jump + 1e6 * any(m == ok(end)) + 1e5 * any(m == ok(1));
end
[~, order] = sort(prio, 'descend');
place_labels(gx, px, la(at(order)), lo(at(order)), txt(order), la(ok), lo(ok), 8, ring);
end

function s = own_note(H, i)
s = '';
if H.own(i), s = ' [own zoom]'; end
end
