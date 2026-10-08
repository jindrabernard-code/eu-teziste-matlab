function X = to_matrix(T, codes, years)
%TO_MATRIX Long table (geo, year, value) -> matrix [years x countries].
%   Missing combinations are NaN.
X = nan(numel(years), numel(codes));
[okG, g] = ismember(T.geo, codes);
[okY, y] = ismember(T.year, years);
ok = okG & okY;
X(sub2ind(size(X), y(ok), g(ok))) = T.value(ok);
end
