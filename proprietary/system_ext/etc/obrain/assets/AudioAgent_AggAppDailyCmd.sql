with
PARAM_VAR as (
    select
        {} as var_date,
        {} as var_version,
        {} as var_start_ts,
        {} as var_end_ts
)
insert into agg_audio_app_daily
-- combine energy table and top_app table
select 0 as upload, PARAM_VAR.var_date as date, PARAM_VAR.var_start_ts as start_ts, PARAM_VAR.var_end_ts as end_ts, EG_TBL.energy
	, TOP_APP_BY_MODE_TBL.top_app as top_app_by_mode, TOP_APP_BY_EG_TBL.top_app as top_app_by_energy, PARAM_VAR.var_version as version
from (
	select '[' || group_concat(energy) || ']' as energy
	from (

				-- -- concat volume, duration and energy
				select '{{"screen_mode":' || screen_mode || ',"ground_mode":' || ground_mode || ', "power_mode":' || power_mode || ',"thermal_mode":' || thermal_mode || 
					 ',"energy":{{"channel":' || channel || ',"volume":[' || group_concat(volume) || '],' || '"duration":[' || group_concat(duration) || '],"total_eg":[' || group_concat(total_eg) || ']}}}}' as energy
				from (
					-- -- total duration and energy for each mode
					select screen_mode, ground_mode, power_mode, thermal_mode, volume
						, channel, sum(duration) as duration, sum(whole_eg) as total_eg
					from agg_audio_app_hourly,PARAM_VAR
					where start_ts >= PARAM_VAR.var_start_ts and end_ts < PARAM_VAR.var_end_ts
					group by ground_mode, screen_mode, power_mode, thermal_mode, volume, channel
				)
				group by screen_mode, ground_mode, power_mode, thermal_mode, channel

	)
) EG_TBL, (
		-- - top app
		-- concact all lines
		select '[' || group_concat(oneline) || ']' as top_app
		from (
			-- concat with app and every mode
			select '{{"player_app":"' || obfuscate(player_app) || '","screen_mode":' || screen_mode || ',"ground_mode":' || ground_mode || ',"power_mode":' || power_mode || ',"thermal_mode":' || thermal_mode || ',' || energy || '}}' as oneline
			from (
				-- concat volume, duration and total_eg
				select player_app, screen_mode, ground_mode, power_mode, thermal_mode
					, idx
					, '"energy":{{"channel":' || channel || ',"volume":[' || group_concat(volume) || '], "duration":[' || group_concat(duration) || '], "total_eg":[' || group_concat(total_eg) || ']}}' as energy
				from (
					-- group each mode for all records selected
					select player_app, screen_mode, ground_mode, power_mode, thermal_mode
						, volume, channel, sum(duration) as duration, sum(whole_eg) as total_eg
						, idx
					from (
						-- all records match condition
						select T1.player_app, T1.screen_mode, T1.ground_mode, T1.power_mode, T1.thermal_mode
							, T1.volume, duration as duration, T1.channel, T1.whole_eg, T2.idx
						from agg_audio_app_hourly T1,PARAM_VAR
							inner join (
								-- select top 10 app
								select *
								from (
									-- add idx for each partition 
									select player_app, screen_mode, ground_mode, power_mode, thermal_mode
										, sum(whole_eg) as total_eg, row_number() over (partition by screen_mode, ground_mode, power_mode, thermal_mode order by sum(whole_eg) desc) as idx
									from agg_audio_app_hourly,PARAM_VAR
									where start_ts >= PARAM_VAR.var_start_ts and end_ts < PARAM_VAR.var_end_ts
									group by player_app, ground_mode, screen_mode, power_mode, thermal_mode
								)
								where idx <= 10
							) T2
							on T1.player_app = T2.player_app
								and T1.ground_mode = T2.ground_mode
								and T1.screen_mode = T2.screen_mode
								and T1.power_mode = T2.power_mode
								and T1.thermal_mode = T2.thermal_mode
						where start_ts >= PARAM_VAR.var_start_ts and end_ts < PARAM_VAR.var_end_ts
					)
					group by player_app, screen_mode, ground_mode, power_mode, thermal_mode, volume, channel
				)
				group by player_app, screen_mode, ground_mode, power_mode, thermal_mode, channel
			)
		)
	) TOP_APP_BY_MODE_TBL, (
		select '[' || group_concat(oneline) || ']' as top_app
		from (
			select '{{"player_app":"' || obfuscate(player_app) || '","screen_mode":' || screen_mode || ',"ground_mode":' || ground_mode || ',"power_mode":' || power_mode || ',"thermal_mode":' || thermal_mode || ',' || energy || '}}' as oneline
			from (
				select player_app, ground_mode, screen_mode, power_mode, thermal_mode
					, idx
					, '"energy":{{"channel":' || channel || ',"volume":[' || group_concat(volume) || '], "duration":[' || group_concat(duration) || '], "total_eg":[' || group_concat(total_eg) || ']}}' as energy
				from (
					-- group by every mode to calculate sum energy of each permutation
					select player_app, ground_mode, screen_mode, power_mode, thermal_mode
						, idx, volume, channel, sum(duration) as duration
						, sum(whole_eg) as total_eg
					from (
						-- only select interested app from original table
						select *, duration as duration
						from agg_audio_app_hourly T1,PARAM_VAR
							inner join (
								-- get top 10 app
								select *
								from (
									-- get top app by energy and add idx
									select player_app, sum(whole_eg) as total_eg, row_number() over (order by sum(whole_eg) desc) as idx
									from agg_audio_app_hourly,PARAM_VAR
									where start_ts >= PARAM_VAR.var_start_ts and end_ts < PARAM_VAR.var_end_ts
									group by player_app
								)
								where idx <= 10
							) T2
							on T1.player_app = T2.player_app
						where start_ts >= PARAM_VAR.var_start_ts and end_ts < PARAM_VAR.var_end_ts
					)
					group by player_app, ground_mode, screen_mode, power_mode, thermal_mode, volume, channel
				)
				group by player_app, ground_mode, screen_mode, power_mode, thermal_mode, channel
			)
		)
	) TOP_APP_BY_EG_TBL,PARAM_VAR
