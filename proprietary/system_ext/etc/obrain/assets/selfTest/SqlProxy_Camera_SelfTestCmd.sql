create view if not exists {}.diag_obrain_Camera_self_check as

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
	select 'camera' as agent,
		start_ts,
		end_ts,
		screen_mode,
        thermal_mode,
        ground_mode,
        power_mode
	from comp_cameraAgent_appPower_intv
	where screen_mode <> -1 and thermal_mode <> -1 and ground_mode <> -1 and power_mode <> -1
	union
		select 'camera' as agent,
		start_ts,
		end_ts,
		screen_mode,
        thermal_mode,
        ground_mode,
        power_mode
	from comp_cameraAgent_explorer
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
		'comp_cameraAgent_appPower_intv' as tbl_name
		from comp_cameraAgent_appPower_intv
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
	'energy' as fields,
json_valid(energy) as value
from agg_cameraAgent_daily

UNION ALL

SELECT
	'top_app_by_mode' as fields,
json_valid(top_app_by_mode) as value
from agg_cameraAgent_daily

UNION ALL

SELECT
	'top_app_by_energy' as fields,
json_valid(top_app_by_energy) as value
from agg_cameraAgent_daily

UNION ALL

SELECT
	'explorer' as fields,
json_valid(explorer) as value
from agg_cameraAgent_daily
),
AGG_TABLE_RESULT as (
select
	'agg_cameraAgent_daily' as tbl_name,
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
--laser_eg_check
LASER_EG_RESULT_TBL as (
SELECT
	'energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'top_app_by_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(top_app_by_energy)
),
LASER_EG_REASON_TBL as (
SELECT
	fields || ' : ' || fk || ' : ' || key as field_index,
	value,
	case when value >= 0 then 'pass' else 'fail' end as result
FROM LASER_EG_RESULT_TBL, json_each(val)
where key = 'laser_eg'
),
AGG_LASER_EG_CHECK as (
SELECT
	'laser_eg_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fial_cnt,
	json_group_array(field_index) as detail
FROM LASER_EG_REASON_TBL
WHERE result = 'fail'
),
--osi_eg_check
OSI_EG_RESULT_TBL as (
SELECT
	'energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'top_app_by_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(top_app_by_energy)
),
OSI_EG_REASON_TBL as (
SELECT
	fields || ' : ' || fk || ' : ' || key as field_index,
	value,
	case when value >= 0 then 'pass' else 'fail' end as result
FROM OSI_EG_RESULT_TBL, json_each(val)
where key = 'osi_eg'
),
AGG_OSI_EG_CHECK as (
SELECT
	'osi_eg_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fial_cnt,
	json_group_array(field_index) as detail
FROM OSI_EG_REASON_TBL
WHERE result = 'fail'
),
--motor_eg_check
MOTOR_EG_RESULT_TBL as (
SELECT
	'energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'top_app_by_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(top_app_by_energy)
),
MOTOR_EG_REASON_TBL as (
SELECT
	fields || ' : ' || fk || ' : ' || key as field_index,
	value,
	case when value >= 0 then 'pass' else 'fail' end as result
FROM MOTOR_EG_RESULT_TBL, json_each(val)
where key = 'motor_eg'
),
AGG_MOTOR_EG_CHECK as (
SELECT
	'motor_eg_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fial_cnt,
	json_group_array(field_index) as detail
FROM MOTOR_EG_REASON_TBL
WHERE result = 'fail'
),
--camera_Id_check
CAMERA_ID_RESULT_TBL as (
SELECT
	'energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'top_app_by_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(top_app_by_energy)
),
CAMERA_ID_REASON_TBL as (
SELECT
	fields || ' : ' || fk || ' : ' || key as field_index,
	value,
	case when cast(value as int) in(0,1,2,3,4) or cast(value as int) is null then 'pass' else 'fail' end as result
FROM CAMERA_ID_RESULT_TBL, json_each(val)
where key = 'camera_Id'
),
AGG_CAMERA_ID_CHECK as (
SELECT
	'camera_Id_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fial_cnt,
	json_group_array(field_index) as detail
FROM CAMERA_ID_REASON_TBL
WHERE result = 'fail'
),
--camera_number_check
CAMERA_NUMBER_RESULT_TBL as (
SELECT
	'energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'top_app_by_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(top_app_by_energy)
),
CAMERA_NUMBER_REASON_TBL as (
SELECT
	fields || ' : ' || fk || ' : ' || key as field_index,
	value,
	case when value >= 0 and value <= 4 then 'pass' else 'fail' end as result
FROM CAMERA_NUMBER_RESULT_TBL, json_each(val)
where key = 'camera_number'
),
AGG_CAMERA_NUMBER_CHECK as (
SELECT
	'camera_number_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fial_cnt,
	json_group_array(field_index) as detail
FROM CAMERA_NUMBER_REASON_TBL
WHERE result = 'fail'
),
--total_dura_check
TOTAL_DURA_RESULT_TBL as (
SELECT
	'energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'top_app_by_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(top_app_by_energy)
),
TOTAL_DURA_REASON_TBL as (
SELECT
	fields || ' : ' || fk || ' : ' || key as field_index,
	value,
	case when value < 86400 then 'pass' else 'fail' end as result
FROM TOTAL_DURA_RESULT_TBL, json_each(val)
where key = 'total_du' or key = 'duration'
),
AGG_TOTAL_DURA_CHECK as (
SELECT
	'total_dura_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fial_cnt,
	json_group_array(field_index) as detail
FROM TOTAL_DURA_REASON_TBL
WHERE result = 'fail'
),
--total_check
TOTAL_RESULT_TBL as (
SELECT
	'energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'top_app_by_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(top_app_by_energy)
),
TOTAL_REASON_TBL as (
SELECT
	fields || ' : ' || fk || ' : ' || key as field_index,
	value,
	case when value <= 0 then 'pass' else 'fail' end as result
FROM TOTAL_RESULT_TBL, json_each(val)
where key = 'total_du' or key = 'duration'
),
AGG_TOTAL_CHECK as (
SELECT
	'total_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fial_cnt,
	json_group_array(field_index) as detail
FROM TOTAL_REASON_TBL
WHERE result = 'fail'
),
--fps_check
FPS_RESULT_TBL as (
SELECT
	'energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'top_app_by_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(top_app_by_energy)
),
FPS_REASON_TBL as (
SELECT
	fields || ' : ' || fk || ' : ' || key as field_index,
	value,
	case when value >= 0 and value <= 60 then 'pass' else 'fail' end as result
FROM FPS_RESULT_TBL, json_each(val)
where key = 'fps'
),
AGG_FPS_CHECK as (
SELECT
	'fps_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fial_cnt,
	json_group_array(field_index) as detail
FROM FPS_REASON_TBL
WHERE result = 'fail'
),
--camera_eg_check
CAMERA_EG_RESULT_TBL as (
SELECT
	'energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'top_app_by_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cameraAgent_daily, json_each(top_app_by_energy)
),
CAMERA_EG_REASON_TBL as (
SELECT
	fields || ' : ' || fk || ' : ' || key as field_index,
	value,
	case when value >= 0 then 'pass' else 'fail' end as result
FROM CAMERA_EG_RESULT_TBL, json_each(val)
where key = 'camera_eg'
),
AGG_CAMERA_EG_CHECK as (
SELECT
	'camera_eg_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fial_cnt,
	json_group_array(field_index) as detail
FROM CAMERA_EG_REASON_TBL
WHERE result = 'fail'
)
SELECT * FROM AGG_CAMERA_EG_CHECK
UNION
SELECT * FROM AGG_FPS_CHECK
UNION
SELECT * FROM AGG_TOTAL_CHECK
UNION
SELECT * FROM AGG_TOTAL_DURA_CHECK
UNION
SELECT * FROM AGG_CAMERA_NUMBER_CHECK
UNION
SELECT * FROM AGG_CAMERA_ID_CHECK
UNION
SELECT * FROM AGG_MOTOR_EG_CHECK
UNION
SELECT * FROM AGG_OSI_EG_CHECK
UNION
SELECT * FROM AGG_LASER_EG_CHECK
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