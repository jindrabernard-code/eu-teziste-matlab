function tracks_set_year(H, y, animated)
%TRACKS_SET_YEAR Zobrazí v obrázku z tracks_figure trajektorie do roku y.
%   animated = true: nadpis s rokem a velikostí EU, modře státy, které
%   byly členy v daném roce (UK od 2020 jako bývalý člen), zvýrazněný
%   aktuální bod. false: statická mapa za celé období.
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
        title(gx, sprintf('%s  (bez dat)', H.labels{i}), 'FontSize', 10);
        continue
    end
    year_labels(gx, H.px{i}, la, lo, H.years, ok);
    d = haversine_km(la(ok(1)), lo(ok(1)), la(ok(end)), lo(ok(end)));
    if animated
        set(H.cur(i), 'LatitudeData', la(ok(end)), 'LongitudeData', lo(ok(end)));
        step = 0;
        if numel(ok) > 1 && H.years(ok(end)) == y
            step = haversine_km(la(ok(end-1)), lo(ok(end-1)), la(ok(end)), lo(ok(end)));
        end
        title(gx, sprintf('%s  (od %d: %.0f km, za rok: %.0f km)', H.labels{i}, ...
            H.years(ok(1)), d, step), 'FontSize', 10);
    else
        set(H.cur(i), 'LatitudeData', NaN, 'LongitudeData', NaN);
        title(gx, sprintf('%s  (%d–%d: %.0f km)', H.labels{i}, H.years(ok(1)), ...
            H.years(ok(end)), d), 'FontSize', 10);
    end
end
if animated
    mem = H.codes(H.member(yi, :));
    former = H.codes(any(H.member(1:yi, :), 1) & ~H.member(yi, :));
    H.map.showMembers(mem, former);
    H.map.LegEU.DisplayName = sprintf('Členské státy EU v roce %d (%d)', y, numel(mem));
    H.map.LegFormer.DisplayName = 'Bývalý člen (UK od 2020)';
    title(H.tl, sprintf('%s — rok %d (EU-%d)', H.ttl, y, numel(mem)), ...
        'FontWeight', 'bold', 'FontSize', 16);
end
end

function year_labels(gx, px, la, lo, years, ok)
% první rok, skoky > 25 km a poslední rok; body blíž než 20 km
% k předchozímu popisku se k němu připojí jako rozsah ("2020–25").
% Umístění řeší place_labels, aby popisky nepřekrývaly trajektorii.
d = [inf; haversine_km(la(ok(1:end-1)), lo(ok(1:end-1)), la(ok(2:end)), lo(ok(2:end)))];
lab = unique([ok(1); ok(d > 25); ok(end)]);
txt = strings(0);  at = [];
for k = lab'
    if ~isempty(at) && haversine_km(la(at(end)), lo(at(end)), la(k), lo(k)) < 20
        txt(end) = extractBefore(txt(end) + "–", 5) + "–" + mod(years(k), 100);
    else
        txt(end+1) = string(years(k));  at(end+1) = k; %#ok<AGROW>
    end
end
place_labels(gx, px, la(at), lo(at), txt, la(ok), lo(ok), 8);
end
