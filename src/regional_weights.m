function [W, reg, proxyUsed, verUsed] = regional_weights(T, G, countries, years, M, natTot, Tproxy, refVer)
%REGIONAL_WEIGHTS Rozpočítá národní hodnotu metriky do regionů NUTS.
%   T      long tabulka z Eurostatu (geo, year, value), všechny úrovně NUTS
%   G      tabulka regionů (load_nuts_geometry, více verzí NUTS pod sebou)
%   natTot [roky x státy] záložní národní součty (NaN = nemáme), např. HDP
%          z nama_10_gdp tam, kde regionální data ještě nevyšla
%   Tproxy volitelná tabulka jiné metriky (typicky populace), podle které
%          se národní součet rozdělí, když stát nemá regionální data vůbec
%          (UK: Eurostat z regionálních účtů vyřadil HDP i zaměstnanost)
%   refVer [roky x státy] verze NUTS, kterou musí daný stát a rok použít
%          (NaN = libovolná). Kompozity potřebují, aby všechny metriky
%          stály na stejném rozdělení regionů; jinak by region, který
%          v jedné metrice chybí, dostal v geometrickém průměru nulu.
%          Když metrika v dané verzi data nemá, rozdělí se podle proxy.
%   Výstup W [roky x regiony], reg (řádky G, které se použily), proxyUsed
%   (kódy států, u kterých se použila proxy) a verUsed [roky x státy].
%
%   Regionální řady Eurostatu jsou děravé a kódy regionů se mezi verzemi
%   NUTS mění. Proto pro každý stát a rok:
%     1. národní součet = řádek státu v T, jinak natTot, jinak součet regionů
%     2. rozložení uvnitř státu = podíly regionů z nejbližšího roku, kde je
%        pro některou verzi NUTS pokrytí kompletní (přednost má novější verze)
%     3. váha regionu = součet x podíl
%   Součty za státy tak sedí s národními daty a nemůže dojít ke dvojímu
%   započtení starého a nového kódu téhož území.
if nargin < 7, Tproxy = []; end
if nargin < 8 || isempty(refVer), refVer = nan(numel(years), height(countries)); end
verUsed = nan(numel(years), height(countries));
[D, dataCodes, dataYears, hasRow, rowOf] = nuts_index_data(T, G);
if ~isempty(Tproxy)
    [Dp, ~, pYears, pHas, pRow] = nuts_index_data(Tproxy, G);
end

W = zeros(numel(years), height(G));
bad = false(numel(years), 1);          % rok, kde některému členovi chybí data
proxyUsed = strings(0);
for j = 1:height(countries)
    c = countries.code(j);
    [hasC, cRow] = ismember(c, dataCodes);
    for y = find(M(:, j))'
        % 1. národní součet
        tot = NaN;
        [~, ty] = ismember(years(y), dataYears);
        if hasC && ty > 0, tot = D(cRow, ty); end
        if isnan(tot) && ~isempty(natTot), tot = natTot(y, j); end
        % 2. rozložení uvnitř státu
        [r, x, dist] = nuts_split(D, dataYears, hasRow, rowOf, G, c, years(y), refVer(y, j));
        if isempty(r) && ~isempty(Tproxy)
            [r, x] = nuts_split(Dp, pYears, pHas, pRow, G, c, years(y), refVer(y, j));
            dist = inf;                                % součet z proxy nebrat
            if ~isempty(r), proxyUsed(end+1) = c; end %#ok<AGROW>
        end
        if isempty(r), bad(y) = true; continue, end
        if isnan(tot)
            if dist == 0, tot = sum(x); else, bad(y) = true; continue, end
        end
        W(y, r) = tot * x / sum(x);
        verUsed(y, j) = G.version(r(1));
    end
end
W(bad, :) = NaN;
proxyUsed = unique(proxyUsed);
used = any(W > 0, 1);
W = W(:, used);
reg = G(used, :);
end
