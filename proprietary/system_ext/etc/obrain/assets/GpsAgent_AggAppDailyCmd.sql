with
PARAM_VAR as (
    select
        {} as var_date,
        {} as var_version,
        {} as var_start_ts,
        {} as var_end_ts
)
insert into agg_gps_app_daily
-- energy table
select 0 as upload, PARAM_VAR.var_date as date, PARAM_VAR.var_start_ts as start_ts, PARAM_VAR.var_end_ts as end_ts
	, TOP_APP_BY_MODE_TBL.top_app as top_app_by_mode, TOP_APP_BY_EG_TBL.top_app as top_app_by_energy, EG_TBL.energy, PARAM_VAR.var_version as version
from (
	select '[' || group_concat(oneline) || ']' as energy
	from (
		select '{{"screen_mode":' || screen_mode || ',"ground_mode":' || ground_mode || ', "power_mode":' || power_mode || ',"thermal_mode":' || thermal_mode || ',"status":' || status || ',"duration":' || duration || ',"total_eg":' || total_eg || '}}' as oneline
		from (
			-- -- total duration and energy for each mode
			select screen_mode, ground_mode, power_mode, thermal_mode, status
				, sum(duration) as duration, sum(energy) as total_eg
			from agg_gps_app_hourly,PARAM_VAR
			where start_ts >= PARAM_VAR.var_start_ts AND end_ts < PARAM_VAR.var_end_ts
			group by ground_mode, screen_mode, power_mode, thermal_mode, status
		)
		group by screen_mode, ground_mode, power_mode, thermal_mode, status
	)
) EG_TBL, (
		select '[' || group_concat(oneline) || ']' as top_app
		from (
			select '{{"gnss_app":"' || obfuscate(gnss_app) || '","screen_mode":' || screen_mode || ',"ground_mode":' || ground_mode || ',"power_mode":' || power_mode || ',"thermal_mode":' || thermal_mode || ',"status":' || status || ',"idx":' || idx || ',"duration":' || duration || ',"total_eg":' || total_eg || '}}' as oneline
			from (
				select gnss_app, screen_mode, ground_mode, power_mode, thermal_mode
					, status, sum(duration) as duration, sum(energy) as total_eg
					, idx
				from (
					select T1.gnss_app, T1.screen_mode, T1.ground_mode, T1.power_mode, T1.thermal_mode
						, T1.status, T1.duration, T1.energy, T2.idx
					from agg_gps_app_hourly T1
						inner join (
							select *
							from (
								-- add idx for each partition
								select gnss_app, screen_mode, ground_mode, power_mode, thermal_mode
									, sum(energy) as total_eg, row_number() over (partition by screen_mode, ground_mode, power_mode, thermal_mode order by sum(energy) desc) as idx
								from agg_gps_app_hourly,PARAM_VAR
								where start_ts >= PARAM_VAR.var_start_ts AND end_ts < PARAM_VAR.var_end_ts
								group by gnss_app, ground_mode, screen_mode, power_mode, thermal_mode
							)
							where idx <= 10
						) T2
						on T1.gnss_app = T2.gnss_app
							and T1.ground_mode = T2.ground_mode
							and T1.screen_mode = T2.screen_mode
							and T1.power_mode = T2.power_mode
							and T1.thermal_mode = T2.thermal_mode
				)
				group by gnss_app, screen_mode, ground_mode, power_mode, thermal_mode, status
			)
		)
	) TOP_APP_BY_MODE_TBL, (
		select '[' || group_concat(oneline) || ']' as top_app
		from (
			select '{{"gnss_app":"' || obfuscate(gnss_app) || '","screen_mode":' || screen_mode || ',"ground_mode":' || ground_mode || ',"power_mode":' || power_mode || ',"thermal_mode":' || thermal_mode || ',"status":' || status || ',"idx":' || idx || ',"duration":' || duration || ',"total_eg":' || total_eg || '}}' as oneline
			from (
				select gnss_app, screen_mode, ground_mode, power_mode, thermal_mode
					, status, sum(duration) as duration, sum(energy) as total_eg
					, idx
				from (
					select *
					from agg_gps_app_hourly T1,PARAM_VAR
						inner join (
							select *
							from (
								-- get top app by energy and add idx
								select gnss_app, sum(energy) as total_eg, row_number() over (order by sum(energy) desc) as idx
								from agg_gps_app_hourly,PARAM_VAR
								where start_ts >= PARAM_VAR.var_start_ts AND end_ts < PARAM_VAR.var_end_ts
								group by gnss_app
							)
							where idx <= 10
						) T2
						on T1.gnss_app = T2.gnss_app
					where start_ts >= PARAM_VAR.var_start_ts AND end_ts < PARAM_VAR.var_end_ts
				)
				group by gnss_app, screen_mode, ground_mode, power_mode, thermal_mode, status
			)
		)
	) TOP_APP_BY_EG_TBL,PARAM_VAR
