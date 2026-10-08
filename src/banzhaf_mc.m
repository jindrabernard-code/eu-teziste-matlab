function beta = banzhaf_mc(rule, n, nSamples, seed)
%BANZHAF_MC Normalizovaný Banzhafův index síly odhadnutý Monte Carlem.
%   Náhodné koalice (každý stát s p = 1/2); stát i je "swing", pokud
%   koalice s ním vyhrává a bez něj prohrává. Pro n = 28 je přesný výpočet
%   2^28 koalic zbytečný, chyba MC při 2e5 vzorcích je ~1e-3.
if nargin < 4, seed = 1; end
rng(seed);
C = rand(nSamples, n) < 0.5;
swings = zeros(1, n);
for i = 1:n
    Cin = C;  Cin(:, i) = true;
    Cout = C; Cout(:, i) = false;
    swings(i) = sum(rule(Cin) & ~rule(Cout));
end
beta = swings / sum(swings);
end
