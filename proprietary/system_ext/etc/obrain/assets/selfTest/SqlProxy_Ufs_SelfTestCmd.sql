create view if not exists {}.diag_obrain_Ufs_self_check as

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
CHARGE_MODE_TBL as (
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
	select 'ufs' as agent,
		start_ts,
		end_ts,
		screen_mode,
        thermal_mode,
        ground_mode,
        charge_mode
	from comp_table_whole_ufs_energy
	where screen_mode <> -1 and thermal_mode <> -1 and ground_mode <> -1 and charge_mode <> -1
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
CHARGE_MODE_RESULT_TBL as (
	select AGENT_TBL.agent,
		json_insert(
			'{{}}',
			'$.agent',
			AGENT_TBL.agent,
			'$.timestamp',
			CHARGE_MODE_TBL.start_ts || ',' || CHARGE_MODE_TBL.end_ts || ',' || AGENT_TBL.start_ts || ',' || AGENT_TBL.end_ts,
			'$.power_mode',
			CHARGE_MODE_TBL.mode || ',' || AGENT_TBL.charge_mode
		) as detail,
		case
			when CHARGE_MODE_TBL.mode = AGENT_TBL.charge_mode then 'pass'
			else 'fail'
		end as result
	from CHARGE_MODE_TBL
		inner join AGENT_TBL on AGENT_TBL.start_ts >= CHARGE_MODE_TBL.start_ts
		and AGENT_TBL.end_ts <= CHARGE_MODE_TBL.end_ts
),
CHARGE_MODE_REASON_TBL as (
	select count(*) as fail_cnt,
		'[' || group_concat(detail) || ']' detail
	from CHARGE_MODE_RESULT_TBL
	where result <> 'pass'
),
CHARGE_MODE_FINAL_TBL as (
    select 'charge_mode_check' as item,
        case
            when fail_cnt > 0 then 'fail'
            else 'pass'
        end as result,
        fail_cnt,
        detail
    from CHARGE_MODE_REASON_TBL
),
--empty_table_check
COMP_TBL as (
	select
		case when count(*) = 0 then 'fail' else 'pass' end as result,
		'comp_table_whole_ufs_energy' as tbl_name
		from comp_table_whole_ufs_energy
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
from agg_ufs_app_daily

UNION ALL

SELECT
	'top_app_by_mode' as fields,
json_valid(top_app_by_mode) as value
from agg_ufs_app_daily

UNION ALL

SELECT
	'top_app_by_energy' as fields,
json_valid(top_app_by_energy) as value
from agg_ufs_app_daily
),
AGG_TABLE_RESULT as (
select
	'agg_ufs_app_daily' as tbl_name,
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
--xx_eg_check
XX_EG_RESULT_TBL as (
SELECT
	'energy' as fields,
	fullkey as fk,
	value as val
FROM agg_ufs_app_daily, json_each(energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_ufs_app_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'top_app_by_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_ufs_app_daily, json_each(top_app_by_energy)
),
XX_EG_REASON_TBL as (
SELECT
	fields || ' : ' || fk || ' : ' || key as field_index,
	key,
	value,
	case when value > 0 then 'pass' else 'fail' end as result
FROM XX_EG_RESULT_TBL, json_each(val)
WHERE key like '%_eg'
),
AGG_XX_EG_CHECK as (
SELECT
	'xx_eg_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
FROM XX_EG_REASON_TBL
where result = 'fail'
),
--xx_du_check
XX_DU_RESULT_TBL as (
SELECT
	'agg_ufs_app_daily' as tbl,
	value as val
FROM agg_ufs_app_daily, json_each(energy)

UNION ALL

SELECT
	'agg_ufs_app_daily' as tbl,
	value as val
FROM agg_ufs_app_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'agg_ufs_app_daily' as tbl,
	value as val
FROM agg_ufs_app_daily, json_each(top_app_by_energy)
),
XX_DU_REASON_TBL as (
SELECT
	tbl || ' : ' || key as field_index,
	key,
	sum(value) as sum_value,
	case when sum(value) > 0 and sum(value) < 90000 * 1000 then 'pass' else 'fail' end as result
FROM XX_DU_RESULT_TBL, json_each(val)
WHERE key like '%du'
),
AGG_XX_DU_CHECK as (
SELECT
	'xx_du_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
FROM XX_DU_REASON_TBL
WHERE result = 'fail'
)
SELECT * from AGG_XX_DU_CHECK
UNION
SELECT * FROM AGG_XX_EG_CHECK
UNION
SELECT * FROM AGG_TABLE_JSON_CHECK
UNION
SELECT * FROM COMP_TABLE_NULL_CHECK
UNION
SELECT * FROM SCREEN_MODE_FINAL_TBL
UNION
SELECT * FROM THERMAL_MODE_FINAL_TBL
UNION
SELECT * FROM CHARGE_MODE_FINAL_TBL
;