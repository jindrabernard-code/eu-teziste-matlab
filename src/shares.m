function S = shares(W, M)
%SHARES Turn weights into shares: every row (year) sums to 1 over members.
%   This makes metrics with different units (people, EUR, km2, votes)
%   addable. Non-members get 0, a year with missing data gets NaN.
W = W .* M;
W(~M) = 0;
S = W ./ sum(W, 2);
end
