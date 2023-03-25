create view if not exists {}.diag_obrain_Dsp_self_check as

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
	select 'dsp' as agent,
		start_ts,
		end_ts,
		screen_mode,
        thermal_mode,
        ground_mode,
        power_mode
	from comp_dsp_data
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
		'comp_dsp_data' as tbl_name
		from comp_dsp_data
	UNION
	select
		case when count(*) = 0 then 'fail' else 'pass' end as result,
		'comp_cameraAgent_explorer' as tbl_name
		from comp_cameraAgent_explorer
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
	'by_mode' as fields,
json_valid(by_mode) as value
from agg_dsp_app_daily

UNION ALL

SELECT
	'by_app' as fields,
json_valid(by_app) as value
from agg_dsp_app_daily

UNION ALL

SELECT
	'energy' as fields,
json_valid(energy) as value
from agg_dsp_app_daily
),
AGG_TABLE_RESULT as (
select
	'agg_dsp_app_daily' as tbl_name,
	value,
	fields
from AGG_TABLE
where fields in('by_mode','by_app','energy')
)
,
AGG_TABLE_JSON_CHECK as (
SELECT
	'json_check' as item,
	case when count(*) != 0 then 'fail' else 'pass' end as result,
	count(*) as fail_cnt,
	json_group_array(tbl_name || ':' ||fields) as detail
from AGG_TABLE_RESULT
where value = 0
),
--duration_check
DURATION_RESULT_TBL as (
SELECT
	'by_mode' as fields,
	value as val
FROM agg_dsp_app_daily, json_each(by_mode)

UNION ALL

SELECT
	'by_app' as fields,
	value as val
FROM agg_dsp_app_daily, json_each(by_app)

UNION ALL

SELECT
	'energy' as fields,
	value as val
FROM agg_dsp_app_daily, json_each(energy)
),
DURATION_REASON_TBL as (
SELECT
	'agg_dsp_app_daily' || ' : ' || fields as field_index,
	sum(value) as num_val,
	case when sum(value) >= 0 and sum(value) < 86400000 then 'pass' else 'fail' end as result
FROM DURATION_RESULT_TBL, json_each(val)
where key = 'duration'
group by fields
),
AGG_DURATION_CHECK as (
SELECT
	'duration_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fial_cnt,
	json_group_array(field_index) as detail
FROM DURATION_REASON_TBL
WHERE result = 'fail'
),
--whole_eg_check
WHOLE_EG_RESULT_TBL as (
SELECT
	'by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_dsp_app_daily, json_each(by_mode)

UNION ALL

SELECT
	'by_app' as fields,
	fullkey as fk,
	value as val
FROM agg_dsp_app_daily, json_each(by_app)

UNION ALL

SELECT
	'energy' as fields,
	fullkey as fk,
	value as val
FROM agg_dsp_app_daily, json_each(energy)
),
WHOLE_EG_REASON_TBL as (
SELECT
	fields || ' : ' || fk || ' : ' || key as field_index,
	value,
	case when cast(value as int) >= 0 then 'pass' else 'fail' end as result
FROM WHOLE_EG_RESULT_TBL, json_each(val)
where key = 'whole_eg'
),
AGG_WHOLE_EG_CHECK as (
SELECT
	'whole_eg_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fial_cnt,
	json_group_array(field_index) as detail
FROM WHOLE_EG_REASON_TBL
WHERE result = 'fail'
),
--effFreq_check
EFFFREQ_RESULT_TBL as (
SELECT
	'by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_dsp_app_daily, json_each(by_mode)

UNION ALL

SELECT
	'by_app' as fields,
	fullkey as fk,
	value as val
FROM agg_dsp_app_daily, json_each(by_app)

UNION ALL

SELECT
	'energy' as fields,
	fullkey as fk,
	value as val
FROM agg_dsp_app_daily, json_each(energy)
),
EFFFREQ_REASON_TBL as (
SELECT
	fields || ' : ' || fk || ' : ' || key as field_index,
	value,
	case when cast(value as int) >= 0 and cast(value as int) <= 1364 then 'pass' else 'fail' end as result
FROM EFFFREQ_RESULT_TBL, json_each(val)
where key = 'effFreq'
),
AGG_EFFFREQ_CHECK as (
SELECT
	'effFreq_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fial_cnt,
	json_group_array(field_index) as detail
FROM EFFFREQ_REASON_TBL
WHERE result = 'fail'
),
--cycle_count_check
CYCLE_COUNT_RESULT_TBL as (
SELECT
	'by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_dsp_app_daily, json_each(by_mode)

UNION ALL

SELECT
	'by_app' as fields,
	fullkey as fk,
	value as val
FROM agg_dsp_app_daily, json_each(by_app)

UNION ALL

SELECT
	'energy' as fields,
	fullkey as fk,
	value as val
FROM agg_dsp_app_daily, json_each(energy)
),
CYCLE_COUNT_REASON_TBL as (
SELECT
	fields || ' : ' || fk || ' : ' || key as field_index,
	value,
	case when cast(value as int) >= 0 then 'pass' else 'fail' end as result
FROM CYCLE_COUNT_RESULT_TBL, json_each(val)
where key = 'cycle_count'
),
AGG_CYCLE_COUNT_CHECK as (
SELECT
	'cycle_count_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fial_cnt,
	json_group_array(field_index) as detail
FROM CYCLE_COUNT_REASON_TBL
WHERE result = 'fail'
),
--cdsp_sleep_duration_check
CDSP_SL_DUR_RESULT_TBL as (
SELECT
	'by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_dsp_app_daily, json_each(by_mode)

UNION ALL

SELECT
	'by_app' as fields,
	fullkey as fk,
	value as val
FROM agg_dsp_app_daily, json_each(by_app)

UNION ALL

SELECT
	'energy' as fields,
	fullkey as fk,
	value as val
FROM agg_dsp_app_daily, json_each(energy)
),
CDSP_SL_DUR_CONDITION_TBL as (
SELECT
	fields || ' : ' || fk as dur_idx,
	value as dur_val
FROM CDSP_SL_DUR_RESULT_TBL, json_each(val)
WHERE key = 'duration'
),
CDSP_SL_DUR_REASON_TBL as (
SELECT
	fields || ' : ' || fk as field_index,
	value as cdsp_val
FROM CDSP_SL_DUR_RESULT_TBL, json_each(val)
WHERE key = 'cdsp_sleep_duration'
),
CDSP_SL_DUR_FINAL_TBL as (
SELECT
	*,
	case when cast(cdsp_val as int) <= cast(dur_val as int) then 'pass' else 'fail' end as result
FROM CDSP_SL_DUR_CONDITION_TBL, CDSP_SL_DUR_REASON_TBL
ON dur_idx = field_index
),
AGG_CDSP_SL_DUR_CHECK as (
SELECT
	'cdsp_sleep_duration_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fial_cnt,
	json_group_array(field_index) as detail
FROM CDSP_SL_DUR_FINAL_TBL
WHERE result = 'fail'
)
SELECT * FROM AGG_CDSP_SL_DUR_CHECK
UNION
SELECT * FROM AGG_CYCLE_COUNT_CHECK
UNION
SELECT * FROM AGG_EFFFREQ_CHECK
UNION
SELECT * FROM AGG_WHOLE_EG_CHECK
UNION
SELECT * FROM AGG_DURATION_CHECK
UNION
SELECT * FROM AGG_TABLE_JSON_CHECK
UNION
SELECT * FROM COMP_TABLE_NULL_CHECK
UNION
SELECT * FROM SCREEN_MODE_FINAL_TBL
UNION
SELECT * FROM THERMAL_MODE_FINAL_TBL
UNION
SELECT * FROM POWER_MODE_FINAL_TBL
;