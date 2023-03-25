create view if not exists {}.diag_obrain_Cellular_self_check as

WITH SCREEN_MODE_TBL as (
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
	select 'cellular' as agent,
		start_ts,
		end_ts,
		screen_mode,
        thermal_mode,
        1 as ground_mode,
        power_mode
	from comp_cellularagent_backward
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
		'comp_cellularagent_backward' as tbl_name
		from comp_cellularagent_backward
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
	'cell_energy' as fields,
json_valid(cell_energy) as value
from agg_cellularagent_daily

UNION ALL

SELECT
	'top_app_by_mode' as fields,
json_valid(top_app_by_mode) as value
FROM agg_cellularagent_daily

UNION ALL

SELECT
	'modem_stats' as fields,
json_valid(modem_stats) as value
FROM agg_cellularagent_daily

UNION ALL

SELECT
	'signal_du_stats' as fields,
json_valid(signal_du_stats) as value
FROM agg_cellularagent_daily
),
AGG_TABLE_RESULT as (
select
	'agg_cellularagent_daily' as tbl_name,
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
--signalLevel_check
SIGNALLEVEL_RESULT_TBL  as (
SELECT
	'cell_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(cell_energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'modem_stats' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(modem_stats)

UNION ALL

SELECT
	'signal_du_stats' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(signal_du_stats)
),
SIGNALLEVEL_REASON_TBL as (
SELECT
	fields || ' : ' || fk || ' : ' || key as field_index,
	key,
	value,
	case when value between 0 and 4 then 'pass' else 'fail' end as result
FROM SIGNALLEVEL_RESULT_TBL, json_each(val)
WHERE key = 'signalLevel'
),
AGG_SIGNALLEVEL_CHECK as (
SELECT
	'signalLevel_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
FROM SIGNALLEVEL_REASON_TBL
WHERE result = 'fail'
),
--simState_check
SIMSTATE_RESULT_TBL as (
SELECT
	'cell_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(cell_energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'modem_stats' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(modem_stats)

UNION ALL

SELECT
	'signal_du_stats' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(signal_du_stats)
),
SIMSTATE_REASON_TBL as (
SELECT
	fields || ' : ' || fk || ' : ' || key as field_index,
	key,
	value,
	case when value between 0 and 11 then 'pass' else 'fail' end as result
FROM SIMSTATE_RESULT_TBL, json_each(val)
WHERE key = 'simState'
),
AGG_SIMSTATE_CHECK as (
SELECT
	'simState_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
FROM SIMSTATE_REASON_TBL
WHERE result = 'fail'
),
--duplexMode_check
DUPLEXMODE_RESULT_TBL as (
SELECT
	'cell_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(cell_energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'modem_stats' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(modem_stats)

UNION ALL

SELECT
	'signal_du_stats' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(signal_du_stats)
),
DUPLEXMODE_REASON_TBL as (
SELECT
	fields || ' : ' || fk || ' : ' || key as field_index,
	key,
	value,
	case when value in(0,1,2) then 'pass' else 'fail' end as result
FROM DUPLEXMODE_RESULT_TBL, json_each(val)
WHERE key = 'duplexMode'
),
AGG_DUPLEXMODE_CHECK as (
SELECT
	'duplexMode_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
FROM DUPLEXMODE_REASON_TBL
WHERE result = 'fail'
),
--tx_rx_xxx_time_check
TX_RX_XXX_TIME_RESULT_TBL as (
SELECT
	'cell_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(cell_energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'modem_stats' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(modem_stats)

UNION ALL

SELECT
	'signal_du_stats' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(signal_du_stats)
),
TX_RX_XXX_TIME_REASON_TBL as (
SELECT
	'agg_cellularagent_daily' || ' : ' || fields as field_index,
	sum(value) as sum_val,
	case when sum(value) >= 0 and sum(value) <= 86400 * 1000 then 'pass' else 'fail' end as result
FROM TX_RX_XXX_TIME_RESULT_TBL, json_each(val)
WHERE
	key like 'tx%time'
or
	key like 'rx%time'
group by fields
),
AGG_TX_RX_XXX_TIME_CHECK as (
SELECT
	'tx_rx_xxx_time_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
FROM TX_RX_XXX_TIME_REASON_TBL
WHERE result = 'fail'
),
--tx_rx_xxx_byte_check
TX_RX_XXX_BYTE_RESULT_TBL as (
SELECT
	'cell_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(cell_energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'modem_stats' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(modem_stats)

UNION ALL

SELECT
	'signal_du_stats' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(signal_du_stats)
),
TX_RX_XXX_BYTE_REASON_TBL as (
SELECT
	'agg_cellularagent_daily' || ' : ' || fields  as field_index,
	key,
	sum(value),
	case when sum(value) >= 0 and sum(value) < (1024 * 1024 * 1024 * 1024) / 8 then 'pass' else 'fail' end as result
FROM TX_RX_XXX_BYTE_RESULT_TBL, json_each(val)
WHERE
	key like 'tx%byte'
or
	key like 'rx%byte'
group by fields,key
),
AGG_TX_RX_XXX_BYTE_CHECK as (
SELECT
	'tx_rx_xxx_byte_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
FROM TX_RX_XXX_BYTE_REASON_TBL
WHERE result = 'fail'
),
--incall_du_check
INCALL_DU_RESULT_TBL as (
SELECT
	'cell_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(cell_energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'modem_stats' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(modem_stats)

UNION ALL

SELECT
	'signal_du_stats' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(signal_du_stats)
),
INCALL_DU_REASON_TBL as (
SELECT
	'agg_cellularagent_daily' || ' : ' || fields as field_index,
	sum(value),
	case when sum(value) <= 16 * 3500 * 1000 then 'pass' else 'fail' end as result
FROM INCALL_DU_RESULT_TBL, json_each(val)
WHERE key = 'incall_du'
group by fields
),
AGG_INCALL_DU_CHECK as (
SELECT
	'incall_du_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
FROM INCALL_DU_REASON_TBL
WHERE result = 'fail'
),
--sum(rx_&_sleep_time)_check
RX_XX_5G_SLEEP_TIME_RESULT_TBL as (
SELECT
	'cell_energy' as fields,
	value as val
FROM agg_cellularagent_daily, json_each(cell_energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	value as val
FROM agg_cellularagent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'modem_stats' as fields,
	value as val
FROM agg_cellularagent_daily, json_each(modem_stats)

UNION ALL

SELECT
	'signal_du_stats' as fields,
	value as val
FROM agg_cellularagent_daily, json_each(signal_du_stats)
),
RX_XX_5G_SLEEP_TIME_REASON_TBL as (
SELECT
	'agg_cellularagent_daily' || ' : ' || fields  as field_index,
	sum(value) as sum_value,
	case when sum(value) <= 86400 * 1000 then 'pass' else 'fail' end as result
FROM RX_XX_5G_SLEEP_TIME_RESULT_TBL, json_each(val)
WHERE key in ('rx_time', 'rx_5g_time', 'sleep_time')
group by fields
),
AGG_RX_XX_5G_SLEEP_TIME_CHECK as (
SELECT
	'sum(rx_&_sleep_time)_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
FROM RX_XX_5G_SLEEP_TIME_REASON_TBL
WHERE result = 'fail'
),--total_eg_check
TOTAL_EG_RESULT_TBL as (
SELECT
	'cell_energy' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(cell_energy)

UNION ALL

SELECT
	'top_app_by_mode' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(top_app_by_mode)

UNION ALL

SELECT
	'modem_stats' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(modem_stats)

UNION ALL

SELECT
	'signal_du_stats' as fields,
	fullkey as fk,
	value as val
FROM agg_cellularagent_daily, json_each(signal_du_stats)
),
TOTAL_EG_REASON_TBL as (
SELECT
	fields || ' : ' || key as field_index,
	key,
	sum(value),
	case when sum(value) >= 0 and sum(value) < 4000 * 1000000 then 'pass' else 'fail' end as result
FROM TOTAL_EG_RESULT_TBL, json_each(val)
WHERE key = 'total_eg'
GROUP by fields
),
AGG_TOTAL_EG_CHECK as (
SELECT
	'total_eg_check' as item,
	case when count(*) = 0 then 'pass' else 'fail' end as result,
	count(*) as fail_cnt,
	json_group_array(field_index) as detail
FROM TOTAL_EG_REASON_TBL
WHERE result = 'fail'
)
SELECT * FROM AGG_TOTAL_EG_CHECK
UNION
SELECT * FROM AGG_RX_XX_5G_SLEEP_TIME_CHECK
UNION
SELECT * FROM AGG_INCALL_DU_CHECK
UNION
SELECT * from AGG_TX_RX_XXX_BYTE_CHECK
UNION
SELECT * FROM AGG_TX_RX_XXX_TIME_CHECK
UNION
SELECT * FROM AGG_DUPLEXMODE_CHECK
UNION
SELECT * FROM AGG_SIMSTATE_CHECK
UNION
SELECT * FROM AGG_SIGNALLEVEL_CHECK
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