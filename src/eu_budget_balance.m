function T = eu_budget_balance(cacheDir, includeNGEU)
%EU_BUDGET_BALANCE Operating budgetary balance of EU member states, 2000–2025.
%   T = eu_budget_balance('data/raw') returns a long table code, year, obb,
%   spending, contribution, gni (EUR million). obb > 0 = net receiver,
%   obb < 0 = net payer.
%
%   Source: European Commission, "EU spending and revenue – Data 2000–2025"
%   (one sheet per year, countries in columns). The balance follows the
%   Commission's operating budgetary balance method:
%     spending     = EU spending allocated to the country, excluding
%                    administration (the institutions' seats would turn
%                    Belgium and Luxembourg into receivers)
%     contribution = national contribution (VAT-, GNI- and plastics-based
%                    own resources, corrections and adjustments), excluding
%                    traditional own resources (customs duties, sugar levies)
%     balance      = spending - contribution * (sum spending / sum contribution)
%   The rescaling makes the balances of all countries sum to zero.
%   NextGenerationEU (from 2021, a separate block in the file) is excluded by
%   default because it is financed by borrowing, not by national
%   contributions (includeNGEU = true adds it).
if nargin < 2, includeNGEU = false; end
file = fullfile(cacheDir, 'eu_budget_2000-2025.xlsx');
if ~isfile(file)
    websave(file, ['https://commission.europa.eu/document/download/' ...
        '9f334bee-d097-4b68-8f93-2225eabeb631_en?filename=eu_budget_spending_and_revenue_2000-2025.xlsx'], ...
        weboptions('Timeout', 120));
end
cacheCsv = fullfile(cacheDir, sprintf('eu_budget_balance_ngeu%d.csv', includeNGEU));
if isfile(cacheCsv) && dir(cacheCsv).datenum > dir(file).datenum
    T = readtable(cacheCsv, 'TextType', 'string');
    return
end

T = table();
for s = sheetnames(file)'
    C = readcell(file, 'Sheet', s);
    L1 = labels(C(:, 1));  L2 = labels(C(:, 2));
    % the row with country codes (BE, BG, ...) is among the first three
    hr = find(any(cellfun(@(x) isequal(x, 'BE'), C(1:3, :)), 2), 1);
    hdr = labels(C(hr, :));
    % country codes: two capital letters, possibly with a footnote star ("LU*" in 2022)
    cols = find(~cellfun(@isempty, regexp(hdr, '^[A-Z]{2}\*?$', 'once')));
    codes = erase(hdr(cols), "*")';

    rTot = find(L1 == "TOTAL EXPENDITURE", 1);
    rAdm = find(startsWith(upper(L1), "5. ADMINISTRATION") | upper(L2) == "ADMINISTRATION" ...
        | L2 == "European Public Administration", 1);
    spend = num(C(rTot, cols)) - num(C(rAdm, cols));
    % from 2021 the countries' spending excludes NGEU, which is a separate block
    rNg = find(L1 == "TOTAL NGEU", 1);
    if includeNGEU && ~isempty(rNg), spend = spend + num(C(rNg, cols)); end

    rNat = find(L1 == "TOTAL national contribution", 1);
    if ~isempty(rNat)                                   % 2000–2020
        contrib = num(C(rNat, cols));
    else                                                % 2021+
        own = num(C(find(L2 == "TOTAL Own resources", 1), cols));
        cus = num(C(find(L2 == "Customs duties", 1), cols));
        sug = num(C(find(L2 == "Sugar levies", 1), cols));
        adj = num(C(find(L2 == "TOTAL Balances and adjustments", 1), cols));
        contrib = own - cus - sug + adj;
    end
    rG = find(startsWith(L1, "Gross National Income") | startsWith(L2, "Gross National Income"), 1);
    gni = num(C(rG, cols));

    % only countries that pay a national contribution, i.e. members; candidate
    % countries have pre-accession spending but must not enter the rescaling
    ok = contrib ~= 0;
    k = sum(spend(ok)) / sum(contrib(ok));
    obb = spend - contrib * k;
    y = str2double(regexp(s, '\d{4}', 'match', 'once'));
    T = [T; table(codes(ok), repmat(y, nnz(ok), 1), obb(ok)', spend(ok)', contrib(ok)', gni(ok)', ...
        'VariableNames', {'code', 'year', 'obb', 'spending', 'contribution', 'gni'})]; %#ok<AGROW>
end
writetable(T, cacheCsv);
end

function L = labels(c)
L = strings(size(c));
for i = 1:numel(c)
    x = c{i};
    if ischar(x) || isstring(x), L(i) = strtrim(strrep(string(x), newline, ' ')); end
end
end

function v = num(c)
v = zeros(1, numel(c));
for i = 1:numel(c)
    if isnumeric(c{i}) && ~isempty(c{i}) && ~isnan(c{i}), v(i) = c{i}; end
end
end
