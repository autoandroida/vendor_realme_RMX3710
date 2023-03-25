insert into agg_displayAgent_brightness_hourly
select {} as start_ts, {} as end_ts, sum(time_delta) as total_du, screen_id, app
	, brightness / 100 * 100 as brightness, brightmode
from comp_displayAgent_brightness_intv
where start_ts >= {}
	and end_ts <= {}
group by screen_id, app, brightness / 100 * 100, brightmode