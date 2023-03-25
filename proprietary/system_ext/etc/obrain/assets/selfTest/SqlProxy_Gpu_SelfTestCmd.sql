create view if not exists {}.diag_obrain_Gpu_self_check as

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
	select 'gpu' as agent,
		start_ts,
		end_ts,
		screen_mode,
        thermal_mode,
        ground_mode,
        power_mode
	from comp_gpuPower_gpuAgent_intv
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
		'comp_gpuPower_gpuAgent_intv' as tbl_name
		from comp_gpuPower_gpuAgent_intv
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
	'fg_top_app_by_eg' as fields,
json_valid(fg_top_app_by_eg) as value
from agg_gpu_app_daily

UNION ALL

SELECT
	'fg_top_app_by_mode' as fields,
json_valid(fg_top_app_by_mode) as value
from agg_gpu_app_daily

UNION ALL

SELECT
	'gpu_energy' as fields,
json_valid(gpu_energy) as value
from agg_gpu_app_daily
),
AGG_TABLE_RESULT as (
select
	'agg_gpu_app_daily' as tbl_name,
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
--total_eg_check
TOTAL_EG_RESULT_TBL as (
SELECT
	'fg_top_app_by_eg' as fields,
	fullkey,
	value
from agg_gpu_app_daily, json_each(fg_top_app_by_eg)

union all

SELECT
	'fg_top_app_by_mode' as fields,
	fullkey,
	value
from agg_gpu_app_daily, json_each(fg_top_app_by_mode)

union all

SELECT
	'gpu_energy' as fields,
	fullkey,
	value
from agg_gpu_app_daily, json_each(gpu_energy)
),
TOTAL_EG_REASON_TBL as (
SELECT
	fields,
	fullkey,
	case when json_extract(value,'$.total_eg') >= 0 then 'pass' else 'fail' end as result
from TOTAL_EG_RESULT_TBL
),
AGG_TOTAL_EG_CHECK as (
SELECT
	'total_eg_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(fields || ' : ' || fullkey || ' : ' || 'total_eg') as detail
from TOTAL_EG_REASON_TBL
where result = 'fail'
),
--gpu_eg_check
GPU_EG_RESULT_TBL as (
SELECT
	'fg_top_app_by_eg' as fields,
	fullkey,
	value
from agg_gpu_app_daily, json_each(fg_top_app_by_eg)

union all

SELECT
	'fg_top_app_by_mode' as fields,
	fullkey,
	value
from agg_gpu_app_daily, json_each(fg_top_app_by_mode)

union all

SELECT
	'gpu_energy' as fields,
	fullkey,
	value
from agg_gpu_app_daily, json_each(gpu_energy)
),
GPU_EG_REASON_TBL as(
SELECT
	fields || ' : ' || fullkey || ' : ' || 'gpu_eg' as field_index,
	json_extract(value,'$.gpu_eg') as field_value
from GPU_EG_RESULT_TBL
),
GPU_EG_FINAL_TBL as (
SELECT
	field_index,
	sum(value) as sum_value,
	case when sum(value) >= 0 then 'pass' else 'fail' end as result
from GPU_EG_REASON_TBL, json_each(field_value)
group by field_index
),
AGG_GPU_EG_CHECK as (
SELECT
	'sum(gpu_eg)_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
from GPU_EG_FINAL_TBL
where result = 'fail'
),
--xxx_utilize_rate_check
XXX_UTILIZE_RATE_RESULT_TBL as (
SELECT
	'fg_top_app_by_eg' as fields,
	fullkey as fk,
	value as val
from agg_gpu_app_daily, json_each(fg_top_app_by_eg)

union all

SELECT
	'fg_top_app_by_mode' as fields,
	fullkey as fk,
	value as val
from agg_gpu_app_daily, json_each(fg_top_app_by_mode)

union all

SELECT
	'gpu_energy' as fields,
	fullkey as fk,
	value as val
from agg_gpu_app_daily, json_each(gpu_energy)
),
XXX_UTILIZE_RATE_REASON_TBL as (
SELECT
	fields || ' : ' || fk ||  ' : ' || key as field_index,
	key,
	value
from XXX_UTILIZE_RATE_RESULT_TBL, json_each(val)
where key like '%_utilize_rate'
),
XXX_UTILIZE_RATE_FINAL_TBL as (
SELECT
	field_index,
	key,
	value,
	case when value >= 0 or value <= 100 then 'pass' else 'fail' end as result
from XXX_UTILIZE_RATE_REASON_TBL
),
AGG_XXX_UTILIZE_RATE_CHECK as (
SELECT
	'xxx_utilize_rate_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
from XXX_UTILIZE_RATE_FINAL_TBL
where result = 'fail'
),
--app_check
APP_RESULT_TBL as (
SELECT
	'fg_top_app_by_eg' as fields,
	fullkey,
	value
from agg_gpu_app_daily, json_each(fg_top_app_by_eg)

union all

SELECT
	'fg_top_app_by_mode' as fields,
	fullkey,
	value
from agg_gpu_app_daily, json_each(fg_top_app_by_mode)

union all

SELECT
	'gpu_energy' as fields,
	fullkey,
	value
from agg_gpu_app_daily, json_each(gpu_energy)
),
APP_REASON_TBL as (
SELECT
	fields,
	fullkey,
	case when json_extract(value,'$.app') != '' then 'pass' else 'fail' end as result
FROM APP_RESULT_TBL
),
AGG_APP_TBL as (
SELECT
	'app_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(fields || ' : ' || fullkey || ' : ' || 'app') as detail
FROM APP_REASON_TBL
where result = 'fail'
),
--xxx_mode_check
XXX_MODE_RESULT_TBL as (
SELECT
	'fg_top_app_by_eg' as fields,
	fullkey as fk,
	value as val
from agg_gpu_app_daily, json_each(fg_top_app_by_eg)

union all

SELECT
	'fg_top_app_by_mode' as fields,
	fullkey as fk,
	value as val
from agg_gpu_app_daily, json_each(fg_top_app_by_mode)

union all

SELECT
	'gpu_energy' as fields,
	fullkey as fk,
	value as val
from agg_gpu_app_daily, json_each(gpu_energy)
),
XXX_MODE_REASON_TBL as (
SELECT
	fields || ' : ' || fk ||  ' : ' || key as field_index,
	key,
	value
from XXX_MODE_RESULT_TBL, json_each(val)
where key like '%mode'
),
XXX_MODE_FINAL_TBL as (
SELECT
	field_index,
	key,
	value,
	case when value != -1 then 'pass' else 'fail' end as result
from XXX_MODE_REASON_TBL
),
AGG_XXX_MODE_CHECK as (
SELECT
	'xxx_mode_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
from XXX_MODE_FINAL_TBL
where result = 'fail'
),
--tot_slu_du_check
TOT_SLU_DU_RESULT_TBL as (
SELECT
	'fg_top_app_by_eg' as fields,
	fullkey as fk,
	value as val
from agg_gpu_app_daily, json_each(fg_top_app_by_eg)

union all

SELECT
	'fg_top_app_by_mode' as fields,
	fullkey as fk,
	value as val
from agg_gpu_app_daily, json_each(fg_top_app_by_mode)

union all

SELECT
	'gpu_energy' as fields,
	fullkey as fk,
	value as val
from agg_gpu_app_daily, json_each(gpu_energy)
),
TOT_SLU_DU_REASON_TBL as (
SELECT
	'agg_gpu_app_daily' || ' : ' || fields  as field_index,
	sum(value) as sum_val,
	case when sum(value) >= 0 and sum(value) <= 86400 * 1000 then 'pass' else 'fail' end as result
FROM TOT_SLU_DU_RESULT_TBL, json_each(val)
WHERE key = 'total_du' or key = 'slumber_du'
group by fields
),
AGG_TOT_SLU_DU_CHECK as (
SELECT
	'tot_slu_du_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
from TOT_SLU_DU_REASON_TBL
where result = 'fail'
)
SELECT * FROM AGG_TOT_SLU_DU_CHECK
UNION
SELECT * FROM AGG_TOTAL_EG_CHECK
UNION
SELECT * FROM AGG_GPU_EG_CHECK
UNION
SELECT * FROM AGG_XXX_UTILIZE_RATE_CHECK
UNION
SELECT * FROM AGG_APP_TBL
UNION
SELECT * FROM AGG_XXX_MODE_CHECK
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