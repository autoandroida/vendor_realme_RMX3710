create view if not exists {}.diag_obrain_Display_self_check as
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
	select 'display' as agent,
		start_ts,
		end_ts,
		screen_mode,
        thermal_mode,
        ground_mode,
        power_mode
	from comp_displayAgent_appPower_intv
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
COMP_CHECK_TABLE as(
    select
        case
            when count(*) = 0 then 'fail'
            else 'pass'
        end as result,
		'comp_displayAgent_appPower_intv' as tbl_name
	from comp_displayAgent_appPower_intv
	UNION
    select
        case
            when count(*) = 0 then 'fail'
            else 'pass'
        end as result,
		'comp_displayAgent_brightness_intv' as tbl_name
	from comp_displayAgent_brightness_intv
	UNION
    select
        case
            when count(*) = 0 then 'fail'
            else 'pass'
        end as result,
		'comp_displayAgent_histInfo_intv' as tbl_name
	from comp_displayAgent_histInfo_intv
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
	from agg_displayAgent_daily
UNION
	select json_valid(by_app) as json_result,
		'by_app' as fields
	from agg_displayAgent_daily
UNION
	select json_valid(energy) as json_result,
		'energy' as fields
	from agg_displayAgent_daily
UNION
	select json_valid(by_sumHist) as json_result,
		'by_sumHist' as fields
	from agg_displayAgent_daily
UNION
	select json_valid(by_bright) as json_result,
		'by_bright' as fields
	from agg_displayAgent_daily
),
JSON_RESULT_TABLE as (
	select
		'agg_displayAgent_daily' as table_name,
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

JSON_EACH_TABLE as (
	select
		value,
		fullkey,
		'by_mode' as fields
	from agg_displayAgent_daily,json_each(by_mode)
	UNION
	select
		value,
		fullkey,
		'by_app' as fields
	from(
		select
			json_extract(value,'$.apps') as apps
		from (
			select
				value
			from agg_displayAgent_daily,json_each(by_app)
			)
		),json_each(apps)
	UNION
	select
		value,
		fullkey,
		'energy' as fields
	from agg_displayAgent_daily,json_each(energy)
),
SCREEN_MODE_TAB as (
	select *,
		case
			when screen_mode != 0 then 'pass'
			else 'fail'
		end as result
	from (
		select
			json_extract(value,'$.screen_mode') as screen_mode,
			fullkey,
			fields
		from JSON_EACH_TABLE
		)
),
SCREEN_MODE_CHECK_TAB as (
	select
		'screen_mode_check' as item ,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
 		count(*) as fail_cnt,
		json_group_array(fields || ':' || fullkey) as detail
	from SCREEN_MODE_TAB
	where result = 'fail'
),

FPS_TAB as (
	select *,
		case
			when fps >= 0 and fps <= 120 then 'pass'
			else 'fail'
		end as result
	from (
		select
			json_extract(value,'$.fps') as fps,
			fullkey,
			fields
		from JSON_EACH_TABLE
		)
),


FPS_CHECK_TAB as (
	select
		'fps_check' as item ,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
 		count(*) as fail_cnt,
		json_group_array(fields || ':' || fullkey || fps) as detail
	from FPS_TAB
	where result = 'fail'
),

BRIGHTNESS_EACH_TABLE as (
	select
		value,
		fullkey,
		'by_mode' as fields
	from agg_displayAgent_daily,json_each(by_mode)
	UNION
	select
		value,
		fullkey,
		'by_app' as fields
	from(
		select
			json_extract(value,'$.apps') as apps
		from (
			select
				value
			from agg_displayAgent_daily,json_each(by_app)
			)
		),json_each(apps)
	UNION
	select
		value,
		fullkey,
		'energy' as fields
	from agg_displayAgent_daily,json_each(energy)
	UNION
	select
		value,
		fullkey,
		'by_bright' as fields
	from agg_displayAgent_daily,json_each(by_bright)
),

BRIGHTNESS_TAB as (
	select *
	from (
		select
			json_extract(value,'$.brightness') as brightness,
			fullkey,
			fields
		from BRIGHTNESS_EACH_TABLE
		),json_each(brightness)
),

SUM_BRIGHTNESS_CHECK as (
	select * ,
		case
			when sum_br >= 0 and sum_br <= 8192 then 'pass'
			else 'fail'
		end as result
	from (
		select
			fields,
			fullkey,
			sum(value) as sum_br
		from BRIGHTNESS_TAB group by fields,fullkey
		)
),

BRIGHTNESS_CHECK_TAB as (
	select
		'brightness_check' as item ,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
 		count(*) as fail_cnt,
		json_group_array(fields || ':' || fullkey || sum_br) as detail
	from SUM_BRIGHTNESS_CHECK
	where result = 'fail'
),

DURATION_TAB as(
	select
		json_extract(value,'$.duration') as duration,
		fields
	from JSON_EACH_TABLE
),

SUN_DURATION_TAB as (
	select
		fields,
		sum(value) as sum_duration,
			case
				when sum(value) >= 0 and sum(value) <= 86400 * 1000 then 'pass'
				else 'fail'
			end as result
		from (
			select
				fields,
				value
			from DURATION_TAB, json_each(duration)
			) group by fields
),

DURATION_CHECK_TAB as (
	select
		'sum(duration)_check' as item ,
			case
				when count(*) = 0 then 'pass'
				else 'fail'
			end as result,
 		count(*) as fail_cnt,
		json_group_array(fields || ':' || sum_duration) as detail
	from SUN_DURATION_TAB
	where result = 'fail'
),
BRIGHTMODE_EACH_TAB as (
	select
		value,
		fullkey,
		'by_bright' as fields
	from agg_displayAgent_daily,json_each(by_bright)
),

BRIGHTMODE_TAB as (
	select *,
		case
			when brightmode = 0 or brightmode = 1 then 'pass'
			else 'fail'
		end as result
	from (
		select
			json_extract(value,'$.brightmode') as brightmode,
			fullkey,
			fields
		from BRIGHTMODE_EACH_TAB
		)
),

BRIGHTMODE_CHECK_TAB as (
	select
		'brightmode_check' as item ,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
 		count(*) as fail_cnt,
		json_group_array(fields || ':' || fullkey) as detail
	from BRIGHTMODE_TAB
	where result = 'fail'
),
BY_APP_EACH_TAB as (
	select
		value as val
	from agg_displayAgent_daily,json_each(by_app)
),

TYPE_TAB as (
	select
		json_extract(val,'$.apps') as apps,
		'normal' as typ
	from BY_APP_EACH_TAB
	where json_extract(val,'$.type') = 'normal'
UNION
	select
		json_extract(val,'$.apps') as apps,
		'parallel' as typ
	from BY_APP_EACH_TAB
	where json_extract(val,'$.type') = 'parallel'
UNION
	select
		json_extract(val,'$.apps') as apps,
		'split' as typ
	from BY_APP_EACH_TAB where json_extract(val,'$.type') = 'split'
),

NORMAL_CHECK as (
	select
		typ,
		json_extract(value,'$.app') as app ,
		json_extract(value,'$.activity') as activity,
		fullkey
	from (
		select
			typ,
			value,
			fullkey
		from TYPE_TAB,json_each(apps)
		where typ = 'normal'
		)
),

NORMAL_CHECK_TAB as (
	select
		'type_normal_check' as item ,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
 		count(*) as fail_cnt,
		json_group_array(typ || ':' || fullkey) as detail
	from NORMAL_CHECK where app is NULL or activity is NULL
),

PARALLEL_CHECK as (
	select
		typ,
		json_extract(value,'$.app') as app ,
		json_extract(value,'$.activity') as activity,
		json_extract(value,'$.activity_secondary') as activity_secondary,
		fullkey
	from (
		select
			typ,
			value,
			fullkey
		from TYPE_TAB,json_each(apps)
		where typ = 'parallel'
		)
),

PARALLEL_CHECK_TAB as (
	select
		'type_parallel_check' as item ,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
 		count(*) as fail_cnt,
		json_group_array(typ || ':' || fullkey) as detail
	from PARALLEL_CHECK
	where app is NULL or activity is NULL or activity_secondary is NULL
),

SPLIT_CHECK as (
	select
		typ,
		json_extract(value,'$.app') as app ,
		json_extract(value,'$.activity') as activity,
		json_extract(value,'$.activity_secondary') as activity_secondary,
		json_extract(value,'$.app_secondary') as app_secondary,
		fullkey
	from (
		select
			typ,
			value,
			fullkey
		from type_tab,json_each(apps)
		where typ = 'split'
		)
),

SPLIT_CHECK_TAB as (
	select
		'type_split_check' as item ,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
 		count(*) as fail_cnt,
		json_group_array(typ || ':' || fullkey) as detail
	from SPLIT_CHECK
	where app is NULL or activity is NULL or activity_secondary is NULL or app_secondary is NULL
)

select * from SPLIT_CHECK_TAB
union
select * from PARALLEL_CHECK_TAB
union
select * from NORMAL_CHECK_TAB
union
select * from DURATION_CHECK_TAB
union
select * from SCREEN_MODE_CHECK_TAB
union
select * from FPS_CHECK_TAB
union
select * from BRIGHTNESS_CHECK_TAB
union
SELECT * FROM BRIGHTMODE_CHECK_TAB
union
select * from JSON_ERROR_CHECK_TABLE
union
select * from COMP_TABLE_EMPTY_CHECK
union
select * from SCREEN_MODE_FINAL_TBL
union
select * from THERMAL_MODE_FINAL_TBL
union
select * from POWER_MODE_FINAL_TBL
;