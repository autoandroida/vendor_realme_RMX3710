create view if not exists {}.diag_obrain_self_check as
-------- mode check ----------
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
NATIVE_PSS_TBL as (
    select *, round(1.0 * native_pss_increased_kb / time_h, 2) as kb_per_hour
    from (
        select min(start_ts) as start_ts, max(end_ts) as end_ts, EVENT,
			sum(increased_mem) as native_pss_increased_kb, round(1.0*sum(duration)/3600000, 2) as time_h
        from (
			select TB1.start_ts as start_ts, TB1.end_ts, TB1.EVENT, TB1.mem,
				lead(TB1.mem) over (order by TB1.start_ts) as next_mem, (lead(TB1.mem) over (order by TB1.start_ts) - TB1.mem) as increased_mem,
				(TB1.end_ts - TB1.start_ts) as duration, TB2.phase, lead(TB2.phase) over (order by TB1.start_ts) as next_phase
			from (
				select OTIME as start_ts, lead(OTIME) over (order by OTIME) as end_ts, DATE, EVENT, DES,
				case
				when EVENT = 'Memory' then  json_extract(DES,'$.nativePss') else 0 end as mem
				from log_running_event
				where  EVENT = 'Memory'
			) TB1, (
			    -- select start phase --
				select T1.start_ts, ifnull(T1.end_ts, T2.max_ts) as end_ts, T1.EVENT, T1.phase
				from (
					select OTIME as start_ts, lead(OTIME) over (order by OTIME) as end_ts, EVENT,
					row_number() over () as phase
					from log_running_event
					where  EVENT = 'START'
					ORDER BY start_ts asc
				) T1, (
					select max(OTIME) as max_ts
					from log_running_event
				) T2
			) TB2
			where TB1.start_ts > TB2.start_ts and TB1.start_ts <= TB2.end_ts
        )
        where phase == next_phase
        group by phase
    )
),
GPU_FREQ_TBL as (
	select count(*) as count from comp_gpuPower_gpuAgent_intv where whole_eg = 0 and usually_utilize_rate <> 0
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
	union
	select 'battery' as agent,
		start_ts,
		end_ts,
		screen_mode,
        thermal_mode,
		1 as ground_mode,
        power_mode
	from comp_batteryAgent_mode_intv
	where screen_mode <> -1 and thermal_mode <> -1 and power_mode <> -1
	union
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
-------- logic error check ----------
LOG_ERR_CHECK_TBL as (
    select 'logic_error_check' as item,
        case
            when count(*) > 0 then 'fail'
            else 'pass'
        end as result,
		count(*) as fail_cnt,
        json_group_array(DATE || ':' || EVENT || ':' || DES) as detail
    from log_running_event
    where EVENT='ERROR'
),
NATIVE_PSS_INCREASE_CHECK_TBL as (
    select 'native_increase_pss_check' as item,
	case
		when kb_per_hour >  213  then 'fail' ----5MB/day == 213KB/hour------
		else 'pass'
	end as result, count (*) as fail_cnt,
	json_group_array('start_ts :' || start_ts || ', end_ts :' || end_ts || ', native_increased_pss_kb :' || native_pss_increased_kb  || ', time_h : ' || time_h || ', kb_per_hour: ' || kb_per_hour ) as detail
    from NATIVE_PSS_TBL
    where kb_per_hour >  213
),
GPU_FREQ_CHECK_TBL as (
	select 'gpu_freq_check' as item,
	case
	when count >  0
		then 'fail' ----出现GPU频点不匹配的问题------
		else 'pass'
	end as result,
	count as fail_cnt,
	'GPU freq error' as detail
    from GPU_FREQ_TBL
),
--------------cpu_check-----------------
COMP_CPU_TAB as (
	select *
	from (
		select total_eg
			, case
				when total_eg >= 0 then 'pass'
				else 'fail'
			end as total_eg_check, pid
			, case
				when pid = -1 or pid >= 0 and pid = cast(pid as int) then 'pass'
				else 'fail'
			end as pid_check, tgid
			, case
				when tgid = -1 or tgid >= 0 and tgid = cast(tgid as int) then 'pass'
				else 'fail'
			end as tgid_check, uid
			, case
		        when uid = -1 or uid >= 0 and uid = cast(uid as int) then 'pass'
				else 'fail'
			end as uid_check, pid_name
			, case
				when pid = -1 and pid_name = '' then 'pass'
				when uid = -1 and pid_name = '' then 'pass'
				when pid <> -1 and uid <> -1 and pid_name <> '' then 'pass'
				else 'fail'
			end as pid_name_check, tgid_name
			, case
				when pid = -1 and tgid_name = '' then 'pass'
				when uid = -1 and tgid_name = '' then 'pass'
				when pid <> -1 and uid <> -1 and tgid_name <> '' then 'pass'
				else 'fail'
			end as tgid_name_check, uid_name
			, case
				when uid_name <> '' then 'pass'
				else 'fail'
			end as uid_name_check
		from comp_uidstate_cpuagent_backward
	)
	where total_eg_check = 'fail'
		or pid_check = 'fail'
		or tgid_check = 'fail'
		or uid_check = 'fail'
		or pid_name_check = 'fail'
		or tgid_name_check = 'fail'
		or uid_name_check = 'fail'
),
SUM_COMP_CPU_TAB as (
	select *
    from (
    	select round(sum_eg * 1.0 / sum_dur * 1.0, 2) as p
    		, case
    			when sum_eg / sum_dur >= 1 then 'pass'
    			else 'fail'
    		end as sum_total_eg_check, empty_check
    	from (
    		select max(end_ts) - min(start_ts) as sum_dur
    			, sum(total_eg) as sum_eg
    			, case
    				when count(*) > 0 then 'pass'
    				else 'fail'
    			end as empty_check
    		from comp_uidstate_cpuagent_backward
    	)
    )
    where sum_total_eg_check = 'fail'
    	or empty_check = 'fail'
),
AGG_CPU_DAILY_TAB as (
	select *
	from (
		select case
				when count(*) > 0 then 'pass'
				else 'fail'
			end as empty_check, date
			, case
				when date > 0 and date = cast(date as int) then 'pass'
				else 'fail'
			end as date_check, start_ts
			, case
				when start_ts >= 0 then 'pass'
				else 'fail'
			end as start_ts_check, end_ts
			, case
				when end_ts >= 0 then 'pass'
				else 'fail'
			end as end_ts_check, top_app
			, case
				when top_app <> '' then 'pass'
				else 'fail'
			end as top_app_check, fg_cpu_energy
			, case
				when fg_cpu_energy <> '' then 'pass'
				else 'fail'
			end as fg_cpu_energy_check, bg_cpu_energy
			, case
				when bg_cpu_energy <> '' then 'pass'
				else 'fail'
			end as bg_cpu_energy_check, power_table
			, case
				when power_table <> '' then 'pass'
				else 'fail'
			end as power_table_check, version
			, case
				when version > 0 and version = cast(version as int) then 'pass'
				else 'fail'
			end as version_check
		from agg_cpuagent_daily
	)
	where date_check = 'fail'
		or start_ts_check = 'fail'
		or end_ts_check = 'fail'
		or top_app_check = 'fail'
		or fg_cpu_energy_check = 'fail'
		or bg_cpu_energy_check = 'fail'
		or power_table_check = 'fail'
		or version_check = 'fail'
		or empty_check = 'fail'
),
CPU_RESULT_CHECK_TAB as (
	select 'comp_uidstate_cpuagent_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select a.fail_cnt  + c.fail_cnt as fail_cnt
			, json_group_array('comp_uidstate_cpuagent_backward :' || c.detail || a.detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('total_eg :' || total_eg || ':' || total_eg_check || ', pid :' || pid || ':' || pid_check || ', tgid :' || tgid || ':' || tgid_check ||
				', uid :' || uid || ':' || uid_check || ', pid_name :' || pid_name || ':' || pid_name_check || ', tgid_name :' || tgid_name || ':' || tgid_name_check ||
				', uid_name :' || uid_name || ':' || uid_name_check) as detail
			from COMP_CPU_TAB
		) a , (
				select count(*) as fail_cnt
					, json_group_array('empty_check :' || empty_check || ', total_eg/total_du :' || p || ':' || sum_total_eg_check) as detail
				from SUM_COMP_CPU_TAB
			) c
	)
	where fail_cnt > 0
),
AGG_DAILY_CHECK_TAB as (
	select 'agg_cpuagent_daily_data_check' as item
    	, case
    		when count(*) > 0 then 'fail'
    		else 'pass'
    	end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
    from (
    	select fail_cnt, json_group_array('agg_cpuagent_daily :' || detail) as detail
    	from (
    		select count(*) as fail_cnt
    			, json_group_array('empty_check :' || empty_check || ', date :' || date || ':' || date_check || ', start_ts :' || start_ts || ':' || start_ts_check ||
    			', end_ts : ' || end_ts || ':' || end_ts_check || ', top_app :' || top_app_check ||
    			', fg_cpu_energy :' || fg_cpu_energy_check || ', bg_cpu_energy :' || bg_cpu_energy_check || ', power_table ;' || power_table_check ||
    			', version :' || version || ':' || version_check) as detail
    		from AGG_CPU_DAILY_TAB
    	)
    )
    where fail_cnt > 0
),
--------------------binder_check--------------------
COMP_BINDER_TAB as (
	select *
	from (
		select service_name
			, case
				when service_name <> '' then 'pass'
				else 'fail'
			end as service_name_check, service_proc_name
			, case
				when service_proc_name <> '' then 'pass'
				else 'fail'
			end as service_proc_name_check, service_calltimes
			, case
				when service_calltimes >= 0 then 'pass'
				else 'fail'
			end as service_calltimes_check, caller_uid_names
			, case
				when caller_uid_names <> '' then 'pass'
				else 'fail'
			end as caller_uid_names_check, caller_proc_names
			, case
				when caller_proc_names <> '' then 'pass'
				else 'fail'
			end as caller_proc_names_check, caller_thread_names
			, case
				when caller_thread_names <> '' then 'pass'
				else 'fail'
			end as caller_thread_names_check, caller_calltimes
			, case
				when caller_calltimes <> '' then 'pass'
				else 'fail'
			end as caller_calltimes_check
		from comp_binderstats_binderagent_backward
		where screen_mode <> -1
	)
	where service_name_check = 'fail'
		or service_proc_name_check = 'fail'
		or service_calltimes_check = 'fail'
		or caller_uid_names_check = 'fail'
		or caller_proc_names_check = 'fail'
		or caller_thread_names_check = 'fail'
		or caller_calltimes_check = 'fail'
),
FOREGROUND_APP_CHECK_TAB as (
	select *
	from (
		select case
				when c2 - c1 > 0 and c2 > 0 then 'pass'
				when c2 = 0 and c1 = 0 then 'pass'
				else 'fail'
			end as foreground_app_cheeck
		from (
			select count(*) as c1
			from (
				select foreground_app
				from comp_binderstats_binderagent_backward
				where screen_mode <> -1
			)
			where foreground_app = ''
				or foreground_app = 'unknown'
		) t, (
				select count(*) as c2
				from comp_binderstats_binderagent_backward
				where screen_mode <> -1
			) t1
	)
	where foreground_app_cheeck = 'fail'
),
AGG_BINDERAGENT_DAILY_TAB as (
	select *
	from (
		select case when count(*) = 0 then 'fail'
				else 'pass'
			end as empty_check, date
			, case
				when date > 0 and date = cast(date as int) then 'pass'
				else 'fail'
			end as date_check, start_ts
			, case
				when start_ts >= 0 then 'pass'
				else 'fail'
			end as start_ts_check, end_ts
			, case
				when end_ts >= 0 then 'pass'
				else 'fail'
			end as end_ts_check, binder_stats
			, case
				when binder_stats <> '' then 'pass'
				else 'fail'
			end as binder_stats_check, version
			, case
				when version > 0 and version = cast(version as int) then 'pass'
				else 'fail'
			end as version_check
		from agg_binderagent_daily
	)
	where empty_check = 'fail'
		or date_check = 'fail'
		or start_ts_check = 'fail'
		or end_ts_check = 'fail'
		or binder_stats_check = 'fail'
		or version_check = 'fail'
),

COMP_BINDER_RESULT_TAB as (
	select 'comp_binderagent_backward_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result,ifnull(fail_cnt,0) as fail_cnt,detail
		from (select a.fail_cnt + c.fail_cnt + b.fail_cnt as fail_cnt
		, json_group_array('comp_binderstats_binderagent_backward :' || c.detail || b.detail || a.detail) as detail
	from (
		select count(*) as fail_cnt
			, json_group_array('service_name :' || service_name || ':'
			|| service_name_check || ', service_proc_name :' || service_proc_name_check || ', service_calltimes :'
			|| service_calltimes || ':' || service_calltimes_check || ', caller_uid_names :' || caller_uid_names_check
			|| ', caller_proc_names :' || caller_proc_names_check || ', caller_thread_names :' || caller_thread_names_check ||
			', caller_calltimes :' || caller_calltimes || ':' || caller_calltimes_check) as detail
		from COMP_BINDER_TAB
	) a,
	    (   select count(*) as fail_cnt, json_group_array('empty_check :' || empty_check) as detail
			from (
				select case
						when count(*) = 0 then 'fail'
						else 'pass'
					end as empty_check
				from comp_binderstats_binderagent_backward
			)
			where empty_check = 'fail'
		) c,
		(   select count(*) as fail_cnt, json_group_array('foreground_app_cheeck :' || foreground_app_cheeck) as detail
				from FOREGROUND_APP_CHECK_TAB
		) b
	) where fail_cnt > 0
),
AGG_BINDER_RESULT_TAB as (
	select 'agg_binderagent_daily_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select fail_cnt, json_group_array('agg_binderagent_daily :' || detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('empty_check :' || empty_check || ', date :' || date || ':' || date_check || ', start_ts :' || start_ts || ':' || start_ts_check ||
				', end_ts :' || end_ts || ':' || end_ts_check || ', binder_stats :' || binder_stats_check || ', version :' || version || ':' || version_check) as detail
			from AGG_BINDERAGENT_DAILY_TAB
		)
	)
	where fail_cnt > 0
),
----------------camera_check--------------
COMP_CAMERA_TAB as (
	select *
	from (
		select time_delta
			, case
				when time_delta > 0 then 'pass'
				else 'fail'
			end as time_delta_check, app
			, case
				when app <> '' then 'pass'
				else 'fail'
			end as app_check, camera_app
			, case
				when camera_app <> '' then 'pass'
				else 'fail'
			end as camera_app_check, duration
			, case
				when duration > 0 then 'pass'
				else 'fail'
			end as duration_check, fps
			, case
				when fps > 0 and fps < 120
				then 'pass'
				else 'fail'
			end as fps_check, camera_eg
			, case
				when camera_eg >= 0 then 'pass'
				else 'fail'
			end as camera_eg_check, laser_eg
			, case
				when laser_eg >= 0 then 'pass'
				else 'fail'
			end as laser_eg_check, osi_eg
			, case
				when osi_eg >= 0 then 'pass'
				else 'fail'
			end as osi_eg_check, motor_eg
			, case
				when motor_eg >= 0 then 'pass'
				else 'fail'
			end as motor_eg_check
		from comp_cameraAgent_appPower_intv
	)
	where time_delta_check = 'fail'
		or app_check = 'fail'
		or camera_app_check = 'fail'
		or duration_check = 'fail'
		or fps_check = 'fail'
		or camera_eg_check = 'fail'
		or laser_eg_check = 'fail'
		or osi_eg_check = 'fail'
		or motor_eg_check = 'fail'
),
AGG_CAMERA_DAILY_TAB as (
	select *
	from (
		select case
				when count(*) = 0 then 'fail'
				else 'pass'
			end as empty_check, start_ts
            , case
            	when start_ts >= 0 then 'pass'
            	else 'fail'
            end as start_ts_check, end_ts
            , case
            	when end_ts >= 0 then 'pass'
            	else 'fail'
            end as end_ts_check, energy
			, case
				when energy <> '' then 'pass'
				else 'fail'
			end as energy_check, top_app_by_mode
			, case
				when top_app_by_mode <> '' then 'pass'
				else 'fail'
			end as top_app_by_mode_check, top_app_by_energy
			, case
				when top_app_by_energy <> '' then 'pass'
				else 'fail'
			end as top_app_by_energy_check
		from agg_cameraAgent_daily
	)
	where empty_check = 'fail'
		or energy_check = 'fail'
		or top_app_by_mode_check = 'fail'
		or top_app_by_energy_check = 'fail'
		or start_ts_check = 'fail'
		or end_ts_check = 'fail'
),
COMP_CAMERA_RESULT_TAB as (
	select 'comp_cameraAgent_appPower_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select a.fail_cnt + c.fail_cnt as fail_cnt
			, json_group_array('comp_cameraAgent_appPower_intv :' || c.detail || a.detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('time_delta :' || time_delta || ':' || time_delta_check || ', app :' || app || ':' || app_check ||
				', camera_app :' || camera_app || ':' || camera_app_check || ', duration :' || duration || ':' || duration_check || ', fps :' || fps || ':' || fps_check ||
				', camera_eg :' || camera_eg || ':' || camera_eg_check || ', laser_eg :' || laser_eg || ':' || laser_eg_check || ', osi_eg :' || osi_eg || ':' || osi_eg_check ||
				', motor_eg :' || motor_eg || ':' || motor_eg_check) as detail
			from COMP_CAMERA_TAB
		) a, (
				select count(*) as fail_cnt, json_group_array('empty_check :' || empty_check) as detail
				from (
					select case
							when count(*) = 0 then 'fail'
							else 'pass'
						end as empty_check
					from comp_cameraAgent_appPower_intv
				)
				where empty_check = 'fail'
			) c
	)
	where fail_cnt > 0
),
AGG_CAMERA_DAILY_RESULT_TAB as (
	select 'agg_cameraAgent_daily_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select fail_cnt, json_group_array('agg_cameraAgent_daily :' || detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('empty_check :' || empty_check || ', start_ts :' || start_ts || ':' || start_ts_check || ', end_ts :' || end_ts || ':' || end_ts_check ||
				', energy :' || energy_check || ', top_app_by_mode :' || top_app_by_mode_check ||
				', top_app_by_energy :' || top_app_by_energy_check) as detail
			from AGG_CAMERA_DAILY_TAB
		)
	)
	where fail_cnt > 0
),
---------------------------cellular_check-----------------------------
COMP_CELLULAR_AGENT_TAB as (
	select *
	from (
		select total_du
			, case
				when total_du >= 0 then 'pass'
				else 'fail'
			end as total_du_check, fg_app
			, case
				when fg_app <> '' then 'pass'
				else 'fail'
			end as fg_app_check, incall_du
			, case
				when incall_du >= 0 then 'pass'
				else 'fail'
			end as incall_du_check, rx_trans_byte
			, case
				when rx_trans_byte >= 0 then 'pass'
				else 'fail'
			end as rx_trans_byte_check, tx_trans_byte
			, case
				when tx_trans_byte >= 0 then 'pass'
				else 'fail'
			end as tx_trans_byte_check, sleep_time
			, case
				when sleep_time >= 0 then 'pass'
				else 'fail'
			end as sleep_time_check, rx_time
			, case
				when rx_time >= 0 then 'pass'
				else 'fail'
			end as rx_time_check, rx_5g_time
			, case
				when rx_5g_time >= 0 then 'pass'
				else 'fail'
			end as rx_5g_time_check, signalStrength
			, case
				when signalStrength >= -143 and signalStrength <= -43
				then 'pass'
				when signalStrength = -1 then 'pass'
				else 'fail'
			end as signalStrength_check, transceiver_eg
			, case
				when transceiver_eg >= 0 then 'pass'
				else 'fail'
			end as transceiver_eg_check, pa_eg
			, case
				when pa_eg >= 0 then 'pass'
				else 'fail'
			end as pa_eg_check, modem_eg
			, case
				when modem_eg >= 0 then 'pass'
				else 'fail'
			end as modem_eg_check, total_eg
			, case
				when total_eg >= 0 then 'pass'
				else 'fail'
			end as total_eg_check
		from comp_cellularagent_backward
	)
	where total_du_check = 'fail'
		or fg_app_check = 'fail'
		or incall_du_check = 'fail'
		or rx_trans_byte_check = 'fail'
		or tx_trans_byte_check = 'fail'
		or sleep_time_check = 'fail'
		or rx_time_check = 'fail'
		or rx_5g_time_check = 'fail'
		or signalStrength_check = 'fail'
		or transceiver_eg_check = 'fail'
		or pa_eg_check = 'fail'
		or modem_eg_check = 'fail'
		or total_eg_check = 'fail'
),
COMP_CELLULAR_UID_STATE_TAB as (
	select *
	from (
		select busy_du
			, case
				when busy_du >= 0 then 'pass'
				else 'fail'
			end as busy_du_check, incall_du
			, case
				when incall_du >= 0 then 'pass'
				else 'fail'
			end as incall_du_check, name
			, case
				when name <> '' then 'pass'
				else 'fail'
			end as name_check, rx_trans_byte
			, case
				when rx_trans_byte >= 0 then 'pass'
				else 'fail'
			end as rx_trans_byte_check, tx_trans_byte
			, case
				when tx_trans_byte >= 0 then 'pass'
				else 'fail'
			end as tx_trans_byte_check, sleep_time
			, case
				when sleep_time >= 0 then 'pass'
				else 'fail'
			end as sleep_time_check, rx_time
			, case
				when rx_time >= 0 then 'pass'
				else 'fail'
			end as rx_time_check, rx_5g_time
			, case
				when rx_5g_time >= 0 then 'pass'
				else 'fail'
			end as rx_5g_time_check, transceiver_eg
			, case
				when transceiver_eg >= 0 then 'pass'
				else 'fail'
			end as transceiver_eg_check, pa_eg
			, case
				when pa_eg >= 0 then 'pass'
				else 'fail'
			end as pa_eg_check, modem_eg
			, case
				when modem_eg >= 0 then 'pass'
				else 'fail'
			end as modem_eg_check, total_eg
			, case
				when total_eg >= 0 then 'pass'
				else 'fail'
			end as total_eg_check
		from comp_cellularUidState_backward
	)
	where busy_du_check = 'fail'
		or incall_du_check = 'fail'
		or name_check = 'fail'
		or rx_trans_byte_check = 'fail'
		or tx_trans_byte_check = 'fail'
		or sleep_time_check = 'fail'
		or rx_time_check = 'fail'
		or rx_5g_time_check = 'fail'
		or transceiver_eg_check = 'fail'
		or pa_eg_check = 'fail'
		or modem_eg_check = 'fail'
		or total_eg_check = 'fail'
),
AGG_CELLULAR_DAILY_TAB as (
	select *
	from (
		select case
				when count(*) = 0 then 'fail'
				else 'pass'
			end as empty_check, cell_energy
			, case
				when cell_energy <> '' then 'pass'
				else 'fail'
			end as cell_energy_check, top_app_by_mode
			, case
				when top_app_by_mode <> '' then 'pass'
				else 'fail'
			end as top_app_by_mode_check, modem_stats
			, case
				when modem_stats <> '' then 'pass'
				else 'fail'
			end as modem_stats_check, signal_du_stats
			, case
				when signal_du_stats <> '' then 'pass'
				else 'fail'
			end as signal_du_stats_check
		from agg_cellularagent_daily
	)
	where empty_check = 'fail'
		or cell_energy_check = 'fail'
		or top_app_by_mode_check = 'fail'
		or modem_stats_check = 'fail'
		or signal_du_stats_check = 'fail'
),
COMP_CELLULAR_AGENT_RESULT_TAB as (
	select 'comp_cellularagent_backward_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select a.fail_cnt + c.fail_cnt as fail_cnt
			, json_group_array('comp_cellularagent_backward :' || c.detail || a.detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('total_du :' || total_du || ':' || total_du_check || ', fg_app :' || fg_app || ':' || fg_app_check ||
				', incall_du :' || incall_du || ':' || incall_du_check || ', rx_trans_byte :' || rx_trans_byte || ':' || rx_trans_byte_check ||
				', tx_trans_byte :' || tx_trans_byte || ':' || tx_trans_byte_check || ', sleep_time :' || sleep_time || ':' || sleep_time_check ||
				', rx_time :' || rx_time || ':' || rx_time_check || ', rx_5g_time :' || rx_5g_time || ':' || rx_5g_time_check ||
				', signalStrength :' || signalStrength || ':' || signalStrength_check || ', pa_eg :' || pa_eg || ':' || pa_eg_check ||
				', modem_eg :' || modem_eg || ':' || modem_eg_check || ', total_eg :' || total_eg || ':' || total_eg_check) as detail
			from COMP_CELLULAR_AGENT_TAB
		) a, (
				select count(*) as fail_cnt, json_group_array('empty_check :' || empty_check) as detail
				from (
					select case
							when count(*) = 0 then 'fail'
							else 'pass'
						end as empty_check
					from comp_cellularagent_backward
				)
				where empty_check = 'fail'
			) c
	)
	where fail_cnt > 0
),
COMP_CELLULAR_UID_STATE_RESULT_TAB as (
	select 'comp_cellularUidState_backward_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select a.fail_cnt + c.fail_cnt as fail_cnt
			, json_group_array('comp_cellularUidState_backward :' || c.detail || a.detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('busy_du :' || busy_du || ':' || busy_du_check || ', incall_du :' || incall_du || ':' || incall_du_check ||
				', name :' || name || ':' || name_check || ', rx_trans_byte :' || rx_trans_byte || ':' || rx_trans_byte_check || ', tx_trans_byte :' || tx_trans_byte || ':'
				|| tx_trans_byte_check || ', sleep_time :' || sleep_time || ':' || sleep_time_check || ', rx_time :' || rx_time || ':' || rx_time_check ||
				', rx_5g_time :' || rx_5g_time || ':' || rx_5g_time_check || ', transceiver_eg :' || transceiver_eg || ':' || transceiver_eg_check ||
				', pa_eg :' || pa_eg || ':' || pa_eg_check || ', modem_eg :' || modem_eg || ':' || modem_eg_check || ', total_eg :' || total_eg || ':'
				|| total_eg_check) as detail
			from COMP_CELLULAR_UID_STATE_TAB
		) a, (
				select count(*) as fail_cnt, json_group_array('empty_check :' || empty_check) as detail
				from (
					select case
							when count(*) = 0 then 'fail'
							else 'pass'
						end as empty_check
					from comp_cellularUidState_backward
				)
				where empty_check = 'fail'
			) c
	)
	where fail_cnt > 0
),
AGG_CELLULARAGENT_DAILY_RESULT_TAB as (
	select 'agg_cellularagent_daily_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select fail_cnt, json_group_array('agg_cellularagent_daily :' || detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('empty_check :' || empty_check || ', cell_energy :' || cell_energy_check || ', top_app_by_mode :' || top_app_by_mode_check ||
				', modem_stats :' || modem_stats || modem_stats_check || ', signal_du_stats :' || signal_du_stats || signal_du_stats_check) as detail
			from AGG_CELLULAR_DAILY_TAB
		)
	)
	where fail_cnt > 0
),
--------------GPU----------------
COMP_GPU_AGENT_TAB as (
	select *
	from (
		select app
			, case
				when app <> '' then 'pass'
				else 'fail'
			end as app_check, gpu_slumber_time_du
			, case
				when gpu_slumber_time_du >= 0 then 'pass'
				else 'fail'
			end as gpu_slumber_time_du_check, usually_utilize_rate
			, case
				when usually_utilize_rate >= 0 then 'pass'
				else 'fail'
			end as usually_utilize_rate_check, fmax_utilize_rate
			, case
				when fmax_utilize_rate >= 0 then 'pass'
				else 'fail'
			end as fmax_utilize_rate_check, time_delta
			, case
				when time_delta >= 0 then 'pass'
				else 'fail'
			end as time_delta_check, whole_eg
			, case
				when whole_eg >= 0 then 'pass'
				else 'fail'
			end as whole_eg_check
		from comp_gpuPower_gpuAgent_intv
	)
	where app_check = 'fail'
		or gpu_slumber_time_du_check = 'fail'
		or usually_utilize_rate_check = 'fail'
		or fmax_utilize_rate_check = 'fail'
		or time_delta_check = 'fail'
		or whole_eg_check = 'fail'
),
AGG_GPU_DAILY_TAB as (
	select *
	from (
		select case
				when count(*) > 0 then 'pass'
				else 'fail'
			end as empty_check, date
			, case
				when date > 0 and date = cast(date as int) then 'pass'
				else 'fail'
			end as date_check, start_ts
			, case
				when start_ts >= 0 then 'pass'
				else 'fail'
			end as start_ts_check, end_ts
			, case
				when end_ts >= 0 then 'pass'
				else 'fail'
			end as end_ts_check, fg_top_app_by_eg
			, case
				when fg_top_app_by_eg <> '' then 'pass'
				else 'fail'
			end as fg_top_app_by_eg_check, fg_top_app_by_mode
			, case
				when fg_top_app_by_mode <> '' then 'pass'
				else 'fail'
			end as fg_top_app_by_mode_check, gpu_energy
			, case
				when gpu_energy <> '' then 'pass'
				else 'fail'
			end as gpu_energy_check, version
			, case
				when version > 0 and version = cast(version as int) then 'pass'
				else 'fail'
			end as version_check
		from agg_gpu_app_daily
	)
	where date_check = 'fail'
		or start_ts_check = 'fail'
		or end_ts_check = 'fail'
		or fg_top_app_by_eg_check = 'fail'
		or fg_top_app_by_mode_check = 'fail'
		or gpu_energy_check = 'fail'
		or version_check = 'fail'
		or empty_check = 'fail'
),
COMP_GPU_AGENT_RESULT_TAB as (
	select 'comp_gpuPower_gpuAgent_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select a.fail_cnt + c.fail_cnt as fail_cnt
			, json_group_array('comp_gpuPower_gpuAgent_intv :' || c.detail || a.detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('app :' || app || ':' || app_check || ', gpu_slumber_time_du :' || gpu_slumber_time_du || ':' || gpu_slumber_time_du_check ||
				', usually_utilize_rate :' || usually_utilize_rate || ':' || usually_utilize_rate_check || ', fmax_utilize_rate :' || fmax_utilize_rate || ':' || fmax_utilize_rate_check ||
				', time_delta :' || time_delta || ':' || time_delta_check || ', whole_eg :' || whole_eg || ':' || whole_eg_check) as detail
			from COMP_GPU_AGENT_TAB
		) a, (
				select count(*) as fail_cnt, json_group_array('empty_check :' || empty_check) as detail
				from (
					select case
							when count(*) = 0 then 'fail'
							else 'pass'
						end as empty_check
					from comp_gpuPower_gpuAgent_intv
				)
				where empty_check = 'fail'
			) c
	)
	where fail_cnt > 0
),
AGG_GPU_AGENT_DAILY_RESULT_TAB as (
	select 'agg_gpu_app_daily_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select fail_cnt, json_group_array('agg_gpu_app_daily :' || detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('empty_check :' || empty_check || ', date :' || date || ':' || date_check || ', start_ts :' || start_ts || ':' || start_ts_check ||
				', end_ts :' || end_ts || ':' || end_ts_check || ', fg_top_app_by_eg :' || fg_top_app_by_eg_check || ', fg_top_app_by_mode :' || fg_top_app_by_mode_check ||
				', gpu_energy :' || gpu_energy_check || ', version :' || version || ':' || version_check) as detail
			from AGG_GPU_DAILY_TAB
		)
	)
	where fail_cnt > 0
),
--------------------wifi----------------
COMP_WIFI_TAB as (
	select *
	from (
		select app
			, case when app <> '' then 'pass'
				else 'fail'
			end as app_check, wifi_id
			, case when wifi_id in (0, 1) then 'pass'
				else 'fail'
			end as wifi_id_check, enable
			, case when enable in (0, 1) then 'pass'
				else 'fail'
			end as enable_check, hotspot
			, case when hotspot in (0, 1) then 'pass'
				else 'fail'
			end as hotspot_check, frequency_band
			, case when frequency_band in ('5G', '2.4G', 'unknown') then 'pass'
				else 'fail'
			end as frequency_band_check, package_name
			, case when package_name <> '' then 'pass'
				else 'fail'
			end as package_name_check, tx_byte
			, case when tx_byte >= 0 then 'pass'
				else 'fail'
			end as tx_byte_check, rx_byte
			, case when rx_byte >= 0 then 'pass'
				else 'fail'
			end as rx_byte_check, tx_time
			, case when tx_time >= 0 then 'pass'
				else 'fail'
			end as tx_time_check, rx_time
			, case when rx_time >= 0 then 'pass'
				else 'fail'
			end as rx_time_check, idle_time
			, case when idle_time >= 0 then 'pass'
				else 'fail'
			end as idle_time_check, tx_packet
			, case when tx_packet >= 0 then 'pass'
				else 'fail'
			end as tx_packet_check, rx_packet
			, case when rx_packet >= 0 then 'pass'
				else 'fail'
			end as rx_packet_check, rssi
			, case when rssi >= -127 and rssi <= 0 then 'pass'
				else 'fail'
			end as rssi_check, total_eg
			, case when total_eg >= 0 then 'pass'
				else 'fail'
			end as total_eg_check
		from comp_wifi_agent_intv
	)
	where app_check = 'fail'
		or wifi_id_check = 'fail'
		or enable_check = 'fail'
		or hotspot_check = 'fail'
		or frequency_band_check = 'fail'
		or package_name_check = 'fail'
		or tx_byte_check = 'fail'
		or rx_byte_check = 'fail'
		or tx_time_check = 'fail'
		or rx_time_check = 'fail'
		or idle_time_check = 'fail'
		or tx_packet_check = 'fail'
		or rx_packet_check = 'fail'
		or rssi_check = 'fail'
		or total_eg_check = 'fail'
),
AGG_WIFI_AGENT_TAB as (
	select *
	from (
		select case
				when count(*) = 0 then 'fail'
				else 'pass'
			end as empty_check, date
			, case
				when date > 0 and date = cast(date as int) then 'pass'
				else 'fail'
			end as date_check, start_ts
			, case
				when start_ts >= 0 then 'pass'
				else 'fail'
			end as start_ts_check, end_ts
			, case
				when end_ts >= 0 then 'pass'
				else 'fail'
			end as end_ts_check, energy
			, case
				when energy <> '' then 'pass'
				else 'fail'
			end as energy_check, top_app_by_mode
			, case
				when top_app_by_mode <> '' then 'pass'
				else 'fail'
			end as top_app_by_mode_check, attach
			, case
				when attach <> '' then 'pass'
				else 'fail'
			end as attach_check, version
			, case
				when version > 0 and version = cast(version as int) then 'pass'
				else 'fail'
			end as version_check
		from agg_wifi_agent_daily
	)
	where date_check = 'fail'
		or start_ts_check = 'fail'
		or end_ts_check = 'fail'
		or energy_check = 'fail'
		or top_app_by_mode_check = 'fail'
		or attach_check = 'fail'
		or version_check = 'fail'
),
COMP_WIFI_RESULT_TAB as (
	select 'comp_wifi_agent_intv_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select a.fail_cnt + c.fail_cnt as fail_cnt
			, json_group_array('comp_wifi_agent_intv :' || c.detail || a.detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('app :' || app || ':' || app_check || ', wifi_id :' || wifi_id || ':' || wifi_id_check || ', enable :' || enable || ':' || enable_check ||
				', hotspot :' || hotspot || ':' || hotspot_check || ', frequency_band :' || frequency_band || ':' || frequency_band_check ||
				', package_name :' || package_name || ':' || package_name_check || ', tx_byte :' || tx_byte || ':' || tx_byte_check ||
				', rx_byte :' || rx_byte || ':' || rx_byte_check || ', tx_time :' || tx_time || ':' || tx_time_check || ', rx_time :' || rx_time || ':' || rx_time_check ||
				', idle_time :' || idle_time || ':' || idle_time_check || ', tx_packet :' || tx_packet || ':' || tx_packet_check ||
				', rx_packet :' || rx_packet || ':' || rx_packet_check || ', rssi :' || rssi || ':' || rssi_check || ', total_eg :' || total_eg || ':' || total_eg_check) as detail
			from COMP_WIFI_TAB
		) a, (
				select count(*) as fail_cnt, json_group_array('empty_check :' || empty_check) as detail
				from (
					select case
							when count(*) = 0 then 'fail'
							else 'pass'
						end as empty_check
					from comp_wifi_agent_intv
				)
				where empty_check = 'fail'
			) c
	)
	where fail_cnt > 0
),
AGG_WIFI_AGENT_DAILY_RESULT_TAB as (
	select 'agg_wifi_agent_daily_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select fail_cnt, json_group_array('agg_wifi_agent_daily :' || detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('empty_check :' || empty_check || ', date :' || date || ':' || date_check || ', start_ts :' || start_ts || ':' || start_ts_check ||
				', end_ts :' || end_ts || ':' || end_ts_check || ', energy :' || energy_check || ', top_app_by_mode :' || top_app_by_mode_check ||
				', attach :' || attach_check || ', version :' || version || ':' || version_check) as detail
			from AGG_WIFI_AGENT_TAB
		)
	)
	where fail_cnt > 0
),
----------------audio_check-----------------------
COMP_AUDIO_AGENT_TAB as (
	select *
	from (
		select duration
			, case when duration >= 0 then 'pass'
				else 'fail'
			end as duration_check, app
			, case when app <> '' then 'pass'
				else 'fail'
			end as app_check, player_app
			, case when player_app <> '' then 'pass'
				else 'fail'
			end as player_app_check, audio_number
			, case when audio_number > 0 and audio_number = cast(audio_number as int) then 'pass'
				else 'fail'
			end as audio_number_check, volume
			, case when volume >= 0 and volume <= 16 and volume = cast(volume as int)
				then 'pass'
				else 'fail'
			end as volume_check, channel
			, case when channel in (0, 1, 2) then 'pass'
				else 'fail'
			end as channel_check, whole_eg
			, case
				when volume = 0 and whole_eg = 0 then 'pass'
				when duration < 1000 and whole_eg = 0 then 'pass'
				when whole_eg > 0 and whole_eg = cast(whole_eg as int) then 'pass'
				else 'fail'
			end as whole_eg_check
		from comp_audioPower_audioAgent_intv
		where volume <> -1
	)
	where duration_check = 'fail'
		or app_check = 'fail'
		or player_app_check = 'fail'
		or audio_number_check = 'fail'
		or volume_check = 'fail'
		or channel_check = 'fail'
		or whole_eg_check = 'fail'
),
AGG_AUDIO_APP_DAILY_TAB as (
	select *
	from (
		select case when count(*) = 0 then 'fail'
				else 'pass'
			end as empty_check, date
			, case when date > 0 and date = cast(date as int) then 'pass'
				else 'fail'
			end as date_check, start_ts
			, case when start_ts >= 0 then 'pass'
				else 'fail'
			end as start_ts_check, end_ts
			, case when end_ts >= 0 then 'pass'
				else 'fail'
			end as end_ts_check, energy
			, case when energy <> '' then 'pass'
				else 'fail'
			end as energy_check, top_app_by_mode
			, case when top_app_by_mode <> '' then 'pass'
				else 'fail'
			end as top_app_by_mode_check, top_app_by_energy
			, case when top_app_by_energy <> '' then 'pass'
				else 'fail'
			end as top_app_by_energy_check, version
			, case when version > 0 and version = cast(version as int) then 'pass'
				else 'fail'
			end as version_check
		from agg_audio_app_daily
	)
	where date_check = 'fail'
		or start_ts_check = 'fail'
		or end_ts_check = 'fail'
		or energy_check = 'fail'
		or top_app_by_mode_check = 'fail'
		or top_app_by_energy_check = 'fail'
		or version_check = 'fail'
),
COMP_AUDIO_AGENT_RESULT_TAB as (
	select 'comp_audioAgent_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select a.fail_cnt + c.fail_cnt as fail_cnt
			, json_group_array('comp_audioPower_audioAgent_intv :' || c.detail || a.detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('duration :' || duration || ':' || duration_check || ', app :' || app || ':' || app_check || ', player_app :' || player_app || ':' || player_app_check ||
				', audio_number :' || audio_number || ':' || audio_number_check || ', volume :' || volume || ':' || volume_check || ', channel :' || channel || ':' || channel_check ||
				', whole_eg :' || whole_eg || ':' || whole_eg_check) as detail
			from COMP_AUDIO_AGENT_TAB
		) a, (
				select count(*) as fail_cnt, json_group_array('empty_check :' || empty_check) as detail
				from (
					select case
							when count(*) = 0 then 'fail'
							else 'pass'
						end as empty_check
					from comp_audioPower_audioAgent_intv
				)
				where empty_check = 'fail'
			) c
	)
	where fail_cnt > 0
),
AGG_AUDIO_APP_DAILY_RESULT_TAB as (
	select 'agg_audio_app_daily_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select fail_cnt, json_group_array('agg_audio_app_daily :' || detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('empty_check :' || empty_check || ', date :' || date || ':' || date_check || ', start_ts :' || start_ts || ':' || start_ts_check ||
				', end_ts :' || end_ts || ':' || end_ts_check || ', energy :' || energy_check || ', top_app_by_mode :' || top_app_by_mode_check ||
				', top_app_by_energy :' || top_app_by_energy_check || ', version :' || version || ':' || version_check) as detail
			from AGG_AUDIO_APP_DAILY_TAB
		)
	)
	where fail_cnt > 0
),
------------------gps_check-------------------
COMP_GPS_AGENT_TAB as (
	select *
	from (
		select app
			, case when app <> '' then 'pass'
				else 'fail'
			end as app_check, gnss_app
			, case when gnss_app <> '' then 'pass'
				else 'fail'
			end as gnss_app_check, app_number
			, case when app_number > 0 and app_number = cast(app_number as int) then 'pass'
				else 'fail'
			end as app_number_check, status
			, case when status in (0, 1, 2) then 'pass'
				else 'fail'
			end as status_check, energy
			, case
				when energy >= 0 then 'pass'
				else 'fail'
			end as energy_check,
			duration
			, case when duration >= 0 then 'pass'
				else 'fail'
			end as duration_check
		from comp_gpsPower_gpsAgent_intv
	)
	where app_check = 'fail'
		or gnss_app_check = 'fail'
		or app_number_check = 'fail'
		or status_check = 'fail'
		or energy_check = 'fail'
		or duration_check = 'fail'
),
AGG_GPS_APP_DAILY_TAB as (
	select *
	from (
		select case when count(*) = 0 then 'fail'
				else 'pass'
			end as empty_check, date
			, case when date > 0 and date = cast(date as int) then 'pass'
				else 'fail'
			end as date_check, start_ts
			, case when start_ts >= 0 then 'pass'
				else 'fail'
			end as start_ts_check, end_ts
			, case when end_ts >= 0 then 'pass'
				else 'fail'
			end as end_ts_check, energy
			, case when energy <> '' then 'pass'
				else 'fail'
			end as energy_check, top_app_by_mode
			, case when top_app_by_mode <> '' then 'pass'
				else 'fail'
			end as top_app_by_mode_check, top_app_by_energy
			, case when top_app_by_energy <> '' then 'pass'
				else 'fail'
			end as top_app_by_energy_check, version
			, case when version > 0 and version = cast(version as int) then 'pass'
				else 'fail'
			end as version_check
		from agg_gps_app_daily
	)
	where date_check = 'fail'
		or start_ts_check = 'fail'
		or end_ts_check = 'fail'
		or energy_check = 'fail'
		or top_app_by_mode_check = 'fail'
		or top_app_by_energy_check = 'fail'
		or version_check = 'fail'
),
COMP_GPS_AGENT_RESULT_TAB as (
	select 'comp_gpsAgent_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select
		a.fail_cnt + c.fail_cnt as fail_cnt
			, json_group_array('comp_gpsPower_gpsAgent_intv :' || c.detail || a.detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('app :' || app || ':' || app_check || ', gnss_app :' || gnss_app || ':' || gnss_app_check || ', app_number :' || app_number || ':' || app_number_check ||
				', status :' || status || ':' || status_check || ', energy :' || energy || ':' || energy_check || ', duration :' || duration || ':' || duration_check) as detail
			from COMP_GPS_AGENT_TAB
		) a, (
				select count(*) as fail_cnt, json_group_array('empty_check :' || empty_check) as detail
				from (
					select case
							when count(*) = 0 then 'fail'
							else 'pass'
						end as empty_check
					from comp_gpsPower_gpsAgent_intv
				)
				where empty_check = 'fail'
			) c
	)
	where fail_cnt > 0
),
AGG_GPS_APP_DAILY_RESULT_TAB as (
	select 'agg_gps_app_daily_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select fail_cnt, json_group_array('agg_gps_app_daily :' || detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('empty_check :' || empty_check || ', date :' || date || ':' || date_check || ', start_ts :' || start_ts || ':' || start_ts_check ||
				', end_ts :' || end_ts || ':' || end_ts_check || ', energy :' || energy_check || ', top_app_by_mode :' || top_app_by_mode_check ||
				', top_app_by_energy :' || top_app_by_energy_check || ', version :' || version || ':' || version_check) as detail
			from AGG_GPS_APP_DAILY_TAB
		)
	)
	where fail_cnt > 0
),
----------------------thermal--------------
COMP_THERMAL_AGENT_TAB as (
	select *
	from (
		select fg_app
			, case
				when fg_app <> '' then 'pass'
				else 'fail'
			end as fg_app_check, network_type
			, case
				when network_type = -1 or network_type >= 0 and network_type = cast(network_type as int) then 'pass'
				else 'fail'
			end as network_type_check, zone_name
			, case
				when zone_name <> '' then 'pass'
				else 'fail'
			end as zone_name_check, max_temp
			, case
				when max_temp > 0 and max_temp = cast(max_temp as int) then 'pass'
				when max_temp = -1 and zone_name = 'ambientThermal' then 'pass'
				else 'fail'
			end as max_temp_check, up_trend
			, case
				when up_trend >= 0 then 'pass'
				else 'fail'
			end as up_trend_check, down_trend
			, case
				when down_trend >= 0 then 'pass'
				else 'fail'
			end as down_trend_check, keep_trend
			, case
				when keep_trend >= 0 then 'pass'
				else 'fail'
			end as keep_trend_check
		from comp_thermalAgent_backward
	)
	where fg_app_check = 'fail'
		or network_type_check = 'fail'
		or zone_name_check = 'fail'
		or max_temp_check = 'fail'
		or up_trend_check = 'fail'
		or down_trend_check = 'fail'
		or keep_trend_check = 'fail'
),
AGG_THERMAL_AGENT_DAILY_TAB as (
	select *
	from (
		select case
				when count(*) = 0 then 'fail'
				else 'pass'
			end as empty_check, start_ts
            , case
            	when start_ts >= 0 then 'pass'
            	else 'fail'
            end as start_ts_check, end_ts
            , case
            	when end_ts >= 0 then 'pass'
            	else 'fail'
            end as end_ts_check,histogram
			, case
				when histogram <> '' then 'pass'
				else 'fail'
			end as histogram_check, top_app
			, case
				when top_app <> '' then 'pass'
				else 'fail'
			end as top_app_check
		from agg_thermalAgent_daily
	)
	where empty_check = 'fail'
		or histogram_check = 'fail'
		or top_app_check = 'fail'
		or start_ts_check = 'fail'
        or end_ts_check = 'fail'
),
COMP_THERMAL_AGENT_RESULT_TAB as (
	select 'comp_thermalAgent_backward_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select a.fail_cnt + c.fail_cnt as fail_cnt
			, json_group_array('comp_thermalAgent_backward :' || c.detail || a.detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('fg_app :' || fg_app || ':' || fg_app_check || ', network_type :' || network_type || ':' || network_type_check ||
				', zone_name :' || zone_name || ':' || zone_name_check || ', max_temp :' || max_temp || ':' || max_temp_check || ', up_trend :' || up_trend || ':' || up_trend_check ||
				', down_trend :' || down_trend || ':' || down_trend_check || ', keep_trend :' || keep_trend || ':' || keep_trend_check) as detail
			from COMP_THERMAL_AGENT_TAB
		) a, (
				select count(*) as fail_cnt, json_group_array('empty_check :' || empty_check) as detail
				from (
					select case
							when count(*) = 0 then 'fail'
							else 'pass'
						end as empty_check
					from comp_thermalAgent_backward
				)
				where empty_check = 'fail'
			) c
	)
	where fail_cnt > 0
),
AGG_THERMAL_DAILY_RESULT_TAB as (
	select 'agg_thermalAgent_daily_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select fail_cnt, json_group_array('agg_thermalAgent_daily :' || detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('empty_check :' || empty_check || ', start_ts :' || start_ts || ':' || start_ts_check || ', end_ts :' || end_ts || ':' || end_ts_check ||
				', histogram :' || histogram_check || ', top_app :' || top_app_check) as detail
			from AGG_THERMAL_AGENT_DAILY_TAB
		)
	)
	where fail_cnt > 0
),
-------------battery--------------
COMP_BATTERY_AGENT_TAB as (
	select *
	from (
		select app
			, case
				when app <> '' then 'pass'
				else 'fail'
			end as app_check, input_usb_eg
			, case
				when power_mode = 1 and input_usb_eg >= 0 then 'pass'
				when power_mode = 0 and input_usb_eg = 0 then 'pass'
				else 'fail'
			end as input_usb_eg_check, battery_level
			, case
				when battery_level >= 0 and battery_level <= 100 and battery_level = cast(battery_level as int) then 'pass'
				else 'fail'
			end as battery_level_check
		from comp_batteryAgent_appPower_intv
	)
	where app_check = 'fail'
		or input_usb_eg_check = 'fail'
		or battery_level_check = 'fail'
),
AGG_BATTERY_AGENT_DAILY_TAB as (
	select *
	from (
		select case
				when count(*) = 0 then 'fail'
				else 'pass'
			end as empty_check, by_mode
			, case
				when by_mode <> '' then 'pass'
				else 'fail'
			end as by_mode_check,energy
			, case
				when energy <> '' then 'pass'
				else 'fail'
			end as energy_check,battery_fcc
			, case
				when battery_fcc >= 0 then 'pass'
				else 'fail'
			end as battery_fcc_check,soh
			, case
				when soh >= 0 then 'pass'
				else 'fail'
			end as soh_check,battery_health
			, case
				when battery_health <> '' then 'pass'
				else 'fail'
			end as battery_health_check,oplus_soh
			, case
				when oplus_soh >= 0 then 'pass'
				else 'fail'
			end as oplus_soh_check,cycle_count
			, case
				when cycle_count >= 0 then 'pass'
				else 'fail'
			end as cycle_count_check,native_cycle_count
			, case
				when native_cycle_count >= 0 then 'pass'
				else 'fail'
			end as native_cycle_count_check,oplus_cycle_count
			, case
				when oplus_cycle_count >= 0 then 'pass'
				else 'fail'
			end as oplus_cycle_count_check
		from agg_batteryAgent_daily
	)
	where empty_check = 'fail'
		or by_mode_check = 'fail'
		or energy_check = 'fail'
		or battery_fcc_check = 'fail'
		or soh_check = 'fail'
		or battery_health_check = 'fail'
		or oplus_soh_check = 'fail'
		or cycle_count_check = 'fail'
		or native_cycle_count_check = 'fail'
		or oplus_cycle_count_check = 'fail'
),
COMP_BATTERY_AGENT_RESULT_TAB as (
	select 'comp_batteryAgent_appPower_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select a.fail_cnt + c.fail_cnt as fail_cnt
			, json_group_array('comp_batteryAgent_appPower_intv :' || c.detail || a.detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('app :' || app || ':' || app_check || ', input_usb_eg :' || input_usb_eg || ':' || input_usb_eg_check ||
				', battery_level :' || battery_level || ':' || battery_level_check) as detail
			from COMP_BATTERY_AGENT_TAB
		) a, (
				select count(*) as fail_cnt, json_group_array('empty_check :' || empty_check || ', whole_eg :' || whole_eg_check) as detail
				from (
					select case
							when count(*) = 0 then 'fail'
							else 'pass'
						end as empty_check,
						case when sum(abs(whole_eg)) > 0 then 'pass'
							else 'fail'
						end as whole_eg_check
					from comp_batteryAgent_appPower_intv
				)
				where empty_check = 'fail'
			) c
	)
	where fail_cnt > 0
),
AGG_BATTERY_DAILY_RESULT_TAB as (
	select 'agg_batteryAgent_daily_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select fail_cnt, json_group_array('agg_batteryAgent_daily :' || detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('empty_check :' || empty_check || ', by_mode :' || by_mode_check || ', energy :' || energy_check ||
				', battery_fcc :' || battery_fcc || battery_fcc_check || ', soh :' || soh || soh_check || ', battery_health :' || battery_health || battery_health_check ||
				', oplus_soh :' || oplus_soh || oplus_soh_check || ', cycle_count :' || cycle_count || cycle_count_check ||
				', native_cycle_count :' || native_cycle_count || native_cycle_count_check || ', oplus_cycle_count :' || oplus_cycle_count || oplus_cycle_count_check) as detail
			from AGG_BATTERY_AGENT_DAILY_TAB
		)
	)
	where fail_cnt > 0
),
----------------------display------------
COMP_DISPLAY_AGENT_TAB as (
	select *
	from (
		select app
			, case
				when app <> '' then 'pass'
				else 'fail'
			end as app_check, brightness
			, case
				when brightness > 0 and brightness = cast(brightness as int) then 'pass'
				else 'fail'
			end as brightness_check,renderFps
			, case
				when renderFps >= 0 and renderFps = cast(renderFps as int) then 'pass'
				else 'fail'
			end as renderFps_check,whole_eg
			, case
				when whole_eg >= 0 then 'pass'
				else 'fail'
			end as whole_eg_check
		from comp_displayAgent_appPower_intv
	)
	where app_check = 'fail'
		or brightness_check = 'fail'
		or renderFps_check = 'fail'
		or whole_eg_check = 'fail'
),
AGG_DISPLAY_AGENT_DAILY_TAB as (
	select *
	from (
		select case
				when count(*) = 0 then 'fail'
				else 'pass'
			end as empty_check, by_mode
			, case
				when by_mode <> '' then 'pass'
				else 'fail'
			end as by_mode_check,by_app
			, case
				when by_app <> '' then 'pass'
				else 'fail'
			end as by_app_check,energy
			, case
				when energy <> '' then 'pass'
				else 'fail'
			end as energy_check,hist
			, case
				when hist <> '' then 'pass'
				else 'fail'
			end as hist_check,by_sumHist
			, case
				when by_sumHist <> '' then 'pass'
				else 'fail'
			end as by_sumHist_check,by_bright
			, case
				when by_bright <> '' then 'pass'
				else 'fail'
			end as by_bright_check
		from agg_displayAgent_daily
	)
	where empty_check = 'fail'
		or by_mode_check = 'fail'
		or by_app_check = 'fail'
		or energy_check = 'fail'
		or hist_check = 'fail'
		or by_sumHist_check = 'fail'
		or by_bright_check = 'fail'
),
COMP_DISPLAY_AGENT_RESULT_TAB as (
	select 'comp_displayAgent_appPower_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select a.fail_cnt + c.fail_cnt as fail_cnt
			, json_group_array('comp_displayAgent_appPower_intv :' || c.detail || a.detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('app :' || app || ':' || app_check ||
				', brightness :' || brightness || ':' || brightness_check || ', renderFps :' || renderFps || ':' || renderFps_check ||
				', whole_eg :' || whole_eg || ':' || whole_eg_check) as detail
			from COMP_DISPLAY_AGENT_TAB
		) a, (
				select count(*) as fail_cnt, json_group_array('empty_check :' || empty_check) as detail
				from (
					select case
							when count(*) = 0 then 'fail'
							else 'pass'
						end as empty_check
					from comp_displayAgent_appPower_intv
				)
				where empty_check = 'fail'
			) c
	)
	where fail_cnt > 0
),
AGG_DISPLAY_DAILY_RESULT_TAB as (
	select 'agg_displayAgent_daily_data_check' as item
		, case
			when count(*) > 0 then 'fail'
			else 'pass'
		end as result, ifnull(fail_cnt, 0) as fail_cnt, detail
	from (
		select fail_cnt, json_group_array('agg_displayAgent_daily :' || detail) as detail
		from (
			select count(*) as fail_cnt
				, json_group_array('empty_check :' || empty_check || ', by_mode :' || by_mode_check || ', by_app :' || by_app_check || ', energy :' || energy_check ||
				', hist :' || hist_check || ', by_sumHist :' || by_sumHist_check || ', by_bright :' || by_bright || by_bright_check) as detail
			from AGG_DISPLAY_AGENT_DAILY_TAB
		)
	)
	where fail_cnt > 0
)

select * from COMP_DISPLAY_AGENT_RESULT_TAB
union
select * from AGG_DISPLAY_DAILY_RESULT_TAB
union
select * from COMP_BATTERY_AGENT_RESULT_TAB
union
select * from AGG_BATTERY_DAILY_RESULT_TAB
union
select * from COMP_THERMAL_AGENT_RESULT_TAB
union
select * from AGG_THERMAL_DAILY_RESULT_TAB
union
select * from COMP_GPS_AGENT_RESULT_TAB
union
select * from AGG_GPS_APP_DAILY_RESULT_TAB
union
select * from COMP_AUDIO_AGENT_RESULT_TAB
union
select * from AGG_AUDIO_APP_DAILY_RESULT_TAB
union
select * from COMP_WIFI_RESULT_TAB
union
select * from AGG_WIFI_AGENT_DAILY_RESULT_TAB
union
select * from AGG_GPU_AGENT_DAILY_RESULT_TAB
union
select * from COMP_GPU_AGENT_RESULT_TAB
union
select * from AGG_CELLULARAGENT_DAILY_RESULT_TAB
union
select * from COMP_CELLULAR_UID_STATE_RESULT_TAB
union
select * from COMP_CELLULAR_AGENT_RESULT_TAB
union
select * from AGG_CAMERA_DAILY_RESULT_TAB
union
select * from COMP_CAMERA_RESULT_TAB
union
select * from COMP_BINDER_RESULT_TAB
union
select * from AGG_BINDER_RESULT_TAB
union
select * from CPU_RESULT_CHECK_TAB
union
select * from AGG_DAILY_CHECK_TAB
union
select * from SCREEN_MODE_FINAL_TBL
union
select * from THERMAL_MODE_FINAL_TBL
union
select * from POWER_MODE_FINAL_TBL
union
select * from LOG_ERR_CHECK_TBL
union
select * from NATIVE_PSS_INCREASE_CHECK_TBL
union
select * from GPU_FREQ_CHECK_TBL
;