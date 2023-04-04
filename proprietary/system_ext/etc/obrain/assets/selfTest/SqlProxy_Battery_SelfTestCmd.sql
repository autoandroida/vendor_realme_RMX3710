create view if not exists {}.diag_obrain_Battery_self_check as
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
	select 'battery' as agent,
		start_ts,
		end_ts,
		screen_mode,
        thermal_mode,
		1 as ground_mode,
        power_mode
	from comp_batteryAgent_mode_intv
	where screen_mode <> -1 and thermal_mode <> -1 and power_mode <> -1
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
COMP_CHECK_TABLE as(
    select
        case
            when count(*) = 0 then 'fail'
            else 'pass'
        end as result,
		'comp_batteryAgent_mode_intv' as tbl_name
	from comp_batteryAgent_mode_intv
	UNION
    select
        case
            when count(*) = 0 then 'fail'
            else 'pass'
        end as result,
		'comp_batteryAgent_appPower_intv' as tbl_name
	from comp_batteryAgent_appPower_intv
),
COMP_TABLE_EMPTY_CHECK as(
    select
        'empty_table_check' as item,
        case
            when count(*) != 0 then 'fail'
	        else 'pass'
	    end as result,
        count(*) as fail_cnt,
        json_group_array('tbl_name:' || tbl_name) as detail
    from COMP_CHECK_TABLE where result = 'fail'
),

AGG_JSON_TABLE as (
	select json_valid(by_mode) as json_result,
		'by_mode' as fields
	from agg_batteryAgent_daily
UNION
	select json_valid(energy) as json_result,
		'energy' as fields
	from agg_batteryAgent_daily
UNION
	select json_valid(level_stats) as json_result,
		'level_stats' as fields
	from agg_batteryAgent_daily
),
JSON_RESULT_TABLE as (
	select
	    'agg_batteryAgent_daily' as table_name,
	    fields,
	    json_result
	from AGG_JSON_TABLE
),
JSON_ERROR_CHECK_TABLE as (
	select 'json_check' as item ,
		case
		    when count(*) = 0 then 'pass'
		    else 'fail'
	    end as result ,
		count(*) as fail_cnt,
		json_group_array(table_name || ":" || fields) as detail
	from JSON_RESULT_TABLE
	    where json_result = 0
),

JSON_EACH_TAB as (
	select
		value,
		fullkey,
		'bymode' as fields
	from agg_batteryAgent_daily,json_each(by_mode)
UNION
	select
		value,
		fullkey,
		'energy' as fields
	from agg_batteryAgent_daily,json_each(energy)
),

RESULT_JSON_EACH_TAB as (
	select *,
		json_extract(value,'$.total_eg') as total_eg,
		json_extract(value,'$.total_du') as total_du,
		json_extract(value,'$.rm_eg') as rm_eg
	from JSON_EACH_TAB
),

TOTAL_EG_CHECK as (
	select
		case
			when total_eg > 0 then 'pass'
			else 'fail'
		end as result,
		fullkey,
		fields,
		total_eg
	from RESULT_JSON_EACH_TAB
),

RM_EG_TOTAL_DU_CHECK as (
	select
		case
			when rm_eg / total_du < 7.2 then 'pass'
			else 'fail'
		end as result,
		fields,fullkey,
		rm_eg/total_du as value
	from RESULT_JSON_EACH_TAB
),

TOTAL_DU_CHECK as (
	select
		case
			when total_du < 25 * 3600 * 1000 then 'pass'
			else 'fail'
		end as result,
		fullkey,
		fields,
		total_du
	from RESULT_JSON_EACH_TAB
),

RESULT_TOTAL_EG_CHECK as (
	select
		'total_eg_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || fullkey || 'total_eg=' || total_eg) as detail
	from TOTAL_EG_CHECK
	where result = 'fail'
),

RESULT_TOTAL_DU_CHECK as (
	select
		'total_du_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || fullkey || 'total_du=' || total_du) as detail
	from TOTAL_DU_CHECK
	where result = 'fail'
),

RESULT_RM_EG_TOTAL_DU_CHECK as (
	select
		'rm_eg/total_du_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || fullkey || 'rm_eg/total_du=' || value) as detail
	from RM_EG_TOTAL_DU_CHECK
	where result = 'fail'
)

select * from RESULT_RM_EG_TOTAL_DU_CHECK
UNION
select * from RESULT_TOTAL_DU_CHECK
UNION
select * from RESULT_TOTAL_EG_CHECK
UNION
select * from JSON_ERROR_CHECK_TABLE
UNION
select * from COMP_TABLE_EMPTY_CHECK
UNION
select * from SCREEN_MODE_FINAL_TBL
UNION
select * from THERMAL_MODE_FINAL_TBL
UNION
select * from POWER_MODE_FINAL_TBL
;