create view if not exists {}.diag_obrain_Wifi_self_check as
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
	select 'wifi' as agent,
		start_ts,
		end_ts,
		screen_mode,
        thermal_mode,
        ground_mode,
        power_mode
	from comp_wifi_agent_intv
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
		'comp_wifi_agent_intv' as tbl_name
	from comp_wifi_agent_intv
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
	select json_valid(energy) as json_result,
		'agg_wifi_agent_daily' as table_name,
		'energy' as fields
	from agg_wifi_agent_daily
	UNION
	select json_valid(top_app_by_mode) as json_result,
		'agg_wifi_agent_daily' as table_name,
		'top_app_by_mode' as fields
	from agg_wifi_agent_daily
	UNION
	select json_valid(attach) as json_result,
		'agg_wifi_agent_daily' as table_name,
		'attach' as fields
	from agg_wifi_agent_daily
),
JSON_ERROR_CHECK_TABLE as (
	select 'json_check' as item ,
		case
		    when count(*) = 0 then 'pass'
		    else 'fail'
		end as result ,
		count(*) as fail_cnt,
		json_group_array(table_name || ":" || fields) as detail
	from AGG_JSON_TABLE
		where json_result = 0
),
--------
JSON_EACH_TAB as (
	select value as val,
		'energy' as fields ,
		fullkey as fk
	from agg_wifi_agent_daily,json_each(energy)
UNION
	select value as val,
		'top_app_by_mode' as fields ,
		fullkey as fk
	from agg_wifi_agent_daily,json_each(top_app_by_mode)
UNION
	select value as val,
		fields,
		ke || fullkey as fk
	from (
		select value as val ,
			'attach' as fields,
			key as ke
		from agg_wifi_agent_daily,json_each(attach)
		), json_each(val)
),
RESULT_JSON_TAB as (
	select
		fields,
		key,
		value,
		fk
		from JSON_EACH_TAB,json_each(val)
),
------
BUSY_DU_CHECK as (
	select *,
		sum(value) as sum_value,
		case
			when sum(value) <= 86400 * 1000 and sum(value) >= 0 then 'pass'
			else 'fail'
		end as resulT
	from RESULT_JSON_TAB where key = 'busy_du'
		group by fields
),
BUSY_DU_CHECK_TAB as (
	select
		'busy_du_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || ':sum(busy_du)' || sum_value) as detail
	from BUSY_DU_CHECK  where result = 'fail'
),
-------
XX_TIME_CHECK as (
	select *,
		sum(value) as sum_value,
		case
			when sum(value) >= 0 and sum(value) <= 86400 * 1000 then 'pass'
			else 'fail'
		end as result
	from RESULT_JSON_TAB
	where key = 'rx_time' or key = 'tx_time'
		group by fields,key
),
XX_TIME_CHECK_TAB as (
	select
		'xx_time_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || ':' || key || sum_value) as detail
	from XX_TIME_CHECK  where result = 'fail'
),
--------
XX_BYTE_CHECK as (
	select *,
		sum(value) as sum_value,
		case
			when sum(value) >= 0 and sum(value) <= (1024 * 1024 * 1024 * 1024) / 8 then 'pass'
			else 'fail'
		end as result
	from RESULT_JSON_TAB
	where key = 'rx_byte' or key = 'tx_byte'
		group by fields,key
),
XX_BYTE_CHECK_TAB as (
	select
		'xx_data_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || ':' ||  key || sum_value) as detail
	from XX_BYTE_CHECK  where result = 'fail'
),
--------
TOTAL_EG_CHECK as (
	select *,
		sum(value) as sum_value,
		case
			when sum(value) >= 0 and sum(value) <= 4000 * 1000000 then 'pass'
			else 'fail'
		end as result
	from RESULT_JSON_TAB
	where key = 'total_eg'
		group by fields
),
TOTAL_EG_CHECK_TAB as (
	select
		'sum_total_eg_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || ':' || key || sum_value) as detail
	from TOTAL_EG_CHECK  where result = 'fail'
),
-----
RX_PACKET_CHECK as (
	select *,
		json_extract(val,'$.rx_packet') as rx_packet,
		json_extract(val,'$.rx_byte') as rx_byte
	from JSON_EACH_TAB
),
RESULT_RX_PACKET_CHECK as (
	select *,
		case
			when rx_packet >= 0 and rx_packet <= rx_byte then 'pass'
			else 'fail'
		end as result
	from RX_PACKET_CHECK
	where fields != 'attach'
),
RX_PACKET_CHECK_TAB as (
	select
		'rx_packet_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || ':' || fk) as detail
	from RESULT_RX_PACKET_CHECK  where result = 'fail'
),
-----------
STANDARD_CHECK as (
	select *,
		case
			when value in ('802.11a','802.11b','802.11g','802.11n','802.11ac','802.11ax','unknown') then 'pass'
			else 'fail'
		end as result
	from RESULT_JSON_TAB where key = 'standard'
),

STANDARD_CHECK_TAB as (
	select
		'standard_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || ':' || fk || value) as detail
	from STANDARD_CHECK  where result = 'fail'
),
----------
SUM_TOTAL_EG_CHECK as (
	select (T1.energy_total_eg - T2.top_total_eg) as result
	from(
		select sum(json_extract(val,'$.total_eg')) as energy_total_eg
		from JSON_EACH_TAB
		where fields = 'energy'
		) T1,
		(
		select sum(json_extract(val,'$.total_eg')) as top_total_eg
		from JSON_EACH_TAB
		where fields = 'top_app_by_mode'
		) T2
),
SUM_TOTAL_EG_CHECK_TAB as (
	select
		'sum(app_total_eg) <= total_eg' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(result) as detail
	from (
		select *,
			case
				when result > 0 then 'pass'
				else 'fail'
			end as result1
		from SUM_TOTAL_EG_CHECK
		) where result1 = 'fail'
),
--------
FREQENCY_BAND_CHECK as (
	select *,
		case
			when value in ('2.4G','5G','unknown') then 'pass'
			else 'fail'
		end as result
	from RESULT_JSON_TAB where key = 'freqency_band'
),
FREQENCY_BAND_CHECK_TAB as (
	select
		'freqency_band_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || ':' || fk || value) as detail
	from FREQENCY_BAND_CHECK where result = 'fail'
),
---------
HOTSPOT_CHECK as (
	select *,
		case
			when value = 0 or value = 1 then 'pass'
			else 'fail'
		end as result
	from RESULT_JSON_TAB
	where key = 'hotspot'
),
HOTSPOT_CHECK_TAB as (
	select
		'hotspot_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || ':' || fk || value) as detail
	from HOTSPOT_CHECK where result = 'fail'
),
-------
WIFI_ID_CHECK as (
	select *,
		case
			when value = 0 or value = 1 then 'pass'
			else 'fail'
		end as result
	from RESULT_JSON_TAB where key = 'wifi_id'
),
WIFI_ID_CHECK_TAB as (
	select
		'wifi_id_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || ':' || fk || value) as detail
	from WIFI_ID_CHECK where result = 'fail'
),
-----
ENABLE_CHECK as (
	select *,
		case
			when value = 0 or value = 1 then 'pass'
			else 'fail'
		end as result
	from RESULT_JSON_TAB where key = 'enable'
),
ENABLE_CHECK_TAB as (
	select
		'enable_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || ':' || fk || value) as detail
	from ENABLE_CHECK where result = 'fail'
),
-------
ENABLE_HOTSPOT_CHECK as (
	select *,
		json_extract(val,'$.enable') as enable,
		json_extract(val,'$.hotspot') as hotspot
	from JSON_EACH_TAB where fields != 'attach'
),
RESULT_ENABLE_HOTSPOT_CHECK as (
	select *,
		case
			when hotspot = 1 then 'pass'
			else 'fail'
		end as result
	from ENABLE_HOTSPOT_CHECK  where enable = 0
),
ENABLE_HOTSPOT_CHECK_TAB as (
	select
		'enable_hotspot_check' as item,
		case
			when count(*) = 0 then 'pass'
			else 'fail'
		end as result,
		count(*) as fail_cnt,
		json_group_array(fields || ':' || fk) as detail
	from RESULT_ENABLE_HOTSPOT_CHECK where result = 'fail'
)

select * from ENABLE_HOTSPOT_CHECK_TAB
union
select * from ENABLE_CHECK_TAB
union
select * from WIFI_ID_CHECK_TAB
union
select * from HOTSPOT_CHECK_TAB
union
select * from FREQENCY_BAND_CHECK_TAB
union
select * from SUM_TOTAL_EG_CHECK_TAB
union
select * from STANDARD_CHECK_TAB
union
select * from RX_PACKET_CHECK_TAB
union
select * from TOTAL_EG_CHECK_TAB
union
select * from XX_BYTE_CHECK_TAB
union
select * from XX_TIME_CHECK_TAB
union
select * from BUSY_DU_CHECK_TAB
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