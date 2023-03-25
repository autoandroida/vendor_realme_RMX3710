create view if not exists {}.diag_obrain_audio_self_check as
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
	select 'audio' as agent,
		start_ts,
		end_ts,
		screen_mode,
        thermal_mode,
        ground_mode,
        power_mode
	from comp_audioPower_audioAgent_intv
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
		'comp_audioPower_audioAgent_intv' as tbl_name
	from comp_audioPower_audioAgent_intv
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
        from COMP_CHECK_TABLE
        where result = 'fail'
),
AGG_JSON_TABLE as (
    select json_valid(energy) as json_result,
        'agg_audio_app_daily' as table_name,
        'energy' as fields
    from agg_audio_app_daily
UNION
    select json_valid(top_app_by_mode) as json_result,
        'agg_audio_app_daily' as table_name,
        'top_app_by_mode' as fields
    from agg_audio_app_daily
UNION
    select json_valid(top_app_by_energy) as json_result,
        'agg_audio_app_daily' as table_name,
        'top_app_by_energy' as fields
    from agg_audio_app_daily
),
JSON_RESULT_TABLE as (
	select
		'agg_audio_app_daily' as table_name,
		fields,
		json_result
	from AGG_JSON_TABLE
),
JSON_ERROR_CHECK_TABLE as (
	select 'json_check' as item ,
		case
		when count(*) = 0 then 'pass' else 'fail'
		end as result ,
		count(*) as fail_cnt,
		json_group_array(table_name || ":" || fields) as detail
	from JSON_RESULT_TABLE
		where json_result = 0
),

JSON_EACH_TAB as (
	select
		'energy' as fields,
		value as val,
		fullkey as fk
	from agg_audio_app_daily,json_each(energy)
UNION
	select
		'top_app_by_mode' as fields,
		value as val,
		fullkey as fk
	from agg_audio_app_daily,json_each(top_app_by_mode)
UNION
	select
		'top_app_by_energy' as fields,
		value as val,
		fullkey as fk
	from agg_audio_app_daily,json_each(top_app_by_energy)
),
RESULT_JSON_EACH_TAB as (
	select fields,
		fk,
		key as ke,
		value as va
	from JSON_EACH_TAB,json_each(val)
),
JSON_EACH_ENERGY as (
	select fields,
		fk,
		key as k1,
		value as val
	from (
		select *
		from RESULT_JSON_EACH_TAB
		where ke = 'energy'
		),json_each(va)
),
DURATION_CHECK as (
	select fields,
		fk,val,k1,
		key,value
	from (
		select *
		from JSON_EACH_ENERGY where k1 = 'duration'
		),json_each(val)
),
SUM_DURATION_CHECK as (
	select *,
		sum(value) as sum_dur,
		case
			when sum(value) >= 0 and sum(value) <= 86400 * 1000 then 'pass'
			else 'fail'
		end as result
	from DURATION_CHECK
		group by fields
),
DURATION_CHECK_TAB as (
	select
		'duration_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || ':sum_duration' || sum_dur) as detail
	from SUM_DURATION_CHECK  where result = 'fail'
),
-------------
TOTAL_EG_CHECK as (
	select fields,fk,
		val,k1,key,value
	from (
		select *
		from JSON_EACH_ENERGY where k1 = 'total_eg'
		),json_each(val)
),
SUM_TOTAL_EG_CHECK as (
	select *,
		case
			when value >= 0 then 'pass'
			else 'fail'
		end as result
	from TOTAL_EG_CHECK
),
TOTAL_EG_CHECK_TAB as (
	select
		'total_eg_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || ':' || fk) as detail
	from SUM_TOTAL_EG_CHECK  where result = 'fail'
),
----------------
VOLUME_CHECK as (
	select fields,fk,
		val,k1,key,value
	from (
		select *
		from JSON_EACH_ENERGY where k1 = 'volume'
		),json_each(val)
),
SUM_VOLUME_CHECK as (
	select *,
		case
			when value >= 0 and value <= 16 then 'pass'
			else 'fail'
		end as result
	from VOLUME_CHECK
),
VOLUME_CHECK_TAB as (
	select
		'volume_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || ':' || fk) as detail
	from SUM_VOLUME_CHECK  where result = 'fail'
),
-----------------------
CHANNEL_CHECK as (
	select *,
		case
			when val = 0 or val = 1 or val = 2 then 'pass'
			else 'fail'
		end as result
	from JSON_EACH_ENERGY where k1= 'channel'
),
CHANNEL_CHECK_TAB as (
	select
		'channel_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || ':' || fk || val) as detail
	from CHANNEL_CHECK  where result = 'fail'
)

select * from CHANNEL_CHECK_TAB
union
select * from VOLUME_CHECK_TAB
union
select * from TOTAL_EG_CHECK_TAB
union
select * from DURATION_CHECK_TAB
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