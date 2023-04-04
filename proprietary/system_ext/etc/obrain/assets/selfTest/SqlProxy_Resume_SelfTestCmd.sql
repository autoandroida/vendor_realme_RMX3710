create view if not exists {}.diag_obrain_Resume_self_check as

with SCREEN_MODE_TBL as (
	select *
	FROM (
			select *,
				lead(mode) over(
					order by start_ts
				) as next_mode
			from (
					select otime as start_ts,
						lead(otime) over(
							order by otime
						) as end_ts,
						state as mode
					from (
							select otime,
								state
							from trig_displayOnOff_screenState_eventAgent
							UNION
							select otime,
								-1
							from log_running_event
							where EVENT = 'START'
						)
				)
		)
	where mode <> -1
		and next_mode <> -1
		and end_ts is not null
),
THERMAL_MODE_TBL as (
	select *
	FROM (
			select *,
				lead(mode) over(
					order by start_ts
				) as next_mode
			from (
					select otime as start_ts,
						lead(otime) over(
							order by otime
						) as end_ts,
						state as mode
					from (
							select otime,
								state
							from trig_state_thermal_eventAgent
							UNION
							select otime,
								-1
							from log_running_event
							where EVENT = 'START'
						)
				)
		)
	where mode <> -1
		and next_mode <> -1
		and end_ts is not null
),
POWER_MODE_TBL as (
	select *
	FROM (
			select *,
				lead(mode) over(
					order by start_ts
				) as next_mode
			from (
					select otime as start_ts,
						lead(otime) over(
							order by otime
						) as end_ts,
						state as mode
					from (
							select otime,
								state
							from trig_charging_chargerState_eventAgent
							UNION
							select otime,
								-1
							from log_running_event
							where EVENT = 'START'
						)
				)
		)
	where mode <> -1
		and next_mode <> -1
		and end_ts is not null
),
AGENT_TBL as (
	select 'resume' as agent,
		start_ts,
		end_ts,
		screen_mode,
        thermal_mode,
        ground_mode,
        power_mode
	from comp_resumeAgent_app_backward
	where screen_mode <> -1 and thermal_mode <> -1 and ground_mode <> -1 and power_mode <> -1
),
SCREEN_MODE_RESULT_TBL as (
	select AGENT_TBL.agent,
		json_insert(
			'{{}}',
			'$.agent',
			AGENT_TBL.agent,
			'$.timestamp',
			SCREEN_MODE_TBL.start_ts || ',' || SCREEN_MODE_TBL.end_ts || ',' || AGENT_TBL.start_ts || ',' || AGENT_TBL.end_ts,
			'$.screen_mode',
			SCREEN_MODE_TBL.mode || ',' || AGENT_TBL.screen_mode
		) as detail,
		case
			when SCREEN_MODE_TBL.mode = AGENT_TBL.screen_mode then 'pass'
			else 'fail'
		end as result
	from SCREEN_MODE_TBL
		inner join AGENT_TBL on AGENT_TBL.start_ts >= SCREEN_MODE_TBL.start_ts
		and AGENT_TBL.end_ts <= SCREEN_MODE_TBL.end_ts
),
SCREEN_MODE_REASON_TBL as (
	select count(*) as fail_cnt,
		'[' || group_concat(detail) || ']' detail
	from SCREEN_MODE_RESULT_TBL
	where result <> 'pass'
),
SCREEN_MODE_FINAL_TBL as (
    select 'screen_mode_check' as item,
        case
            when fail_cnt > 0 then 'fail'
            else 'pass'
        end as result,
        fail_cnt,
        detail
    from SCREEN_MODE_REASON_TBL
),
THERMAL_MODE_RESULT_TBL as (
	select AGENT_TBL.agent,
		json_insert(
			'{{}}',
			'$.agent',
			AGENT_TBL.agent,
			'$.timestamp',
			THERMAL_MODE_TBL.start_ts || ',' || THERMAL_MODE_TBL.end_ts || ',' || AGENT_TBL.start_ts || ',' || AGENT_TBL.end_ts,
			'$.thermal_mode',
			THERMAL_MODE_TBL.mode || ',' || AGENT_TBL.thermal_mode
		) as detail,
		case
			when THERMAL_MODE_TBL.mode = AGENT_TBL.thermal_mode then 'pass'
			else 'fail'
		end as result
	from THERMAL_MODE_TBL
		inner join AGENT_TBL on AGENT_TBL.start_ts >= THERMAL_MODE_TBL.start_ts
		and AGENT_TBL.end_ts <= THERMAL_MODE_TBL.end_ts
),
THERMAL_MODE_REASON_TBL as (
	select count(*) as fail_cnt,
		'[' || group_concat(detail) || ']' detail
	from THERMAL_MODE_RESULT_TBL
	where result <> 'pass'
),
THERMAL_MODE_FINAL_TBL as (
    select 'thermal_mode_check' as item,
        case
            when fail_cnt > 0 then 'fail'
            else 'pass'
        end as result,
        fail_cnt,
        detail
    from THERMAL_MODE_REASON_TBL
),
POWER_MODE_RESULT_TBL as (
	select AGENT_TBL.agent,
		json_insert(
			'{{}}',
			'$.agent',
			AGENT_TBL.agent,
			'$.timestamp',
			POWER_MODE_TBL.start_ts || ',' || POWER_MODE_TBL.end_ts || ',' || AGENT_TBL.start_ts || ',' || AGENT_TBL.end_ts,
			'$.power_mode',
			POWER_MODE_TBL.mode || ',' || AGENT_TBL.power_mode
		) as detail,
		case
			when POWER_MODE_TBL.mode = AGENT_TBL.power_mode then 'pass'
			else 'fail'
		end as result
	from POWER_MODE_TBL
		inner join AGENT_TBL on AGENT_TBL.start_ts >= POWER_MODE_TBL.start_ts
		and AGENT_TBL.end_ts <= POWER_MODE_TBL.end_ts
),
POWER_MODE_REASON_TBL as (
	select count(*) as fail_cnt,
		'[' || group_concat(detail) || ']' detail
	from POWER_MODE_RESULT_TBL
	where result <> 'pass'
),
POWER_MODE_FINAL_TBL as (
    select 'power_mode_check' as item,
        case
            when fail_cnt > 0 then 'fail'
            else 'pass'
        end as result,
        fail_cnt,
        detail
    from POWER_MODE_REASON_TBL
),
--empty_table_check
COMP_TBL as (
	select
		case when count(*) = 0 then 'fail' else 'pass' end as result,
		'comp_resumeAgent_app_backward' as tbl_name
		from comp_resumeAgent_app_backward
),
COMP_TABLE_NULL_CHECK as (
	SELECT
		'empty_table_check' as item,
		case when count(*) != 0 then 'fail'
			else 'pass' end as result,
		count(*) as fail_cnt,
		json_group_array('tbl_name:' || tbl_name ) as detail
	from COMP_TBL
	where result = 'fail'
),
--json_table_check
AGG_TABLE as
(
SELECT
	'wakeup_by_mode' as fields,
json_valid(wakeup_by_mode) as value
from agg_resumeAgent_subSystem_daily

UNION ALL

SELECT
	'long_standby_statistic' as fields,
json_valid(long_standby_statistic) as value
from agg_resumeAgent_subSystem_daily

UNION ALL

SELECT
	'subsystem' as fields,
json_valid(subsystem) as value
from agg_resumeAgent_subSystem_daily

UNION ALL

SELECT
	'rpmh_masters' as fields,
json_valid(rpmh_masters) as value
from agg_resumeAgent_subSystem_daily

UNION ALL

SELECT
	'deep_sleep_levels' as fields,
json_valid(deep_sleep_levels) as value
from agg_resumeAgent_subSystem_daily
),
AGG_TABLE_RESULT as (
select
	'agg_resumeAgent_subSystem_daily' as tbl_name,
	value,
	fields
from AGG_TABLE
),
AGG_TABLE_JSON_CHECK as (
SELECT
	'json_check' as item,
	case when count(*) != 0 then 'fail' else 'pass' end as result,
	count(*) as fail_cnt,
	json_group_array(tbl_name || ':' ||fields) as detail
from AGG_TABLE_RESULT
where value = 0
),
--resume_cnt_check
RESUME_CNT_RESULT_TBL as (
select
	'wakeup_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_resumeAgent_subSystem_daily, json_each(wakeup_by_mode)
),
RESUME_CNT_REASON_TBL as (
SELECT
	fields || ' : ' || fk || ' : ' || key as field_index,
	key,
	value,
	case when value > 0 and value < 10000 then 'pass' else 'fail' end as result
FROM RESUME_CNT_RESULT_TBL, json_each(val)
WHERE key = 'resume_cnt'
),
AGG_RESUME_CNT_CHECK as (
SELECT
	'resume_cnt_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
FROM RESUME_CNT_REASON_TBL
WHERE result = 'fail'
),
--awa_sleep_time_check
AWA_SLEEP_TIME_RESULT_TBL as (
select
	'agg_resumeAgent_subSystem_daily' as tbl,
	'wakeup_by_mode' as fields,
	value as val
FROM agg_resumeAgent_subSystem_daily, json_each(wakeup_by_mode)
),
AWA_SLEEP_TIME_REASON_TBL as (
SELECT
	tbl || ' : ' || fields as field_index,
	sum(value) as sum_value,
	case when sum(value) >= 0 and sum(value) <= 86400 * 1000 then 'pass' else 'fail' end as result
FROM AWA_SLEEP_TIME_RESULT_TBL, json_each(val)
WHERE key = 'awake_time' or key = 'sleep_time'
GROUP by field_index
),
AGG_AWA_SLEEP_TIME_CHECK as (
SELECT
	'awa_sleep_time_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
FROM AWA_SLEEP_TIME_REASON_TBL
WHERE result = 'fail'
),
--subsystem_not_null_check
SUBSYSTEM_NOT_NULL_RESULT_TBL as (
SELECT
	*
FROM agg_resumeAgent_subSystem_daily
WHERE subsystem IS NOT NULL
),
SUBSYSTEM_NOT_NULL_REASON_TBL as (
SELECT
	'subsystem_not_null_check' as item,
	case when count(*) != 0 then 'pass' else 'fail' end as result
FROM SUBSYSTEM_NOT_NULL_RESULT_TBL
),
AGG_SUBSYSTEM_NOT_NULL_CHECK as (
SELECT
	*,
	case when result = 'fail' then 1 else 0 end as fail_cnt,
	case when result = 'fail' then json_group_array('agg_resumeAgent_subSystem_daily') else null end as detail
FROM SUBSYSTEM_NOT_NULL_REASON_TBL
),
--pow_scr_mode_check
POW_SCR_MODE_RESULT_TBL as (
select
	fullkey as fk,
	value as val
FROM agg_resumeAgent_subSystem_daily, json_each(wakeup_by_mode)
)
,
POW_SCR_MODE_REASON_TBL as (
SELECT
	fk,
	json_extract(val,'$.cnt') as cnt_val,
	json_extract(val,'$.power_mode') as pow_val,
	json_extract(val,'$.screen_mode') as scr_val
from POW_SCR_MODE_RESULT_TBL
)
,
POW_SCR_MODE_FINAL_TBL as (
SELECT
	fk,
	sum(value) as cnt_value,
	pow_val,
	scr_val,
	case when pow_val = 1 or scr_val = 1 and sum(value) = 0 then 'pass' else 'fail' end as result
FROM POW_SCR_MODE_REASON_TBL, json_each(cnt_val)
GROUP by fk
)
,
AGG_POW_SCR_MODE_CHECK as (
SELECT
	'pow_scr_mode_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array('wakeup_by_mode' || ':' || fk ) as detail
FROM POW_SCR_MODE_FINAL_TBL
WHERE result = 'fail'
)
SELECT * FROM AGG_POW_SCR_MODE_CHECK
UNION
SELECT * FROM AGG_SUBSYSTEM_NOT_NULL_CHECK
UNION
SELECT * FROM AGG_AWA_SLEEP_TIME_CHECK
UNION
SELECT * FROM AGG_RESUME_CNT_CHECK
UNION
SELECT * FROM AGG_TABLE_JSON_CHECK
union
select * from COMP_TABLE_NULL_CHECK
union
select * from SCREEN_MODE_FINAL_TBL
union
select * from THERMAL_MODE_FINAL_TBL
union
select * from POWER_MODE_FINAL_TBL
;