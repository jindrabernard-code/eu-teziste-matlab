function T = fetch_worldbank(indicator, iso3, cacheFile)
%FETCH_WORLDBANK Stáhne ukazatel ze Světové banky (API v2) jako long tabulku.
%   T = fetch_worldbank('MS.MIL.XPND.CD', iso3, 'data/raw/mil.csv') vrací
%   sloupce iso3, year, value. Je-li cacheFile na disku, načte se z něj.
%   Vojenské výdaje (MS.MIL.*) jsou data SIPRI, která Světová banka přebírá.
%   Eurostat (COFOG GF02) je pro tento účel nepoužitelný, chybí v něm UK.
if nargin >= 3 && isfile(cacheFile)
    T = readtable(cacheFile, 'TextType', 'string');
    return
end
url = sprintf('https://api.worldbank.org/v2/country/%s/indicator/%s?format=json&date=2000:2030&per_page=5000', ...
    strjoin(iso3, ';'), indicator);
js = webread(url, weboptions('Timeout', 60, 'ContentType', 'json'));
rows = js{2};                                  % js{1} jsou metadata (stránkování)
if iscell(rows), rows = [rows{:}]; end
iso = string({rows.countryiso3code})';
year = str2double(string({rows.date}))';
v = cellfun(@(x) double_or_nan(x), {rows.value})';
T = rmmissing(table(iso, year, v, 'VariableNames', {'iso3', 'year', 'value'}));
if nargin >= 3, writetable(T, cacheFile); end
end

function d = double_or_nan(x)
if isempty(x), d = NaN; else, d = double(x); end
end
