with
PARAM_VAR as (
    select
        {} as var_date,
        {} as var_start_ts,
        {} as var_end_ts,
        {} as var_version
)
insert into agg_ddrAgent_daily
-- energy table
select 0 as upload, PARAM_VAR.var_date as date, PARAM_VAR.var_start_ts as start_ts, PARAM_VAR.var_end_ts as end_ts, EG_TBL.energy
	, TOP_APP_BY_MODE_TBL.top_app as top_app_by_mode, TOP_APP_BY_EG_TBL.top_app as top_app_by_energy, PARAM_VAR.var_version as version
from (
	select '[' || group_concat(oneline) || ']' as energy
	from (
		select '{{"screen_mode":' || screen_mode || ',"ground_mode":' || ground_mode || ', "power_mode":' || power_mode || ',"thermal_mode":' || thermal_mode
		|| ', "freq":[' || group_concat(freq) || '],"duration":[' || group_concat(duration) ||  '], "energy":[' || group_concat(energy) || ']}}' as oneline
		from (
			-- -- total duration and energy for each mode
			select screen_mode, ground_mode, power_mode, thermal_mode, freq, sum(duration) as duration, sum(energy) as energy
			from agg_ddr_app_hourly,PARAM_VAR
			where start_ts >= PARAM_VAR.var_start_ts
				and end_ts < PARAM_VAR.var_end_ts
			group by ground_mode, screen_mode, power_mode, thermal_mode, freq
		)
		group by screen_mode, ground_mode, power_mode, thermal_mode
	)
) EG_TBL, (
		select '[' || group_concat(oneline) || ']' as top_app
		from (
			select '{{"app":"' || obfuscate(app) || '","screen_mode":' || screen_mode || ',"ground_mode":' || ground_mode || ',"power_mode":' || power_mode || ',"thermal_mode":' || thermal_mode || ',"idx": ' || idx
             || ', "freq":[' || group_concat(freq) || '],"duration":[' || group_concat(duration) ||  '], "energy":[' || group_concat(energy) || ']}}' as oneline
			from (
				select app, screen_mode, ground_mode, power_mode, thermal_mode, freq
					, sum(duration) as duration, sum(energy) as energy, idx
				from (
					select T1.app, T1.screen_mode, T1.ground_mode, T1.power_mode, T1.thermal_mode
						, T1.freq, T1.duration, T1.energy as energy, T2.idx
					from agg_ddr_app_hourly T1,PARAM_VAR
						inner join (
							select *
							from (
								-- add idx for each partition
								select app, screen_mode, ground_mode, power_mode, thermal_mode
									, sum(energy) as energy, row_number() over (partition by screen_mode, ground_mode, power_mode, thermal_mode order by sum(energy) desc) as idx
								from agg_ddr_app_hourly,PARAM_VAR
								where start_ts >= PARAM_VAR.var_start_ts
				                    and end_ts < PARAM_VAR.var_end_ts
								group by app, ground_mode, screen_mode, power_mode, thermal_mode
							)
							where idx <= 10
						) T2
						on T1.app = T2.app
							and T1.ground_mode = T2.ground_mode
							and T1.screen_mode = T2.screen_mode
							and T1.power_mode = T2.power_mode
							and T1.thermal_mode = T2.thermal_mode
						where start_ts >= PARAM_VAR.var_start_ts
				            and end_ts < PARAM_VAR.var_end_ts
				)
				group by app, screen_mode, ground_mode, power_mode, thermal_mode, freq, idx
			)
			group by app, screen_mode, ground_mode, power_mode, thermal_mode, idx
		)
	) TOP_APP_BY_MODE_TBL, (
		select '[' || group_concat(oneline) || ']' as top_app
		from (
			select '{{"app":"' || obfuscate(app) || '","screen_mode":' || screen_mode || ',"ground_mode":' || ground_mode || ',"power_mode":' || power_mode || ',"thermal_mode":' || thermal_mode || ',"idx": ' || idx
             || ', "freq":[' || group_concat(freq) || '],"duration":[' || group_concat(duration) ||  '], "energy":[' || group_concat(energy) || ']}}' as oneline
			from (
				select app, screen_mode, ground_mode, power_mode, thermal_mode
					, freq, sum(duration) as duration, sum(energy) as energy
					, idx
				from (
					select T1.*, idx
					from agg_ddr_app_hourly T1,PARAM_VAR
						inner join (
							select *
							from (
								-- get top app by energy and add idx
								select app,  sum(energy) as energy, row_number() over (order by sum(energy) desc) as idx
								from agg_ddr_app_hourly,PARAM_VAR
								where start_ts >= PARAM_VAR.var_start_ts
				                    and end_ts < PARAM_VAR.var_end_ts
								group by app
							)
							where idx <= 10
						) T2
						on T1.app = T2.app
						where start_ts >= PARAM_VAR.var_start_ts
				            and end_ts < PARAM_VAR.var_end_ts
				)
				group by app, screen_mode, ground_mode, power_mode, thermal_mode, freq, idx
			)
			group by app, screen_mode, ground_mode, power_mode, thermal_mode, idx
		)
	) TOP_APP_BY_EG_TBL,PARAM_VAR
