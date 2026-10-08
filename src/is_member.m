function M = is_member(countries, years)
%IS_MEMBER Logical matrix [years x countries]: EU membership on 31 December.
%   With 31 December as the reference date, 2004 already includes the ten
%   new members, 2013 includes Croatia and 2020 no longer includes the
%   United Kingdom (left on 31 January 2020).
ref  = datetime(years(:), 12, 31);
join = datetime(countries.join_date);
leave = datetime(countries.leave_date);      % NaT = still a member
M = ref >= join' & (isnat(leave') | ref < leave');
end
