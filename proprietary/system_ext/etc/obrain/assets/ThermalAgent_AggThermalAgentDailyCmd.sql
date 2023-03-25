with
PARAM_VAR as (
    select
        {} as var_date,
        {} as var_version,
        {} as var_start_ts,
        {} as var_end_ts
)
insert into agg_thermalAgent_daily
select 0 as upload, var_date as date,  PARAM_VAR.var_start_ts as start_ts, PARAM_VAR.var_end_ts as end_ts, HIST_TBL.histogram, TOP_APP_TBL.top_app, ANALYSIS.analysis, PARAM_VAR.var_version as version
from (
	select json_group_array(oneline) as histogram
	from (
		select json_object('type', zone_name, 'screen_mode', screen_mode, 'power_mode', power_mode, 'thermal_mode', thermal_mode
		       , 'max_temp', max_temp, 'network_type', network_type, 'up_trend', up_trend, 'down_trend', down_trend, 'keep_trend', keep_trend, 'max_rate', max_rate, 'temp', json_array(VectorI('zone$0', ThermalList))) as oneline
		from (
			select zone_name, power_mode, screen_mode, thermal_mode, network_type
			    , max(max_temp) as max_temp
                , sum(up_trend) as up_trend
                , sum(down_trend) as down_trend
                , sum(keep_trend) as keep_trend
                , round(avg(max_rate), 2) as max_rate
			    , VectorI('sum(zone$0) AS zone$0', ThermalList)
			from agg_thermalAgent_hourly, PARAM_VAR
			where start_ts >= PARAM_VAR.var_start_ts
				and end_ts <= PARAM_VAR.var_end_ts
			group by zone_name, screen_mode, power_mode, thermal_mode, network_type
		)
	)
) HIST_TBL, (
		select json_group_array(oneline) as top_app
		from (
			select json_object('fg_app', obfuscate(fg_app), 'type', zone_name, 'screen_mode', screen_mode, 'power_mode', power_mode, 'thermal_mode', thermal_mode
			      , 'max_temp', max_temp, 'network_type', network_type, 'up_trend', up_trend, 'down_trend', down_trend, 'keep_trend', keep_trend, 'max_rate', max_rate, 'idx', idx, 'temp', json_array(VectorI('zone$0', ThermalList))) as oneline
			from (
				select fg_app, zone_name, screen_mode, power_mode, thermal_mode, network_type
				    , max(max_temp) as max_temp
                    , sum(up_trend) as up_trend
                    , sum(down_trend) as down_trend
                    , sum(keep_trend) as keep_trend
                    , round(avg(max_rate), 2) as max_rate
				    , VectorI('sum(zone$0) AS zone$0', ThermalList)
					, idx
				from (
					select T1.fg_app, T1.screen_mode, T1.power_mode, T1.thermal_mode, zone_name, T1.network_type
					    , max_temp
					    , up_trend
					    , down_trend
					    , keep_trend
					    , max_rate
					    , VectorI('zone$0', ThermalList)
						, T2.idx
					from PARAM_VAR, agg_thermalAgent_hourly T1
						inner join (
							select *
							from (
								-- add idx for each partition
								select fg_app, screen_mode, power_mode, thermal_mode, network_type
									, row_number() over (partition by screen_mode, power_mode, thermal_mode, network_type order by 1.0 * (SumVector2II('sum(zone$0)*$1', ThermalList, WaterMarkList)) / (SumVector2II('sum(zone$0)*$1', ThermalList, OneList)) desc) as idx
								from agg_thermalAgent_hourly, PARAM_VAR
                                where start_ts >= PARAM_VAR.var_start_ts
                                    and end_ts <= PARAM_VAR.var_end_ts
								group by fg_app, screen_mode, power_mode, thermal_mode, network_type
							)
							where idx <= 10
						) T2
						on T1.fg_app = T2.fg_app
							and T1.screen_mode = T2.screen_mode
							and T1.power_mode = T2.power_mode
							and T1.thermal_mode = T2.thermal_mode
							and T1.network_type = T2.network_type
                    where start_ts >= PARAM_VAR.var_start_ts
                        and end_ts <= PARAM_VAR.var_end_ts
				)
				group by idx, fg_app, screen_mode, power_mode, thermal_mode, zone_name, network_type
			)
		)
	) TOP_APP_TBL,(
	    select json_group_array(analysis) as analysis
	    from agg_thermalAgent_analysis, PARAM_VAR
	    where start_ts >= PARAM_VAR.var_start_ts
            and end_ts <= PARAM_VAR.var_end_ts
	) ANALYSIS, PARAM_VAR