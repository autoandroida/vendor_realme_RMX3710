insert into {}
select {} as start_ts, {} as end_ts, ground_mode, power_mode, screen_mode, thermal_mode,
	packageName, tag, sum(duration)
from comp_table_wakelock_enegry
where start_ts >= {}
	and end_ts <= {}
	and duration > 0
	and power_mode = 0
	and screen_mode = 0
    and ground_mode != -1
    and thermal_mode != -1
group by power_mode, screen_mode, thermal_mode, ground_mode, packageName, tag;
