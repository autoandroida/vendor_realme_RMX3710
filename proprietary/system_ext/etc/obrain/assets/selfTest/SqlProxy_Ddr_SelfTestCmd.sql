create view if not exists {}.diag_obrain_Ddr_self_check as

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
	select 'ddr' as agent,
		start_ts,
		end_ts,
		screen_mode,
        thermal_mode,
        ground_mode,
        power_mode
	from comp_ddrAgent_whole_energy
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
		'comp_ddrAgent_whole_energy' as tbl_name
		from comp_ddrAgent_whole_energy
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
	'energy' as fields,
json_valid(energy) as value
from agg_ddrAgent_daily

UNION ALL

SELECT
	'top_app_by_mode' as fields,
json_valid(top_app_by_mode) as value
from agg_ddrAgent_daily

UNION ALL

SELECT
	'top_app_by_energy' as fields,
json_valid(top_app_by_energy) as value
from agg_ddrAgent_daily
),
AGG_TABLE_RESULT as (
select
	'agg_ddrAgent_daily' as tbl_name,
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
--sum_duration_check
SUM_DURATION_RESULT_TBL as (
SELECT
	'energy' as fields,
	fullkey as fk,
	value as val
FROM agg_ddrAgent_daily, json_each(energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_ddrAgent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'top_app_by_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_ddrAgent_daily, json_each(top_app_by_energy)
),
SUM_DURATION_REASON_TBL as (
SELECT
	fields || ' : ' || fk || ' : ' || key as field_index,
	key,
	json_extract(val,'$.duration') as num_val
FROM SUM_DURATION_RESULT_TBL, json_each(val)
where key = 'duration'
),
SUM_DURATION_FINAL_TBL as (
SELECT
	field_index,
	sum(value) as sum_val,
	case when sum(value) >= 0 and sum(value) < 86400 then 'pass' else 'fail' end as result
FROM SUM_DURATION_REASON_TBL, json_each(num_val)
group by field_index
),
AGG_SUM_DURATION_CHECK as (
SELECT
	'sum_duration_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
FROM SUM_DURATION_FINAL_TBL
WHERE result = 'fail'
),
--duration_check
DURATION_CHECK_RESULT_TBL as (
SELECT
	'energy' as fields,
	fullkey as fk,
	value as val
FROM agg_ddrAgent_daily, json_each(energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_ddrAgent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'top_app_by_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_ddrAgent_daily, json_each(top_app_by_energy)
),
DURATION_CHECK_REASON_TBL as (
SELECT
	fields || ' : ' || fk  || ' : ' || 'duration' as field_index,
	json_extract(val,'$.duration') as num_val
FROM DURATION_CHECK_RESULT_TBL
),
DURATION_CHECK_FINAL_TBL as (
SELECT
	field_index,
	value,
	case when value >= 0 then 'pass' else 'fail' end as result
FROM DURATION_CHECK_REASON_TBL, json_each(num_val)
),
AGG_DURATION_CHECK as (
SELECT
	'duration_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
FROM DURATION_CHECK_FINAL_TBL
WHERE result = 'fail'
),
--energy_check
ENERGY_RESULT_TBL as (
SELECT
	'energy' as fields,
	fullkey as fk,
	value as val
FROM agg_ddrAgent_daily, json_each(energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_ddrAgent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'top_app_by_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_ddrAgent_daily, json_each(top_app_by_energy)
),
ENERGY_REASON_TBL as (
SELECT
	fields || ' : ' || fk  || ' : ' || 'energy' as field_index,
	json_extract(val,'$.energy') as num_val
FROM ENERGY_RESULT_TBL
),
ENERGY_FINAL_TBL as (
SELECT
	field_index,
	value,
	case when value >= 0 then 'pass' else 'fail' end as result
FROM ENERGY_REASON_TBL, json_each(num_val)
),
AGG_ENERGY_CHECK as (
SELECT
	'energy_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
FROM ENERGY_FINAL_TBL
WHERE result = 'fail'
),
--freq_check
FREQ_RESULT_TBL as (
SELECT
	'energy' as fields,
	fullkey as fk,
	value as val
FROM agg_ddrAgent_daily, json_each(energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_ddrAgent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'top_app_by_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_ddrAgent_daily, json_each(top_app_by_energy)
),
FREQ_REASON_TBL as (
SELECT
	fields || ' : ' || fk  || ' : ' || 'freq' as field_index,
	json_extract(val,'$.freq') as num_val
FROM FREQ_RESULT_TBL
),
FREQ_FINAL_TBL as (
SELECT
	field_index,
	value,
	case when value >= 200 and  value <= 4266 then 'pass' else 'fail' end as result
FROM FREQ_REASON_TBL, json_each(num_val)
),
AGG_FREQ_CHECK as (
SELECT
	'freq_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
FROM FREQ_FINAL_TBL
WHERE result = 'fail'
)
SELECT * from AGG_FREQ_CHECK
UNION
SELECT * FROM AGG_ENERGY_CHECK
UNION
SELECT * FROM AGG_DURATION_CHECK
UNION
SELECT * FROM AGG_SUM_DURATION_CHECK
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