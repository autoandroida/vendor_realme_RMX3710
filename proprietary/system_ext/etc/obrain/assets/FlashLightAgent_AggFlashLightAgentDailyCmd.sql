with
PARAM_VAR as (
    select
        {} as var_date,
        {} as var_version,
        {} as var_start_ts,
        {} as var_end_ts
)
insert into agg_flashlightAgent_daily
-- energy table
select 0 as upload, PARAM_VAR.var_date as date, PARAM_VAR.var_start_ts, PARAM_VAR.var_end_ts, EG_TBL.energy
	, TOP_APP_BY_MODE_TBL.top_app as top_app_by_mode, TOP_APP_BY_EG_TBL.top_app as top_app_by_energy, PARAM_VAR.var_version as version
from (
	select json_group_array(oneline) as energy
	from (
		select json_object('screen_mode', screen_mode, 'ground_mode', ground_mode, 'power_mode'
		, power_mode, 'thermal_mode', thermal_mode, 'Torch_eg', Torch_eg, 'Torch_dur'
		, duration) as oneline
		from (
			-- -- total Torch_dur and energy for each mode
			select screen_mode, ground_mode, power_mode, thermal_mode
				  , sum(Torch_dur) as duration, sum(Torch_eg) as Torch_eg
			from agg_flashlight_app_hourly, PARAM_VAR
			where start_ts >= PARAM_VAR.var_start_ts and end_ts < PARAM_VAR.var_end_ts
			group by ground_mode, screen_mode, power_mode, thermal_mode
		)
		group by screen_mode, ground_mode, power_mode, thermal_mode
	)
) EG_TBL, (
		select json_group_array(oneline) as top_app
		from (
			select json_object('TorchName', obfuscate(TorchName), 'screen_mode', screen_mode, 'ground_mode'
			, ground_mode, 'power_mode', power_mode, 'thermal_mode', thermal_mode, 'idx'
			, idx, 'duration', duration, 'Torch_eg', Torch_eg) as oneline
			from (
				select TorchName,  screen_mode, ground_mode, power_mode, thermal_mode
					, sum(duration) as duration , sum(Torch_eg) as Torch_eg, idx
				from (
					select T1.TorchName, T1.screen_mode, T1.ground_mode, T1.power_mode, T1.thermal_mode
						, Torch_dur as duration, T1.Torch_eg as Torch_eg, T2.idx
					from PARAM_VAR, agg_flashlight_app_hourly T1
						inner join (
							select *
							from (
								-- add idx for each partition
								select TorchName, screen_mode, ground_mode, power_mode, thermal_mode
									, sum(Torch_eg) as Torch_eg, row_number() over (partition by screen_mode, ground_mode, power_mode, thermal_mode order by sum(Torch_eg) desc) as idx
								from agg_flashlight_app_hourly, PARAM_VAR
                                where start_ts >= PARAM_VAR.var_start_ts and end_ts < PARAM_VAR.var_end_ts
								group by TorchName, ground_mode, screen_mode, power_mode, thermal_mode
							)
							where idx <= 10
						) T2
						on T1.TorchName = T2.TorchName
							and T1.ground_mode = T2.ground_mode
							and T1.screen_mode = T2.screen_mode
							and T1.power_mode = T2.power_mode
							and T1.thermal_mode = T2.thermal_mode
                        where start_ts >= PARAM_VAR.var_start_ts and end_ts < PARAM_VAR.var_end_ts
				)
				group by TorchName, screen_mode, ground_mode, power_mode, thermal_mode
			)
		)
	) TOP_APP_BY_MODE_TBL, (
		select json_group_array(oneline) as top_app
		from (
			select json_object('TorchName', obfuscate(TorchName), 'screen_mode', screen_mode, 'ground_mode'
			, ground_mode, 'power_mode', power_mode, 'thermal_mode', thermal_mode, 'idx'
			, idx, 'duration', duration, 'Torch_eg', Torch_eg) as oneline
			from (
				select TorchName, screen_mode, ground_mode, power_mode, thermal_mode
					,  sum(Torch_dur) as duration, sum(Torch_eg) as Torch_eg, idx
				from (
					select *
					from PARAM_VAR, agg_flashlight_app_hourly T1
						inner join (
							select *
							from (
								-- get top app by energy and add idx
								select TorchName,  sum(Torch_eg) as Torch_eg, row_number() over (order by sum(Torch_eg) desc) as idx
								from agg_flashlight_app_hourly, PARAM_VAR
								where start_ts >= PARAM_VAR.var_start_ts and end_ts < PARAM_VAR.var_end_ts
								group by TorchName
							)
							where idx <= 10
						) T2
						on T1.TorchName = T2.TorchName
                        where start_ts >= PARAM_VAR.var_start_ts and end_ts < PARAM_VAR.var_end_ts
				)
				group by TorchName, screen_mode, ground_mode, power_mode, thermal_mode
			)
		)
	) TOP_APP_BY_EG_TBL, PARAM_VAR
