with
PARAM_VAR as (
	select
	    '{}' as var_date,
		{} as var_day_start_ts,
		{} as var_day_end_ts,
		{} as var_battery_fcc,
		{} as var_soh,
		'{}' as var_battery_health,
		{} as var_oplus_soh,
		{} as var_cycle_count,
		{} as var_native_cycle_count,
		{} as var_oplus_cycle_count,
		{} as var_version
),
-- by mode ---------------------------------------------------------
BY_MODE_RAW_SUM_TBL as (
	-- select top 10 apps consumes most energy in each mode
	select *
	from (
		select app,
			sum(total_du) as total_du,
			power_mode,
			screen_mode,
			thermal_mode,
			screen_id,
			sum(battery_passed_chgq_reset_count) as battery_passed_chgq_reset_count,
			sum(battery_level_delta) as total_battery_level_delta,
			sum(input_usb_eg) as total_input_usb_eg,
			sum(whole_eg) as total_eg,
			sum(rm_eg) as rm_eg,
			sum(total_fcc_jump) as total_fcc_jump,
			sum(total_passchq_jump) as total_passchq_jump,
			charge_tech,
			fast_chg_type,
			row_number() over (partition by power_mode, screen_mode, thermal_mode order by sum(rm_eg) asc) as idx
		from agg_battery_app_hourly, PARAM_VAR
		where start_ts >= PARAM_VAR.var_day_start_ts
			and end_ts <= PARAM_VAR.var_day_end_ts
		group by app, power_mode, screen_mode, thermal_mode, screen_id, charge_tech, fast_chg_type
	) where idx <= 10
),
BY_MODE_ONECOL_TBL as (
	select json_object(
		'idx', idx,
		'app', obfuscate(app),
		'total_du', total_du,
		'screen_mode', screen_mode,
		'thermal_mode', thermal_mode,
		'power_mode', power_mode,
		'screen_id', screen_id,
		'charge_tech', charge_tech,
		'fast_chg_type', fast_chg_type,
		'battery_passed_chgq_reset_count', battery_passed_chgq_reset_count,
		'total_battery_level_delta', total_battery_level_delta,
		'total_input_usb_eg', total_input_usb_eg,
		'rm_eg', rm_eg,
		'total_fcc_jump', total_fcc_jump,
		'total_passchq_jump', total_passchq_jump,
		'total_eg', total_eg
	) as by_mode
	from BY_MODE_RAW_SUM_TBL
),
BY_MODE_OUTPUT_TBL as (
	select '[' || group_concat(by_mode, ',') || ']' as by_mode
	from BY_MODE_ONECOL_TBL
),
-- energy ---------------------------------------------------------
EG_RAW_SUM_TBL as (
	select sum(total_du) as total_du,
		power_mode,
		screen_mode,
		charge_tech,
		fast_chg_type,
		thermal_mode,
		sum(battery_level_delta) as total_battery_level_delta,
		sum(battery_passed_chgq_reset_count) as battery_passed_chgq_reset_count,
		sum(input_usb_eg) as total_input_usb_eg,
		sum(whole_eg) as total_eg,
		sum(rm_eg) as rm_eg,
		sum(total_fcc_jump) as total_fcc_jump,
		sum(total_passchq_jump) as total_passchq_jump
	from agg_battery_app_hourly, PARAM_VAR
	where start_ts >= PARAM_VAR.var_day_start_ts
		and end_ts <= PARAM_VAR.var_day_end_ts
	group by power_mode, screen_mode, thermal_mode, charge_tech, fast_chg_type
),
EG_ONECOL_TBL as (
	select json_object(
		'total_du', total_du,
		'total_eg', total_eg,
		'rm_eg', rm_eg,
		'total_fcc_jump', total_fcc_jump,
		'total_passchq_jump', total_passchq_jump,
		'total_input_usb_eg', total_input_usb_eg,
		'battery_passed_chgq_reset_count', battery_passed_chgq_reset_count,
		'total_battery_level_delta', total_battery_level_delta,
		'charge_tech', charge_tech,
		'fast_chg_type', fast_chg_type,
		'screen_mode', screen_mode,
		'thermal_mode', thermal_mode,
		'power_mode', power_mode
	) as energy
	from EG_RAW_SUM_TBL
),
EG_OUTPUT_TBL as (
	select '[' || group_concat(energy, ',') || ']' as energy
	from EG_ONECOL_TBL
),
-- level stats ---------------------------------------------------------
LEVEL_SRC_TB as (
	select * ,
		ROW_NUMBER() over(order by diff) as no_diff from (
		select diff,
			battery_level
		from (
			select otime,
				(lead(otime) over(order by otime) - otime) / (0 - state) as diff,
				state,
				cast(info as int) as battery_level
			from trig_level_Battery_eventAgent, PARAM_VAR
			where otime >= PARAM_VAR.var_day_start_ts
			    and otime <= PARAM_VAR.var_day_end_ts
		)
		where state < 0
			and diff is not null
	)
),
LEVEL_COMM_STATS_TB as (
	select max(diff) as max_level_du,
		min(diff) as min_level_du,
		cast(avg(diff) as int) as avg_level_du
	from LEVEL_SRC_TB
),
LEVEL_P_TB as (
	select json_object('percentile_level_du', json_group_array(T2.diff)) as percentile_level_du from (
		select column1 as r from (values(0.1), (0.25), (0.5), (0.75), (0.9))
	) T1
	inner JOIN
	LEVEL_SRC_TB T2
	on cast(T1.r * (select count(*) from LEVEL_SRC_TB) as int) + 1 = T2.no_diff
),
LEVEL_DETAIL_TB as (
	select json_group_object(level_detail_name, diff) as level_detail_du from (
		select
			'l_' || battery_level as level_detail_name,
			cast(avg(diff) as int) as diff
		from LEVEL_SRC_TB
		where battery_level >= 90 or battery_level <= 10
		group by battery_level
	)
),
LEVEL_STATS_ONE_COL_TB as (
	select
        json_patch(
            json_object(
                'max_level_du', ifnull(max_level_du, 'null'),
                'min_level_du', ifnull(min_level_du, 'null'),
                'avg_level_du', ifnull(avg_level_du, 'null')
            ),
            json_patch(percentile_level_du, level_detail_du)
        )
	 as level_over_all_stats
	from LEVEL_DETAIL_TB, LEVEL_COMM_STATS_TB, LEVEL_P_TB
),
-- by screen ---------------------------------------------------------
SCREEN_SRC_TB as (
	select *,
        cast( -1 * rm_eg * 3.6 / total_du as int) as mA
	from (
		select screen_id,
		    sum(total_du) as total_du,
			sum(battery_level_delta) as total_battery_level_delta,
			sum(whole_eg) as total_eg,
			sum(rm_eg) as rm_eg
		from agg_battery_app_hourly, PARAM_VAR
		where start_ts >= PARAM_VAR.var_day_start_ts
			and end_ts <= PARAM_VAR.var_day_end_ts
			and power_mode = 0
			and screen_mode = 1
			and screen_id <> -1
		group by screen_id
	)
),
SCREEN_ONE_COL_TB as (
	select json_object(
		'total_du', total_du,
		'total_eg', total_eg,
		'rm_eg', rm_eg,
		'total_battery_level_delta', total_battery_level_delta,
		'mA', mA,
		'screen_id', screen_id
	) as by_screen
	from SCREEN_SRC_TB
),
SCREEN_OUTPUT_TB as (
    select '[' || group_concat(by_screen, ',') || ']' as by_screen
    from SCREEN_ONE_COL_TB
),
COLD_HOT_START as (
	select '[' || group_concat(cold_hot_start_info, ',') || ']' as cold_hot_start_info
	from (
		select json_object(
			'cold_switch', cold_switch,
			'hot_switch', hot_switch,
			'app', obfuscate(app)
		) as cold_hot_start_info
		from (
			select
			   SUM(CASE WHEN extra = 1 THEN 1 ELSE 0 END) cold_switch,
			   SUM(CASE WHEN extra = 0 THEN 1 ELSE 0 END) hot_switch,
			   info as app
			from trig_app_cold_hot_start
			group by app
		)
	)
)
insert into agg_batteryAgent_daily
select 0 as upload,
	PARAM_VAR.var_date as date,
	PARAM_VAR.var_day_start_ts as start_ts,
	PARAM_VAR.var_day_end_ts as end_ts,
	BY_MODE_OUTPUT_TBL.by_mode as by_mode,
	EG_OUTPUT_TBL.energy as energy,
	LEVEL_STATS_ONE_COL_TB.level_over_all_stats as level_stats,
	SCREEN_OUTPUT_TB.by_screen as by_screen,
	COLD_HOT_START.cold_hot_start_info as cold_hot_start,
	PARAM_VAR.var_battery_fcc as battery_fcc,
	PARAM_VAR.var_soh as soh,
	PARAM_VAR.var_battery_health as battery_health,
	PARAM_VAR.var_oplus_soh as oplus_soh,
	PARAM_VAR.var_cycle_count as cycle_count,
	PARAM_VAR.var_native_cycle_count as native_cycle_count,
	PARAM_VAR.var_oplus_cycle_count as oplus_cycle_count,
	PARAM_VAR.var_version as version
from BY_MODE_OUTPUT_TBL, EG_OUTPUT_TBL, PARAM_VAR, LEVEL_STATS_ONE_COL_TB, SCREEN_OUTPUT_TB, COLD_HOT_START