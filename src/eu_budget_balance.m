function T = eu_budget_balance(cacheDir, includeNGEU)
%EU_BUDGET_BALANCE Operační rozpočtové saldo členských států EU 2000–2025.
%   T = eu_budget_balance('data/raw') vrací long tabulku code, year, obb,
%   vydaje, prispevek, hni (mil. EUR). obb > 0 = čistý příjemce,
%   obb < 0 = čistý plátce.
%
%   Zdroj: Evropská komise, "EU spending and revenue – Data 2000–2025"
%   (jeden list na rok, státy ve sloupcích). Saldo se počítá metodou
%   Komise (operating budgetary balance):
%     výdaje    = přidělené výdaje státu bez administrativy (sídla institucí
%                 by z Belgie a Lucemburska udělala příjemce)
%     příspěvek = národní příspěvek (DPH, HND, plasty, korekce a vyrovnání),
%                 bez tradičních vlastních zdrojů (cla, cukr)
%     saldo     = výdaje - příspěvek * (sum výdajů / sum příspěvků)
%   Přeškálování příspěvků zajistí, že součet sald přes státy je nula.
%   NextGenerationEU (od 2021, v souboru samostatný blok) se ve výchozím
%   stavu nezapočítává, protože se financuje půjčkami, ne národními
%   příspěvky (includeNGEU = true ho přičte).
if nargin < 2, includeNGEU = false; end
file = fullfile(cacheDir, 'eu_budget_2000-2025.xlsx');
if ~isfile(file)
    websave(file, ['https://commission.europa.eu/document/download/' ...
        '9f334bee-d097-4b68-8f93-2225eabeb631_en?filename=eu_budget_spending_and_revenue_2000-2025.xlsx'], ...
        weboptions('Timeout', 120));
end
cacheCsv = fullfile(cacheDir, sprintf('eu_budget_obb_ngeu%d.csv', includeNGEU));
if isfile(cacheCsv) && dir(cacheCsv).datenum > dir(file).datenum
    T = readtable(cacheCsv, 'TextType', 'string');
    return
end

T = table();
for s = sheetnames(file)'
    C = readcell(file, 'Sheet', s);
    L1 = labels(C(:, 1));  L2 = labels(C(:, 2));
    % řádek s kódy států (BE, BG, ...) je mezi prvními třemi
    hr = find(any(cellfun(@(x) isequal(x, 'BE'), C(1:3, :)), 2), 1);
    hdr = labels(C(hr, :));
    % kódy států: dvě velká písmena, případně s hvězdičkou poznámky ("LU*" v 2022)
    cols = find(~cellfun(@isempty, regexp(hdr, '^[A-Z]{2}\*?$', 'once')));
    codes = erase(hdr(cols), "*")';

    rTot = find(L1 == "TOTAL EXPENDITURE", 1);
    rAdm = find(startsWith(upper(L1), "5. ADMINISTRATION") | upper(L2) == "ADMINISTRATION" ...
        | L2 == "European Public Administration", 1);
    vyd = num(C(rTot, cols)) - num(C(rAdm, cols));
    % výdaje států od 2021 NGEU neobsahují, je v samostatném bloku
    rNg = find(L1 == "TOTAL NGEU", 1);
    if includeNGEU && ~isempty(rNg), vyd = vyd + num(C(rNg, cols)); end

    rNat = find(L1 == "TOTAL national contribution", 1);
    if ~isempty(rNat)                                   % 2000–2020
        pri = num(C(rNat, cols));
    else                                                % 2021+
        own = num(C(find(L2 == "TOTAL Own resources", 1), cols));
        cus = num(C(find(L2 == "Customs duties", 1), cols));
        sug = num(C(find(L2 == "Sugar levies", 1), cols));
        adj = num(C(find(L2 == "TOTAL Balances and adjustments", 1), cols));
        pri = own - cus - sug + adj;
    end
    rG = find(startsWith(L1, "Gross National Income") | startsWith(L2, "Gross National Income"), 1);
    hni = num(C(rG, cols));

    ok = vyd ~= 0 | pri ~= 0;                           % stát v daném roce nečlen
    k = sum(vyd(ok)) / sum(pri(ok));
    obb = vyd - pri * k;
    y = str2double(regexp(s, '\d{4}', 'match', 'once'));
    T = [T; table(codes(ok), repmat(y, nnz(ok), 1), obb(ok)', vyd(ok)', pri(ok)', hni(ok)', ...
        'VariableNames', {'code', 'year', 'obb', 'vydaje', 'prispevek', 'hni'})]; %#ok<AGROW>
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
