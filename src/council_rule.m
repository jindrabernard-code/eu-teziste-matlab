function [rule, w] = council_rule(year, votes, pop)
%COUNCIL_RULE Pravidlo kvalifikované většiny v Radě EU pro daný rok.
%   votes, pop jsou vektory jen pro aktuální členy. Vrací:
%     w    - "hlasy" pro výpočet těžiště (vážené hlasy, od 2014 populace)
%     rule - funkce rule(C) -> logical, C je [N x nStates] logická matice
%            koalic; true = koalice prosadí návrh.
%   Zjednodušení: přechodná období (květen-říjen 2004, 2014-2017 na žádost
%   podle Nice) se ignorují.
n = numel(votes);
popShare = pop(:) / sum(pop);
if year <= 2003                               % Amsterdam, EU-15: 62 z 87
    w = votes(:);
    rule = @(C) C*w >= 62;
elseif year <= 2013                           % Nice: trojí většina
    w = votes(:);
    tot = sum(w);
    q = struct('t321', 232, 't345', 255, 't352', 260);   % EU-25/27/28
    quota = q.("t" + tot);
    rule = @(C) C*w >= quota & sum(C, 2) > n/2 & C*popShare >= 0.62;
else                                          % Lisabon: dvojí většina
    w = pop(:);
    rule = @(C) (sum(C, 2) >= ceil(0.55*n) & C*popShare >= 0.65) ...
              | sum(~C, 2) < 4;                % blokační menšina >= 4 státy
end
end
