with
PARAM_VAR as (
    select
		{} as var_date,
		{} as var_start_ts,
		{} as var_end_ts,
		{} as var_version,
		'{}' as var_sum_hist,
		'{}' as var_screen_name
),
---- TOTAL_EG_TB
TOTAL_EG_RAW_TB as (
	select screen_id, power_mode, ground_mode, screen_mode, thermal_mode, FPS
		, brightness, renderFps, sum(whole_eg) as total_eg, sum(total_du) as total_du
	from agg_display_app_hourly,PARAM_VAR
	where start_ts >= PARAM_VAR.var_start_ts
		and end_ts <= PARAM_VAR.var_end_ts
		and total_du > 0
		and screen_mode = 1
	group by screen_id, power_mode, ground_mode, screen_mode, thermal_mode, FPS, brightness, renderFps
),
TOTAL_EG_RAW_JSON_TB as (
	select '{{"screen_id":' || screen_id || ',"power_mode":' || power_mode || ',"ground_mode":' || ground_mode || ',"screen_mode":' || screen_mode || ',"thermal_mode":' || thermal_mode || ',"fps":' || FPS || ',"renderFps":' || renderFps ||',"brightness":[' || group_concat(brightness) || '],"total_eg":[' || group_concat(total_eg) || '],"duration":[' || group_concat(total_du) || ']}}' as energy
	from TOTAL_EG_RAW_TB
	group by screen_id, power_mode, ground_mode, screen_mode, thermal_mode, FPS, renderFps
),
TOTAL_EG_TB as (
	select '[' || group_concat(energy) || ']' as energy
	from TOTAL_EG_RAW_JSON_TB
),
---- MODE_TB
MODE_TOPAPP_MODE_TB as (
	select app, power_mode, ground_mode, screen_mode, thermal_mode
		, sum(whole_eg) as total_eg, row_number() over (partition by power_mode, ground_mode, screen_mode, thermal_mode order by sum(total_du) desc) as idx
	from agg_display_app_hourly,PARAM_VAR
	where start_ts >= PARAM_VAR.var_start_ts
		and end_ts <= PARAM_VAR.var_end_ts
		and total_du > 0
		and screen_mode = 1
	group by app, power_mode, ground_mode, screen_mode, thermal_mode
),
MODE_TOPAPP_MODE_TOP10_TB as (
	select *
	from MODE_TOPAPP_MODE_TB
	where idx <= 10
),
MODE_TOPAPP_MODEL_INNNERJOIN_TB as (
	select T1.app, T1.power_mode, T1.screen_mode, T1.thermal_mode, T1.ground_mode
		, T1.FPS, T1.brightness, T1.renderFps, idx, sum(total_du) as total_du
		, sum(whole_eg) as total_eg
	from agg_display_app_hourly T1, PARAM_VAR
	inner join
	MODE_TOPAPP_MODE_TOP10_TB T2
	on T1.app = T2.app
		and T1.power_mode = T2.power_mode
		and T1.ground_mode = T2.ground_mode
		and T1.screen_mode = T2.screen_mode
		and T1.thermal_mode = T2.thermal_mode
	where start_ts >= PARAM_VAR.var_start_ts
	and end_ts <= PARAM_VAR.var_end_ts
	and T1.total_du > 0
	and T1.screen_mode = 1
	group by T1.app, T1.power_mode, T1.screen_mode, T1.thermal_mode, T1.ground_mode, T1.FPS, T1.brightness, T1.renderFps
),
MODE_TOTAL_APP_JSON_TB as (
	select '{{"app":"' || obfuscate(app) || '","power_mode":' || power_mode || ',"ground_mode":' || ground_mode || ',"screen_mode":' || screen_mode || ',"thermal_mode":' || thermal_mode || ',"idx":' || idx || ',"fps":' || FPS || ',"renderFps":' || renderFps ||',"brightness":[' || group_concat(brightness) || '],"total_eg":[' || group_concat(total_eg) || '],"duration":[' || group_concat(total_du) || ']}}' as by_mode
	from MODE_TOPAPP_MODEL_INNNERJOIN_TB
	group by app, power_mode, ground_mode, screen_mode, thermal_mode, FPS, renderFps
),
MODE_TBL as (
	select '[' || group_concat(by_mode) || ']' as by_mode
	from MODE_TOTAL_APP_JSON_TB
),
---- APP_TB
    ---- app normal
APP_NORMAL_TOTAL_TB as (
	select sum(total_du) as total_du
	from agg_display_app_hourly, PARAM_VAR
	where start_ts >= PARAM_VAR.var_start_ts
		and end_ts <= PARAM_VAR.var_end_ts
		and total_du > 0
		and split_mode = 0 and parallel_mode = 0 -- normal
),
APP_TOP_NORMAL_INDEX_TB as (
	select app, activity, screen_id, sum(whole_eg) as total_eg, row_number() over (order by sum(total_du) desc) as idx
	from agg_display_app_hourly, PARAM_VAR
	where start_ts >= PARAM_VAR.var_start_ts
		and end_ts <= PARAM_VAR.var_end_ts
		and total_du > 0
		and split_mode = 0 and parallel_mode = 0 -- normal
	group by app, activity, screen_id
	limit 10
),
APP_TOP_NORMAL_INNER_JOIN_TB as (
	select *
	from agg_display_app_hourly T1, PARAM_VAR
	inner join
	APP_TOP_NORMAL_INDEX_TB T2
	on T1.app = T2.app and T1.activity = T2.activity and T1.screen_id = T2.screen_id
	where start_ts >= PARAM_VAR.var_start_ts
		and end_ts <= PARAM_VAR.var_end_ts
		and total_du > 0
		and screen_mode = 1
		and split_mode = 0 and parallel_mode = 0 -- normal
),
APP_TOP_NORMAL_INNER_JOIN_GROUP_TB as (
	select app, activity, screen_id, power_mode, screen_mode, thermal_mode, ground_mode
		, FPS, brightness, renderFps, sum(total_du) as total_du
		, sum(whole_eg) as total_eg, idx
	from APP_TOP_NORMAL_INNER_JOIN_TB
	group by app, activity, screen_id, power_mode, screen_mode, thermal_mode, ground_mode, FPS, brightness, renderFps
),
APP_TOP_NORMAL_JSON_TB as (
	select '{{"app":"' || obfuscate(app) || '","activity":"' || activity || '","screen_id":' || screen_id || ',"power_mode":' || power_mode || ',"ground_mode":' || ground_mode || ',"screen_mode":' || screen_mode || ',"thermal_mode":' || thermal_mode || ',"idx":' || idx || ',"fps":' || FPS || ',"renderFps":' || renderFps ||',"brightness":[' || group_concat(brightness) || '],"total_eg":[' || group_concat(total_eg) || '],"duration":[' || group_concat(total_du) || ']}}' as by_mode
	from APP_TOP_NORMAL_INNER_JOIN_GROUP_TB
	group by app, activity, screen_id, power_mode, ground_mode, screen_mode, thermal_mode, FPS, renderFps
),
APP_NORMAL_TB as (
	select '{{"type":"normal","total_du":' || APP_NORMAL_TOTAL_TB.total_du || ',"apps":[' || group_concat(by_mode) || ']}}' as by_app_normal
	from APP_NORMAL_TOTAL_TB,APP_TOP_NORMAL_JSON_TB
),
    ---- app split
APP_SPLIT_TOTAL_TB as (
	select sum(total_du) as total_du
	from agg_display_app_hourly, PARAM_VAR
	where start_ts >= PARAM_VAR.var_start_ts
		and end_ts <= PARAM_VAR.var_end_ts
		and total_du > 0
		and split_mode = 1 and parallel_mode = 0 -- split
),
APP_TOP_SPLIT_INDEX_TB as (
	select app, activity, app_secondary, activity_secondary, screen_id, sum(whole_eg) as total_eg, row_number() over (order by sum(total_du) desc) as idx
	from agg_display_app_hourly, PARAM_VAR
	where start_ts >= PARAM_VAR.var_start_ts
		and end_ts <= PARAM_VAR.var_end_ts
		and total_du > 0
		and split_mode = 1 and parallel_mode = 0 -- split
	group by app, activity, app_secondary, activity_secondary, screen_id
	limit 10
),
APP_TOP_SPLIT_INNER_JOIN_TB as (
	select *
	from agg_display_app_hourly T1, PARAM_VAR
	inner join
	APP_TOP_SPLIT_INDEX_TB T2
	on T1.app = T2.app and T1.activity = T2.activity
		and T1.app_secondary = T2.app_secondary and T1.activity_secondary = T2.activity_secondary
		and T1.screen_id = T2.screen_id
	where start_ts >= PARAM_VAR.var_start_ts
		and end_ts <= PARAM_VAR.var_end_ts
		and total_du > 0
		and screen_mode = 1
		and split_mode = 1 and parallel_mode = 0 -- split
),
APP_TOP_SPLIT_INNER_JOIN_GROUP_TB as (
	select app, activity, app_secondary, activity_secondary, screen_id, power_mode, screen_mode, thermal_mode, ground_mode
		, FPS, brightness, renderFps, sum(total_du) as total_du
		, sum(whole_eg) as total_eg, idx
	from APP_TOP_SPLIT_INNER_JOIN_TB
	group by app, activity, app_secondary, activity_secondary, screen_id, power_mode, screen_mode, thermal_mode, ground_mode, FPS, brightness, renderFps
),
APP_TOP_SPLIT_JSON_TB as (
	select '{{"app":"' || obfuscate(app) || '","activity":"' || activity || '","app_secondary":"' || obfuscate(app_secondary) || '","activity_secondary":"' || activity_secondary || '","screen_id":' || screen_id || ',"power_mode":' || power_mode || ',"ground_mode":' || ground_mode || ',"screen_mode":' || screen_mode || ',"thermal_mode":' || thermal_mode || ',"idx":' || idx || ',"fps":' || FPS || ',"renderFps":' || renderFps ||',"brightness":[' || group_concat(brightness) || '],"total_eg":[' || group_concat(total_eg) || '],"duration":[' || group_concat(total_du) || ']}}' as by_mode
	from APP_TOP_SPLIT_INNER_JOIN_GROUP_TB
	group by app, activity, app_secondary, activity_secondary, screen_id, power_mode, ground_mode, screen_mode, thermal_mode, FPS, renderFps
),
APP_SPLIT_TB as (
	select '{{"type":"split","total_du":' || APP_SPLIT_TOTAL_TB.total_du || ',"apps":[' || group_concat(by_mode) || ']}}' as by_app_split
	from APP_SPLIT_TOTAL_TB,APP_TOP_SPLIT_JSON_TB
),
    ---- app parallel
APP_PARALLEL_TOTAL_TB as (
	select sum(total_du) as total_du
	from agg_display_app_hourly, PARAM_VAR
	where start_ts >= PARAM_VAR.var_start_ts
		and end_ts <= PARAM_VAR.var_end_ts
		and total_du > 0
		and split_mode = 0 and parallel_mode = 1 -- parallel
),
APP_TOP_PARALLEL_INDEX_TB as (
	select app, activity, activity_secondary, screen_id, sum(whole_eg) as total_eg, row_number() over (order by sum(total_du) desc) as idx
	from agg_display_app_hourly, PARAM_VAR
	where start_ts >= PARAM_VAR.var_start_ts
		and end_ts <= PARAM_VAR.var_end_ts
		and total_du > 0
		and split_mode = 0 and parallel_mode = 1 -- parallel
	group by app, activity, activity_secondary, screen_id
	limit 10
),
APP_TOP_PARALLEL_INNER_JOIN_TB as (
	select *
	from agg_display_app_hourly T1, PARAM_VAR
	inner join
	APP_TOP_PARALLEL_INDEX_TB T2
	on T1.app = T2.app and T1.activity = T2.activity
		and T1.activity_secondary = T2.activity_secondary
		and T1.screen_id = T2.screen_id
	where start_ts >= PARAM_VAR.var_start_ts
		and end_ts <= PARAM_VAR.var_end_ts
		and total_du > 0
		and screen_mode = 1
		and split_mode = 0 and parallel_mode = 1 -- parallel
),
APP_TOP_PARALLEL_INNER_JOIN_GROUP_TB as (
	select app, activity, activity_secondary, screen_id, power_mode, screen_mode, thermal_mode, ground_mode
		, FPS, brightness, renderFps, sum(total_du) as total_du
		, sum(whole_eg) as total_eg, idx
	from APP_TOP_PARALLEL_INNER_JOIN_TB
	group by app, activity, activity_secondary, screen_id, power_mode, screen_mode, thermal_mode, ground_mode, FPS, brightness, renderFps
),
APP_TOP_PARALLEL_JSON_TB as (
	select '{{"app":"' || obfuscate(app) || '","activity":"' || activity || '","activity_secondary":"' || activity_secondary || '","screen_id":' || screen_id || ',"power_mode":' || power_mode || ',"ground_mode":' || ground_mode || ',"screen_mode":' || screen_mode || ',"thermal_mode":' || thermal_mode || ',"idx":' || idx || ',"fps":' || FPS || ',"renderFps":' || renderFps ||',"brightness":[' || group_concat(brightness) || '],"total_eg":[' || group_concat(total_eg) || '],"duration":[' || group_concat(total_du) || ']}}' as by_mode
	from APP_TOP_PARALLEL_INNER_JOIN_GROUP_TB
	group by app, activity, activity_secondary, screen_id, power_mode, ground_mode, screen_mode, thermal_mode, FPS, renderFps
),
APP_PARALLEL_TB as (
	select '{{"type":"parallel","total_du":' || APP_PARALLEL_TOTAL_TB.total_du || ',"apps":[' || group_concat(by_mode) || ']}}' as by_app_parallel
	from APP_PARALLEL_TOTAL_TB,APP_TOP_PARALLEL_JSON_TB
),
    ---- all type merge
APP_ALL_TYPE_TB as (
	select APP_NORMAL_TB.by_app_normal as by_app
	from APP_NORMAL_TB
	union
	select APP_SPLIT_TB.by_app_split as by_app
	from APP_SPLIT_TB
	union
	select APP_PARALLEL_TB.by_app_parallel as by_app
	from APP_PARALLEL_TB
),
APP_TB as (
	select '[' || group_concat(by_app) || ']' as by_app
	from APP_ALL_TYPE_TB
),
---- HIST_TB
HIST_JSON_TB as (
	select '{{{{"app":"' || obfuscate(app) || '", "rhist": "' || rhist || '","rsample": "' || rsample || '", "ghist": "' || ghist || '","gsample": "' || gsample || '", "bhist": "' || bhist || '", "bsample": "' || bsample || '"}}}}' as hist
	from comp_displayAgent_histInfo_intv, PARAM_VAR
	where start_ts >= PARAM_VAR.var_start_ts and end_ts <= PARAM_VAR.var_end_ts
	order by RANDOM() limit 1
),
HIST_TB as (
	select '[' || group_concat(hist) || ']' as hist
	from HIST_JSON_TB
),
---- SUM_HIST_TB
SUM_HIST_TB as (
	select '[' || PARAM_VAR.var_sum_hist || ']' as by_sumHist
	from PARAM_VAR
),
---- BRIGHT_TB
BRIGHT_JSON_TB as (
	select '{{"screen_id":' || screen_id || ',"total_du": ' || sum(total_du) || ',"brightness":' || brightness || ', "brightmode":' || brightmode || '}}' as by_bright
	from agg_displayAgent_brightness_hourly, PARAM_VAR
	where end_ts >= PARAM_VAR.var_start_ts and end_ts <= PARAM_VAR.var_end_ts
	group by screen_id, brightness, brightmode
),
BRIGHT_TB as (
	select '[' || group_concat(by_bright) || ']' as by_bright
	from BRIGHT_JSON_TB
),
---- SCREEN_NAME_TB
SCREEN_NAME_TB as (
	select '[' || PARAM_VAR.var_screen_name || ']' as screenName
	from PARAM_VAR
)
insert into agg_displayAgent_daily
select 0 as upload,
	PARAM_VAR.var_date as date,
	PARAM_VAR.var_start_ts as start_ts,
	PARAM_VAR.var_end_ts as end_ts,
	MODE_TBL.by_mode,
	APP_TB.by_app,
	TOTAL_EG_TB.energy,
	HIST_TB.hist,
	SUM_HIST_TB.by_sumHist,
	BRIGHT_TB.by_bright,
	SCREEN_NAME_TB.screenName,
	PARAM_VAR.var_version as version
from MODE_TBL,
	APP_TB,
	TOTAL_EG_TB,
	HIST_TB,
	SUM_HIST_TB,
	BRIGHT_TB,
	SCREEN_NAME_TB,
	PARAM_VAR