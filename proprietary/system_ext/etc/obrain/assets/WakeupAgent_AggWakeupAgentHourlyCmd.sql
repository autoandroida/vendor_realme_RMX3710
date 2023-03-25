insert into {}
select {} as start_ts, {} as end_ts, {} as wall_start_ts, {} as wall_end_ts, ground_mode, power_mode, screen_mode, thermal_mode, type, packageName
	, tag, sum(times)
from comp_wakeupAgent_backward
where start_ts >= {}
	and end_ts <= {}
	and times > 0
    and ground_mode != -1
    and power_mode != -1
    and screen_mode != -1
    and thermal_mode != -1
group by power_mode, screen_mode, thermal_mode, ground_mode, type, packageName, tag;