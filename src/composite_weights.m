function [W, alpha] = composite_weights(S, alpha, method)
%COMPOSITE_WEIGHTS Combine several metrics into one weight per unit.
%   S      struct of share matrices [years x units] (see shares.m)
%   alpha  struct of metric weights (field = metric name), or 'entropy' /
%          'pca' for objectively derived weights
%   method 'linear'    w = sum_k a_k * s_k          (arithmetic mean)
%          'geometric' w = prod_k s_k ^ a_k          (geometric mean)
%
%   The linear composite has a neat property: its centroid is (in 3D)
%   exactly the weighted average of the centroids of the individual
%   metrics. The geometric one is not: it penalises imbalance (a country
%   that is large by population but poor gets less than the average of its
%   shares), and a metric that is equal for everyone (one state = one vote)
%   has no effect on it at all.
if ischar(alpha) || isstring(alpha)
    switch alpha
        case 'entropy', alpha = entropy_alpha(S);
        case 'pca',     alpha = pca_alpha(S);
    end
end
names = string(fieldnames(alpha))';
a = cellfun(@(k) alpha.(k), cellstr(names));
a = a / sum(a);
switch method
    case 'linear'
        W = 0;
        for k = 1:numel(names), W = W + a(k) * S.(names(k)); end
    case 'geometric'
        W = 1;
        for k = 1:numel(names), W = W .* S.(names(k)) .^ a(k); end
end
for k = 1:numel(names), alpha.(names(k)) = a(k); end
end

function alpha = entropy_alpha(S)
% Entropy weight method: a metric that is distributed more unevenly across
% units (lower entropy) carries more information and gets a larger weight.
% A metric that is equal for all units (one state = one vote) gets ~0.
names = string(fieldnames(S))';
d = zeros(size(names));
for k = 1:numel(names)
    P = S.(names(k));
    n = sum(P > 0, 2);
    e = -sum(P .* log(max(P, realmin)), 2) ./ log(n);
    d(k) = mean(1 - e, 'omitnan');
end
alpha = cell2struct(num2cell(d / sum(d)), cellstr(names), 2);
end

function alpha = pca_alpha(S)
% Weights from the first principal component (OECD Handbook on Composite
% Indicators): standardised shares, squared PC1 loadings, averaged over years.
names = string(fieldnames(S))';
nY = size(S.(names(1)), 1);
acc = zeros(1, numel(names));  cnt = 0;
for y = 1:nY
    X = cell2mat(cellfun(@(k) S.(k)(y, :)', cellstr(names), 'UniformOutput', false));
    X = X(all(X > 0, 2) & all(~isnan(X), 2), :);     % members with data only
    if size(X, 1) < 3, continue, end
    sd = std(X);  keep = sd > 0;                      % constant metric = 0
    Z = (X(:, keep) - mean(X(:, keep))) ./ sd(keep);
    [~, ~, V] = svd(Z, 'econ');
    l = zeros(1, numel(names));  l(keep) = V(:, 1)'.^2;
    acc = acc + l;  cnt = cnt + 1;
end
alpha = cell2struct(num2cell(acc / cnt), cellstr(names), 2);
end
