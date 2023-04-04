with
PARAM_VAR as (
    select
        {} as var_start_ts,
        {} as var_end_ts
)
insert into agg_display_app_hourly
select PARAM_VAR.var_start_ts as start_ts, PARAM_VAR.var_end_ts as end_ts
    , sum(time_delta) as total_du
	, screen_id, split_mode, parallel_mode, app, activity, app_secondary, activity_secondary
	, power_mode, screen_mode, thermal_mode, ground_mode, FPS
	, brightness / 100 * 100
	, (renderFps + 5) / 10 * 10
	, sum(whole_eg) as whole_eg
from comp_displayAgent_appPower_intv, PARAM_VAR
where start_ts >= PARAM_VAR.var_start_ts
	and end_ts <= PARAM_VAR.var_end_ts
	and screen_id != -1
	and split_mode != -1
	and parallel_mode != -1
	and power_mode != -1
	and screen_mode != -1
	and thermal_mode != -1
	and ground_mode != -1
group by screen_id, split_mode, parallel_mode, app, activity, app_secondary, activity_secondary,
    power_mode, screen_mode, thermal_mode, ground_mode, FPS, brightness / 100 * 100, (renderFps + 5) / 10 * 10
