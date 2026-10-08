function T = fetch_imf(indicator, iso3, cacheFile)
%FETCH_IMF Download an IMF DataMapper indicator (WEO) as a long table.
%   T = fetch_imf('GG_DEBT_GDP', "GBR", 'data/raw/imf_debt.csv') returns
%   columns iso3, year, value. Used only to fill the United Kingdom, which
%   Eurostat no longer publishes (general government debt, % of GDP).
%   For EU members the IMF figures equal Eurostat's (e.g. Germany 2000:
%   59.2 % in both).
if nargin >= 3 && isfile(cacheFile)
    T = readtable(cacheFile, 'TextType', 'string');
    return
end
url = "https://www.imf.org/external/datamapper/api/v1/" + indicator + "/" + strjoin(iso3, "/");
% the IMF API rejects MATLAB's (and browser-like) user agents with HTTP 403
% but accepts curl's
js = webread(url, weboptions('Timeout', 60, 'ContentType', 'json', 'UserAgent', 'curl/8.0'));
vals = js.values.(indicator);
T = table(strings(0, 1), zeros(0, 1), zeros(0, 1), 'VariableNames', {'iso3', 'year', 'value'});
for c = string(iso3(:))'
    if ~isfield(vals, c), continue, end
    s = vals.(c);
    yrs = str2double(erase(string(fieldnames(s)), "x"));
    v = cell2mat(struct2cell(s));
    T = [T; table(repmat(c, numel(yrs), 1), yrs, v(:), 'VariableNames', {'iso3', 'year', 'value'})]; %#ok<AGROW>
end
T = T(T.year >= 2000, :);
if nargin >= 3, writetable(T, cacheFile); end
end
