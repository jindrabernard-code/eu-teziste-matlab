function T = fetch_eurostat(dataset, query, cacheFile)
%FETCH_EUROSTAT Stáhne dataset z Eurostat API (JSON-stat 2.0) a vrátí long tabulku.
%   T = fetch_eurostat('demo_pjan', 'sex=T&age=TOTAL', 'data/raw/pop.csv')
%   Výsledek má sloupce geo, year, value. Je-li cacheFile již na disku,
%   načte se z něj (projekt pak běží i offline).

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
% JSON-stat ukládá hodnoty do jednoho plochého objektu "value" indexovaného
% row-major přes všechny dimenze (pořadí v id, velikosti v size).
% Předpokládáme, že všechny dimenze kromě geo a time mají velikost 1.
% Objekt "value" (u regionálních dat desítky tisíc položek) se parsuje
% regulárním výrazem: jsondecode by z něj udělal struct s 50 000 poli.
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
% fieldnames u struct mění "2000" na "x2000" -> vrátit čísla
years = str2double(erase(times, "x"));

assert(prod(sz(~ismember(dims, ["geo" "time"]))) == 1, ...
    'fetch_eurostat: dotaz musí fixovat všechny dimenze kromě geo a time');

gPos = cellfun(@(g) geoIx.(g), cellstr(geos));
tPos = cellfun(@(t) timIx.(t), cellstr(times));
nT   = sz(dims == "time");
% time je v Eurostat odpovědích vždy poslední dimenze
gi = floor(flat / nT);
ti = mod(flat, nT);

[~, gRow] = ismember(gi, gPos);
[~, tRow] = ismember(ti, tPos);
T = table(geos(gRow), years(tRow), v, 'VariableNames', {'geo', 'year', 'value'});
T = rmmissing(sortrows(T, {'geo', 'year'}));
end
