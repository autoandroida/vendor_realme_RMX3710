insert into {}
-- energy table
select 0 as upload, '{}' as date, {} as start_ts, {} as end_ts, CNT_TBL.count
	, TOP_APP_BY_MODE_TBL.top_app as top_app_by_mode, TOP_APP_BY_EG_TBL.top_app as top_app_by_energy, {} as version
from (
	select '[' || group_concat(oneline) || ']' as count
	from (
		select '{{"screen_mode":' || screen_mode || ',"ground_mode":' || ground_mode || ', "power_mode":' || power_mode || ',"thermal_mode":' || thermal_mode || ',"packageName":"' || packageName || '","times":' || times || '}}' as oneline
		from (
			select power_mode, screen_mode, thermal_mode, ground_mode
				, packageName, sum(times) as times
			from agg_wakeupAgent_hourly
			where start_ts >= {}
				and end_ts <= {}
				and times > 0
			group by power_mode, screen_mode, thermal_mode, ground_mode, packageName
		)
	)
) CNT_TBL, (
		select '[' || group_concat(oneline) || ']' as top_app
		from (
			select '{{"packageName":"' || obfuscate(packageName) || '","screen_mode":' || screen_mode || ',"ground_mode":' || ground_mode || ',"power_mode":' || power_mode || ',"thermal_mode":' || thermal_mode || ',"tag":"' || tag || '","idx":' || idx || ',"times":' || times || '}}' as oneline
			from (
				select packageName, tag, screen_mode, ground_mode, power_mode, thermal_mode
					, sum(times) as times, idx
				from (
					select T1.packageName, T1.tag, T1.screen_mode, T1.ground_mode, T1.power_mode, T1.thermal_mode
						, T1.times, T2.idx
					from agg_wakeupAgent_hourly T1
						inner join (
							select *
							from (
								-- add idx for each partition
								select packageName, tag, screen_mode, ground_mode, power_mode, thermal_mode
									, sum(times) as times, row_number() over (partition by screen_mode, ground_mode, power_mode, thermal_mode order by sum(times) desc) as idx
								from agg_wakeupAgent_hourly
								where start_ts >= {}
									and end_ts <= {}
								group by packageName, tag, ground_mode, screen_mode, power_mode, thermal_mode
							)
							where idx <= 10
						) T2
						on T1.packageName = T2.packageName
							and T1.ground_mode = T2.ground_mode
							and T1.screen_mode = T2.screen_mode
							and T1.power_mode = T2.power_mode
							and T1.thermal_mode = T2.thermal_mode
							and T1.tag = T2.tag
					where start_ts >= {}
						and end_ts <= {}
				)
				group by packageName, tag, screen_mode, ground_mode, power_mode, thermal_mode
			)
		)
	) TOP_APP_BY_MODE_TBL, (
		select '[' || group_concat(oneline) || ']' as top_app
		from (
			select '{{"packageName":"' || obfuscate(packageName) || '","screen_mode":' || screen_mode || ',"ground_mode":' || ground_mode || ',"power_mode":' || power_mode || ',"thermal_mode":' || thermal_mode || ',"tag":"' || tag || '","idx":' || idx || ',"times":' || times || '}}' as oneline
			from (
				select packageName, tag, screen_mode, ground_mode, power_mode, thermal_mode
					, sum(times) as times, idx
				from (
					select *
					from agg_wakeupAgent_hourly T1
						inner join (
							select *
							from (
								-- get top app by energy and add idx
								select packageName, sum(times) as times, row_number() over (order by sum(times) desc) as idx
								from agg_wakeupAgent_hourly
								where start_ts >= {}
									and end_ts <= {}
								group by packageName
							)
							where idx <= 10
						) T2
						on T1.packageName = T2.packageName
					where start_ts >= {}
						and end_ts <= {}
				)
				group by packageName, tag, screen_mode, ground_mode, power_mode, thermal_mode
			)
		)
	) TOP_APP_BY_EG_TBL