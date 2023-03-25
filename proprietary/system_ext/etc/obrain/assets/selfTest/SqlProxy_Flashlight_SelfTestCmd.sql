create view if not exists {}.diag_obrain_Flashlight_self_check as

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
	select 'flashlight' as agent,
		start_ts,
		end_ts,
		screen_mode,
        thermal_mode,
        ground_mode,
        power_mode
	from comp_flashlight_appPower_intv
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
		'comp_flashlight_appPower_intv' as tbl_name
		from comp_flashlight_appPower_intv
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
-- json_table_check
AGG_TABLE as
(
SELECT
	'energy' as fields,
json_valid(energy) as value
from agg_flashlightAgent_daily

UNION ALL

SELECT
	'top_app_by_mode' as fields,
json_valid(top_app_by_mode) as value
from agg_flashlightAgent_daily

UNION ALL

SELECT
	'top_app_by_energy' as fields,
json_valid(top_app_by_energy) as value
from agg_flashlightAgent_daily
),
AGG_TABLE_RESULT as (
select
	'agg_flashlightAgent_daily' as tbl_name,
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
------
JSON_EACH_TAB as (
	select value,
		fullkey,
		'energy' as fields
	from agg_flashlightAgent_daily,json_each(energy)
UNION
	select value,
		fullkey,
		'top_app_by_mode' as fields
	from agg_flashlightAgent_daily,json_each(top_app_by_mode)
UNION
	select value,
		fullkey,
		'top_app_by_energy' as fields
	from agg_flashlightAgent_daily,json_each(top_app_by_energy)
),
TORCH_EG_CHECK as (
	select *,
		json_extract(value,'$.Torch_eg') as Torch_eg,
		case
			when json_extract(value,'$.Torch_eg') >= 0 then 'pass'
			else 'fail'
		end as result
	from JSON_EACH_TAB
),
TORCH_EG_CHECK_TAB as (
	select
		'Torch_eg_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || ':' || fullkey || Torch_eg) as detail
	from TORCH_EG_CHECK  where result = 'fail'
),
TORCH_DUR_CHECK as (
	select *,
		sum(json_extract(value,'$.Torch_dur')) as sum_Torch_eg,
		case
			when sum(json_extract(value,'$.Torch_dur')) >= 0 and sum(json_extract(value,'$.Torch_dur')) <= 86400 * 1000 then 'pass'
			else 'fail'
		end as result
	from JSON_EACH_TAB
	where fields = 'energy'
		group by fields
),
TORCH_DUR_CHECK_TAB as (
	select
		'sum(Torch_dur)_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || ':' || sum_Torch_eg) as detail
	from TORCH_DUR_CHECK  where result = 'fail'
)

select * from TORCH_DUR_CHECK_TAB
union
select * from TORCH_EG_CHECK_TAB
union
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