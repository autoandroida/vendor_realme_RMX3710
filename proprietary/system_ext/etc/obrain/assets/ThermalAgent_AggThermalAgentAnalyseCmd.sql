with
PARAM_VAR as (
    select
        {} as var_start_ts,
        {} as var_end_ts,
        {} as var_idx
),
upTrend as (
	select min(max_temp) as my_start_temp, max(max_temp) as my_end_temp, uptrend_start_ts, uptrend_end_ts
	, min(wall_start_ts) as uptrend_wall_start_ts, max(wall_end_ts) as uptrend_wall_end_ts
	from(
		select round(avg(max_temp)) as max_temp, PARAM_VAR.var_start_ts as uptrend_start_ts, PARAM_VAR.var_end_ts as uptrend_end_ts
		, min(wall_start_ts) as wall_start_ts, max(wall_end_ts) as wall_end_ts
		from comp_thermalAgent_backward, PARAM_VAR
		where zone_name like 'shell_%'
			and start_ts >= PARAM_VAR.var_start_ts
			and end_ts <= PARAM_VAR.var_end_ts
		group by uptrend_start_ts, uptrend_end_ts, start_ts, end_ts
	)
),
thermal_cpu as (
    select 'cpu' as agent_name, json_object('name', json_group_array(name), 'type', json_group_array(type)
        , 'total_eg', json_group_array(total_eg), 'total_du', json_group_array(total_du)) as ana_list
    from (
        select type, name, sum(total_eg) as total_eg
            , SumVectorI('sum(c$0_duration)', CpuClusterList) as total_du
        from(
            select case when pid = -1 and tgid = -1 then 0 else 1 end as type
                , case when pid = -1 and tgid = -1 then uid_name else tgid_name end as name
                , sum(total_eg) as total_eg
                , VectorSuffixSumVectorII(' as c$0_duration', 'sum(c$0_$1_du)', CpuClusterList, CpuFreqListList)
            from comp_uidstate_cpuagent_backward
            where start_ts >= (select upTrend.uptrend_start_ts from upTrend)
                and end_ts <= (select upTrend.uptrend_end_ts from upTrend)
            group by type, name
        )
        group by type, name
        order by total_eg DESC
        limit (select PARAM_VAR.var_idx from PARAM_VAR)
    )
),
thermal_wifi as (
    select 'wifi' as agent_name, json_object('package_name', json_group_array(package_name), 'tx_byte', json_group_array(tx_byte)
        , 'rx_byte', json_group_array(rx_byte), 'total_eg', json_group_array(total_eg)) as ana_list
    from(
        select package_name
            , sum(tx_byte) AS tx_byte
            , sum(rx_byte) AS rx_byte
            , sum(total_eg) AS total_eg
        from comp_wifi_agent_intv
        where start_ts >= (select upTrend.uptrend_start_ts from upTrend)
            and end_ts <= (select upTrend.uptrend_end_ts from upTrend)
        group by package_name
        order by total_eg DESC
        limit (select PARAM_VAR.var_idx from PARAM_VAR)
    )
),
thermal_display as (
    select 'display' as agent_name, json_object('app', json_group_array(app), 'total_du', json_group_array(total_du)
        , 'avg_fps', json_group_array(avg_fps), 'max_fps', json_group_array(max_fps), 'avg_brightness', json_group_array(avg_brightness)
        , 'avg_renderFps', json_group_array(avg_renderFps), 'max_renderFps', json_group_array(max_renderFps)
        , 'whole_eg', json_group_array(whole_eg)) as ana_list
    from(
        select app
            , sum(time_delta) as total_du
            , round(avg(FPS),1) as avg_fps
            , max(FPS) as max_fps
            , round(avg(brightness) / 100 * 100, 1) as avg_brightness
            , max(brightness) / 100 * 100 as max_brightness
            , round((avg(renderFps) + 5 / 10 * 10), 1) as avg_renderFps
            , (max(renderFps) + 5 / 10 * 10) as max_renderFps
            , sum(whole_eg) as whole_eg
        from comp_displayAgent_appPower_intv
        where start_ts >= (select upTrend.uptrend_start_ts from upTrend)
            and end_ts <= (select upTrend.uptrend_end_ts from upTrend)
        group by app
        order by total_du DESC
        limit (select PARAM_VAR.var_idx from PARAM_VAR)
    )
),
thermal_binder as (
    select 'binder' as agent_name, json_object('service_name', json_group_array(service_name), 'caller_calltime', json_group_array(caller_calltime)) as ana_list
    from (
        select service_name
            , sum(value) as caller_calltime
        from  comp_binderstats_binderagent_backward, json_each(caller_calltimes)
        where caller_uid_names != 'unknown'
            and start_ts >= (select upTrend.uptrend_start_ts from upTrend)
            and end_ts <= (select upTrend.uptrend_end_ts from upTrend)
        group by service_name
        order by caller_calltime DESC
        limit (select PARAM_VAR.var_idx from PARAM_VAR)
    )
),
thermal as (
    select 'thermal' as agent_name, json_object('wall_start_ts', json_group_array(wall_start_ts), 'temp', json_group_array(max_temp)) as ana_list
    from (
        select min(wall_start_ts) as wall_start_ts, max(wall_end_ts) as wall_end_ts
            , round(avg(max_temp), 1) as max_temp, round((start_ts - uptrend_start_ts) / (1000 * 60)) as dd
        from comp_thermalAgent_backward, upTrend
        where start_ts >= uptrend_start_ts
        and end_ts <= uptrend_end_ts
        and zone_name like 'shell_%'
        group by dd
    )
),
thermal_battery as (
    select 'battery' as agent_name, json_object('power_mode', json_group_array(power_mode), 'avg_cur', json_group_array(avg_cur)
        , 'total_eg', json_group_array(total_eg)) as ana_list
    from (
        select power_mode, round(sum(case when power_mode = 1 then input_usb_eg else rm_delta end) * 3.6 / sum(time_delta), 2) as avg_cur
        , sum(case when power_mode = 1 then input_usb_eg else rm_delta end) as total_eg
        from comp_batteryAgent_appPower_intv, upTrend
        where start_ts >= uptrend_start_ts
        and end_ts <= uptrend_end_ts
        group by power_mode
    )
)

insert into agg_thermalAgent_analysis
	select upTrend.uptrend_start_ts as start_ts, upTrend.uptrend_end_ts as end_ts, json_object('uptrend_start_ts', upTrend.uptrend_wall_start_ts
	    , 'uptrend_end_ts', upTrend.uptrend_wall_end_ts, 'uptrend_start_temp', upTrend.my_start_temp
		, 'uptrend_end_temp', upTrend.my_end_temp, thermal_cpu.agent_name, json(thermal_cpu.ana_list)
		, thermal_wifi.agent_name, json(thermal_wifi.ana_list), thermal_display.agent_name, json(thermal_display.ana_list)
		, thermal_binder.agent_name, json(thermal_binder.ana_list), thermal.agent_name, json(thermal.ana_list)
		, thermal_battery.agent_name, json(thermal_battery.ana_list)) as analysis
	from thermal_cpu, thermal_wifi, thermal_display, thermal_binder, thermal, thermal_battery, upTrend