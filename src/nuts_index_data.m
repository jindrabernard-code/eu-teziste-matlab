function [D, dataCodes, dataYears, hasRow, rowOf] = nuts_index_data(T, G)
%NUTS_INDEX_DATA Long table -> matrix [codes x years] plus the mapping of rows of G onto it.
dataCodes = unique(T.geo);
dataYears = unique(T.year)';
D = nan(numel(dataCodes), numel(dataYears));
[~, gi] = ismember(T.geo, dataCodes);
[~, ti] = ismember(T.year, dataYears);
D(sub2ind(size(D), gi, ti)) = T.value;
[hasRow, rowOf] = ismember(G.code, dataCodes);
end
