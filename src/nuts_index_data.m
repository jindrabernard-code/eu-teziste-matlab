function [D, dataCodes, dataYears, hasRow, rowOf] = nuts_index_data(T, G)
%NUTS_INDEX_DATA
% long tabulka -> matice [kódy x roky] + mapování řádků G na její řádky
dataCodes = unique(T.geo);
dataYears = unique(T.year)';
D = nan(numel(dataCodes), numel(dataYears));
[~, gi] = ismember(T.geo, dataCodes);
[~, ti] = ismember(T.year, dataYears);
D(sub2ind(size(D), gi, ti)) = T.value;
[hasRow, rowOf] = ismember(G.code, dataCodes);
end
