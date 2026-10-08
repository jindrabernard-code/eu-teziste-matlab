function S = shares(W, M)
%SHARES Převede váhy na podíly: každý řádek (rok) sečte přes členy na 1.
%   Tím se metriky s různými jednotkami (lidé, EUR, km2, hlasy) dají
%   sčítat. Nečlenové dostanou 0, rok s chybějícími daty NaN.
W = W .* M;
W(~M) = 0;
S = W ./ sum(W, 2);
end
