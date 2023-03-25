with
PARAM_VAR as (
    select
    %s as var_date,
    %llu  as var_start_ts,
    %llu  as var_end_ts,
    %d as var_version,
    %d as var_max_service_count,
    %d as var_max_callers_count_per_service,
    %d as var_min_service_total_calltimes
)
, ALL_SERTICE_TABLE as (
    select service_name, service_proc_name, obfuscate(caller_uid_name) as caller_uid_name, caller_proc_name, caller_thread_name, screen_mode, ground_mode,
        sum(caller_calltimes) as caller_calltimes
    from agg_binderstats_binderagent_hourly, PARAM_VAR
    where end_ts <= PARAM_VAR.var_end_ts
    group by service_name, service_proc_name, caller_uid_name, caller_proc_name, caller_thread_name, screen_mode, ground_mode
)
, ALL_SERVICE_IDX_TABLE as (
    select service_name, service_proc_name, caller_uid_name, caller_proc_name, caller_thread_name, screen_mode, ground_mode, caller_calltimes,
        row_number() over (partition by service_name order by caller_calltimes desc) as idx
    from ALL_SERTICE_TABLE, PARAM_VAR
)
, ALL_SERVICE_IDX_LIMIT_TABLE as (
    select service_name, service_proc_name, caller_uid_name, caller_proc_name, caller_thread_name, screen_mode, ground_mode, caller_calltimes
    from ALL_SERVICE_IDX_TABLE, PARAM_VAR
    where idx <= PARAM_VAR.var_max_callers_count_per_service
)
, SERVICE_CALLER_MERGED_TABLE as (
    select service_name, service_proc_name, sum(caller_calltimes) as total_calltimes
    , '[' || group_concat( '"' ||caller_uid_name || '"') || ']' as caller_uid_names
    , '[' || group_concat( '"' ||caller_proc_name || '"') || ']' as caller_proc_names
    , '[' || group_concat( '"' ||caller_thread_name || '"') || ']' as caller_thread_names
	, '[' || group_concat(screen_mode) || ']' as screen_modes
	, '[' || group_concat(ground_mode) || ']' as ground_modes
    , '[' || group_concat(caller_calltimes) || ']' as caller_calltimes
    from ALL_SERVICE_IDX_LIMIT_TABLE
    group by service_name
    order by total_calltimes desc
)
, SERVICE_CALLER_MERGED_ONECOLUME_TABLE as (
    select '{' || '"service_name":"' || service_name || '", '
    || '"service_proc_name":"' || service_proc_name || '",'
    || '"total_calltimes":' || total_calltimes || ','
    || '"caller_uid_names":' || group_concat(caller_uid_names) || ','
    || '"caller_proc_names":' || group_concat(caller_proc_names) || ','
    || '"caller_thread_names":' || group_concat(caller_thread_names) || ','
	|| '"screen_modes":' || group_concat(screen_modes) || ','
	|| '"ground_modes":' || group_concat(ground_modes) || ','
    || '"caller_calltimes":' || group_concat(caller_calltimes) || '}' as service_stats
    , row_number() over (order by total_calltimes desc) as idx
    from SERVICE_CALLER_MERGED_TABLE, PARAM_VAR
    where total_calltimes >= PARAM_VAR.var_min_service_total_calltimes
    group by service_name
    order by total_calltimes desc
)
, SERVICE_CALLER_MERGED_ONECOLUME_LIMIT_TABLE as (
    select service_stats
    from SERVICE_CALLER_MERGED_ONECOLUME_TABLE, PARAM_VAR
    where idx <= PARAM_VAR.var_max_service_count
)
, BINDER_STATS_TABLE as (
    select '[' || group_concat(service_stats) || ']' as all_service_stats
    from SERVICE_CALLER_MERGED_ONECOLUME_LIMIT_TABLE
)
insert into agg_binderagent_daily
select
PARAM_VAR.var_date as date, PARAM_VAR.var_start_ts as start_ts, PARAM_VAR.var_end_ts as end_ts, '0' as upload,
BINDER_STATS_TABLE.all_service_stats as binder_stats,
PARAM_VAR.var_version as version
from BINDER_STATS_TABLE, PARAM_VAR
