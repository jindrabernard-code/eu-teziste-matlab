function [W, alpha] = composite_weights(S, alpha, method)
%COMPOSITE_WEIGHTS Složí několik metrik do jedné váhy každé jednotky.
%   S      struct podílových matic [roky x jednotky] (viz shares.m)
%   alpha  struct vah metrik (pole = názvy metrik), nebo 'entropy' / 'pca'
%          pro objektivně odvozené váhy
%   method 'linear'    w = sum_k a_k * s_k          (aritmetický průměr)
%          'geometric' w = prod_k s_k ^ a_k          (geometrický průměr)
%
%   Lineární kompozit má hezkou vlastnost: jeho těžiště je (ve 3D) přesně
%   vážený průměr těžišť jednotlivých metrik. Geometrický ne: trestá
%   nevyváženost (stát velký populací, ale chudý dostane méně než
%   průměr obou) a metrika, která je u všech stejná (1 stát = 1 hlas),
%   se v něm vůbec neprojeví.
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
% Metoda entropických vah: metrika, která je mezi jednotkami rozložená
% nerovnoměrněji (nižší entropie), nese víc informace a dostane větší
% váhu. Metrika rovnoměrná u všech (státy 1:1) dostane ~0.
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
% Váhy podle 1. hlavní komponenty (postup z OECD Handbook on Composite
% Indicators): standardizované podíly, čtverce ladění PC1, průměr přes roky.
names = string(fieldnames(S))';
nY = size(S.(names(1)), 1);
acc = zeros(1, numel(names));  cnt = 0;
for y = 1:nY
    X = cell2mat(cellfun(@(k) S.(k)(y, :)', cellstr(names), 'UniformOutput', false));
    X = X(all(X > 0, 2) & all(~isnan(X), 2), :);     % jen členové s daty
    if size(X, 1) < 3, continue, end
    sd = std(X);  keep = sd > 0;                      % konstantní metrika = 0
    Z = (X(:, keep) - mean(X(:, keep))) ./ sd(keep);
    [~, ~, V] = svd(Z, 'econ');
    l = zeros(1, numel(names));  l(keep) = V(:, 1)'.^2;
    acc = acc + l;  cnt = cnt + 1;
end
alpha = cell2struct(num2cell(acc / cnt), cellstr(names), 2);
end
