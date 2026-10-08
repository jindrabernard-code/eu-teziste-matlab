function beta = banzhaf_mc(rule, n, nSamples, seed)
%BANZHAF_MC Normalised Banzhaf power index estimated by Monte Carlo.
%   Random coalitions (each state in with p = 1/2); state i is a "swing"
%   if the coalition wins with it and loses without it. For n = 28 the
%   exact enumeration of 2^28 coalitions is unnecessary, the MC error with
%   2e5 samples is ~1e-3. Not used as a centroid metric any more; kept for
%   the explanation in the README.
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
