with
PARAM_VAR as (
    select
    %llu as var_start_ts,
    %llu as var_end_ts
)
, EXT_CALLER_TB as (
	select start_ts, end_ts, service_name, service_proc_name, screen_mode, foreground_app,
	value as caller_uid_name,
	json_extract(caller_proc_names, fullkey) as caller_proc_name,
	json_extract(caller_thread_names, fullkey) as caller_thread_name,
	json_extract(caller_calltimes, fullkey) as caller_calltimes
	from comp_binderstats_binderagent_backward, json_each(caller_uid_names), PARAM_VAR
	where start_ts >= PARAM_VAR.var_start_ts and end_ts <= PARAM_VAR.var_end_ts and caller_uid_names != 'unknown'
)
, EXT_UNKNOWN_CALLER_TB as (
	select start_ts, end_ts,
	json_extract(service_name, fullkey) as service_name,
	json_extract(service_proc_name, fullkey) as service_proc_name, screen_mode, foreground_app,
	'unknown' as caller_uid_name,
	'unknown' as caller_proc_name,
	'unknown' as caller_thread_name,
	value as caller_calltimes
	from comp_binderstats_binderagent_backward, json_each(caller_calltimes), PARAM_VAR
	where start_ts >= PARAM_VAR.var_start_ts and end_ts <= PARAM_VAR.var_end_ts and caller_uid_names = 'unknown'
)
, ALL_EXT_CALLER_TB as (
    select * from EXT_CALLER_TB
    union
    select * from EXT_UNKNOWN_CALLER_TB
)
insert into agg_binderstats_binderagent_hourly
select
PARAM_VAR.var_start_ts AS start_ts,
PARAM_VAR.var_end_ts AS end_ts,
screen_mode, (foreground_app == caller_uid_name) as ground_mode,
service_name, service_proc_name, caller_uid_name, caller_proc_name, caller_thread_name, sum(caller_calltimes) as caller_calltimes
from ALL_EXT_CALLER_TB, PARAM_VAR
where screen_mode != -1
group by service_name, service_proc_name, caller_uid_name, caller_proc_name, caller_thread_name, screen_mode, ground_mode
order by service_name asc, caller_calltimes desc