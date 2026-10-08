function T = fetch_eurostat(dataset, query, cacheFile)
%FETCH_EUROSTAT Download a dataset from the Eurostat API (JSON-stat 2.0) as a long table.
%   T = fetch_eurostat('demo_pjan', 'sex=T&age=TOTAL', 'data/raw/pop.csv')
%   returns columns geo, year, value. If cacheFile exists it is read
%   instead, so the project also runs offline after the first run.

if nargin >= 3 && isfile(cacheFile)
    T = readtable(cacheFile, 'TextType', 'string');
    return
end

base = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/";
url  = base + dataset + "?" + query + "&sinceTimePeriod=2000";
opts = weboptions('Timeout', 180, 'ContentType', 'text');
txt  = webread(url, opts);

T = parse_jsonstat(txt);
if nargin >= 3
    writetable(T, cacheFile);
end
end

function T = parse_jsonstat(txt)
% JSON-stat stores the values in one flat "value" object indexed row-major
% over all dimensions (order in id, sizes in size). All dimensions except
% geo and time are assumed to have size 1.
% The "value" object (tens of thousands of entries for regional data) is
% parsed with a regular expression: jsondecode would turn it into a struct
% with 50 000 fields.
tok  = regexp(txt, '"value":\{([^}]*)\}', 'tokens', 'once');
kv   = regexp(tok{1}, '"(\d+)":(-?[\d.eE+-]+|null)', 'tokens');
kv   = vertcat(kv{:});
flat = str2double(kv(:, 1));
v    = str2double(kv(:, 2));                   % null -> NaN
js   = jsondecode(regexprep(txt, '"value":\{[^}]*\}', '"value":{}'));

dims  = string(js.id);
sz    = double(js.size(:))';
geoIx = js.dimension.geo.category.index;
timIx = js.dimension.time.category.index;
geos  = string(fieldnames(geoIx));
times = string(fieldnames(timIx));
% fieldnames turns "2000" into "x2000" -> back to numbers
years = str2double(erase(times, "x"));

assert(prod(sz(~ismember(dims, ["geo" "time"]))) == 1, ...
    'fetch_eurostat: the query must fix every dimension except geo and time');

gPos = cellfun(@(g) geoIx.(g), cellstr(geos));
tPos = cellfun(@(t) timIx.(t), cellstr(times));
nT   = sz(dims == "time");
% time is always the last dimension in Eurostat responses
gi = floor(flat / nT);
ti = mod(flat, nT);

[~, gRow] = ismember(gi, gPos);
[~, tRow] = ismember(ti, tPos);
T = table(geos(gRow), years(tRow), v, 'VariableNames', {'geo', 'year', 'value'});
T = rmmissing(sortrows(T, {'geo', 'year'}));
end
