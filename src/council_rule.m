function [rule, w] = council_rule(year, votes, pop)
%COUNCIL_RULE Qualified-majority rule in the Council of the EU for a year.
%   votes, pop are vectors for current members only. Returns:
%     w    - "votes" used as centroid weights (weighted votes, population
%            from 2014)
%     rule - function rule(C) -> logical, C is an [N x nStates] logical
%            matrix of coalitions; true = the coalition passes a proposal.
%   Simplification: transitional periods (May-October 2004, 2014-2017 Nice
%   voting on request) are ignored.
n = numel(votes);
popShare = pop(:) / sum(pop);
if year <= 2003                               % Amsterdam, EU-15: 62 of 87
    w = votes(:);
    rule = @(C) C*w >= 62;
elseif year <= 2013                           % Nice: triple majority
    w = votes(:);
    tot = sum(w);
    q = struct('t321', 232, 't345', 255, 't352', 260);   % EU-25/27/28
    quota = q.("t" + tot);
    rule = @(C) C*w >= quota & sum(C, 2) > n/2 & C*popShare >= 0.62;
else                                          % Lisbon: double majority
    w = pop(:);
    rule = @(C) (sum(C, 2) >= ceil(0.55*n) & C*popShare >= 0.65) ...
              | sum(~C, 2) < 4;                % blocking minority >= 4 states
end
end
