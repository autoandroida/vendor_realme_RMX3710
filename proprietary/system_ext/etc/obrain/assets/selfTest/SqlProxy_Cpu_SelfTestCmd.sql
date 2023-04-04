create view if not exists {}.diag_obrain_cpu_self_check as

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
	select 'cpu' as agent,
		start_ts,
		end_ts,
		screen_mode,
        thermal_mode,
        ground_mode,
        power_mode
	from comp_uidstate_cpuagent_backward
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
		'comp_uidstate_cpuagent_backward' as tbl_name
	from comp_uidstate_cpuagent_backward
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
	select json_valid(top_app) as json_result,
		'top_app' as fields
	from agg_cpuagent_daily
UNION
	select json_valid(fg_cpu_energy) as json_result,
		'obrainInfo' as fields
	from agg_cpuagent_daily
UNION
	select json_valid(bg_cpu_energy) as json_result,
		'bg_cpu_energy' as fields
	from agg_cpuagent_daily
UNION
	select json_valid(power_table) as json_result,
		'power_table' as fields
	from agg_cpuagent_daily
),
JSON_RESULT_TABLE as (
    select
        'agg_cpuagent_daily' as table_name,
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
	select value as val,
		fullkey,
		'top_app' as fields
	from agg_cpuagent_daily,json_each(top_app)
UNION
	select value as val,
		fullkey,
		'fg_cpu_energy' as fields
	from agg_cpuagent_daily,json_each(fg_cpu_energy)
UNION
	select value as val,
		fullkey,
		'bg_cpu_energy' as fields
	from agg_cpuagent_daily,json_each(bg_cpu_energy)
),

RESULT_C0_FREQ_DUR as (
	select
		json_extract(val,'$.c0_freq_duration') as c0_freq_duration,
		fields || ':' || fullkey || ':c0_freq_duration' as field
	from JSON_EACH_TABLE
),

RESULT_C1_FREQ_DUR as (
	select
		json_extract(val,'$.c1_freq_duration') as c1_freq_duration,
		fields || ':' || fullkey || ':c1_freq_duration' as field
	from JSON_EACH_TABLE
),

RESULT_C2_FREQ_DUR as (
	select
		json_extract(val,'$.c2_freq_duration') as c2_freq_duration,
		fields || ':' || fullkey || ':c2_freq_duration' as field
	from JSON_EACH_TABLE
),

C0_FREQ_DUR_CHECK_TAB as (
	select
		case
			when sum_c0_freq >= 0 and sum_c0_freq <= 4 * 86400 * 1000 then 'pass'
			else 'fail'
		end as result, field
	from (
			select
				sum(value) as sum_c0_freq,
				field
			from RESULT_C0_FREQ_DUR,json_each(c0_freq_duration)
			group by field
		)
),

C0_FREQ_RESULT as (
	select
		'c0_freq_duration_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(field) as detail
	from C0_FREQ_DUR_CHECK_TAB
	where result = 'fail'
),

C1_FREQ_DUR_CHECK_TAB as (
	select
		case
			when sum_c1_freq >= 0 and sum_c1_freq <= 4 * 86400 * 1000 then 'pass'
			else 'fail'
		end as result, field
	from (
			select
				sum(value) as sum_c1_freq,
				field
			from RESULT_C1_FREQ_DUR,json_each(c1_freq_duration)
			group by field
		)
),

C1_FREQ_RESULT as (
	select
		'c1_freq_duration_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(field) as detail
	from C1_FREQ_DUR_CHECK_TAB
	where result = 'fail'
),

C2_FREQ_DUR_CHECK_TAB as (
	select
		case
			when sum_c2_freq >= 0 and sum_c2_freq <= 86400 * 1000 then 'pass'
			else 'fail'
		end as result,
		field
	from (
			select
				sum(value) as sum_c2_freq,
				field
			from RESULT_C2_FREQ_DUR,json_each(c2_freq_duration)
			group by field
		)
),

C2_FREQ_RESULT as (
	select
		'c2_freq_duration_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(field) as detail
	from C2_FREQ_DUR_CHECK_TAB
	where result = 'fail'
),

C0_DUR_CHECK as (
	select sum_c0_dur,
		case
			when sum_c0_dur >= 0 and sum_c0_dur <= 8 * 86400 * 1000 then 'pass'
			else 'fail'
		end as c0_result,
		field
	from (
			select
				sum(json_extract(val,'$.c0_duration')) as sum_c0_dur,
				fields||':c0_duration' as field
			from JSON_EACH_TABLE
			group by fields
		)
),

RESULT_C0_DUR_CHECK as (
	select
		'sum(c0_duration)_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(field) as detail
	from C0_DUR_CHECK
	where c0_result = 'fail'
),

C1_DUR_CHECK as (
	select
		sum_c1_dur,
		case
			when sum_c1_dur >= 0 and sum_c1_dur <= 8 * 86400 * 1000 then 'pass'
			else 'fail'
		end as c1_result,
		field
	from (
			select
				sum(json_extract(val,'$.c1_duration')) as sum_c1_dur,
				fields || ':c1_duration' as field
			from JSON_EACH_TABLE
			group by fields
		)
),
RESULT_C1_DUR_CHECK as (
	select 'sum(c1_duration)_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(field) as detail
	from C1_DUR_CHECK
	where c1_result = 'fail'
),

C2_DUR_CHECK as (
	select sum_c2_dur,
		case
			when sum_c2_dur >= 0 and sum_c2_dur <= 8 * 86400 * 1000 then 'pass'
			else 'fail'
		end as c2_result,
		field
	from (
			select
				sum(json_extract(val,'$.c2_duration')) as sum_c2_dur,
				fields || ':c2_duration' as field
			from JSON_EACH_TABLE
			group by fields
		)
),

RESULT_C2_DUR_CHECK as (
	select 'sum(c2_duration)_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(field) as detail
	from C2_DUR_CHECK
	where c2_result = 'fail'
),

TOTAL_EG_CHECK as (
	select sum_total_eg,
		case
			when sum_total_eg >= 10000 * 1000000 then 'pass'
			else 'fail'
		end as total_eg_result,
		field
	from (
			select sum(json_extract(val,'$.total_eg')) as sum_total_eg,
				fields || ':total_eg' as field
			from JSON_EACH_TABLE
			group by fields
		)
),

RESULT_TOTAL_EG_CHECK as (
	select 'sum(total_eg)_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(field) as detail
	from TOTAL_EG_CHECK
	where total_eg_result = 'fail'
),

TYPE_RESULT as (
	select
		json_extract(value,'$.name') as name,
		json_extract(value,'$.type') as type ,
		json_extract(value,'$.parent') as parent,
		json_extract(value,'$.grand_parent') as grand_parent,
		fullkey,
		fields
	from (
			select value,
				fullkey,
				'top_app' as fields
			from agg_cpuagent_daily,json_each(top_app)
		)
),

NAME_UID_CHECK_TAB as (
	select
		case
			when name != "" then 'pass'
				else 'fail'
			end as result1,
			fullkey,fields
	from TYPE_RESULT
	where type = 'uid'
),

NAME_UID_CHECK as (
	select
		'name_uid_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || fullkey) as detail
	from NAME_UID_CHECK_TAB
	where result1 = 'fail'
),

NAME_PARENT_PROCESS_CHECK_TAB as (
	select
		case
			when name != "" and parent != "" then 'pass'
			else 'fail'
		end as result2,
		fullkey, fields
	from TYPE_RESULT
	where type = 'process'
),

NAME_PARENT_PROCESS_CHECK as (
	select 'name_parent_process_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || fullkey) as detail
	from NAME_PARENT_PROCESS_CHECK_TAB
	where result2 = 'fail'
),

NAME_PARENT_GRAND_PARENT_THREAD_CHECK_TAB as (
	select
		case
			when name != "" and parent != "" and grand_parent != "" then 'pass'
			else 'fail'
		end as result3,
		fullkey, fields
	from TYPE_RESULT
	where type='thread'
),

NAME_PARENT_GRAND_PARENT_THREAD_CHECK as(
	select 'name_parent_grand_parent_thread_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || fullkey) as detail
	from NAME_PARENT_GRAND_PARENT_THREAD_CHECK_TAB
	where result3 = 'fail'
),

MODE_CHECK_TAB as (
	select
		fields || fullkey || ':' || key as index_fields,
		value,
		case
			when value != '-1' then 'pass'
			else 'fail'
		end as result
	from (
		select * from JSON_EACH_TABLE,json_each(val)
		)
	where key like '%_mode'
),

RESULT_MODE_CHECK_TAB as (
    select 'mode_check' as item ,
 		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
 		count(*) as fail_cnt,
		json_group_array(index_fields || ':' ||  value) as detail
	from MODE_CHECK_TAB where result = 'fail'
)

select * from RESULT_MODE_CHECK_TAB
union
select * from NAME_PARENT_GRAND_PARENT_THREAD_CHECK
union
select * from NAME_PARENT_PROCESS_CHECK
union
select * from NAME_UID_CHECK
union
select * from RESULT_C0_DUR_CHECK
union
select * from RESULT_C1_DUR_CHECK
union
select * from RESULT_C2_DUR_CHECK
union
select * from RESULT_TOTAL_EG_CHECK
union
select * from C0_FREQ_RESULT
union
select * from C1_FREQ_RESULT
union
select * from C2_FREQ_RESULT
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