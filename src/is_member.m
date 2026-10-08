function M = is_member(countries, years)
%IS_MEMBER Logická matice [roky x státy]: členství k 31. 12. daného roku.
%   Referenční datum 31. 12. => 2004 už obsahuje 10 nových států, 2013
%   Chorvatsko a 2020 už ne Spojené království (odchod 31. 1. 2020).
ref  = datetime(years(:), 12, 31);
join = datetime(countries.join_date);
leave = datetime(countries.leave_date);      % NaT = stále členem
M = ref >= join' & (isnat(leave') | ref < leave');
end
