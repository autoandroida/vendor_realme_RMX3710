insert into agg_bluetoothAgent_daily
select 0 as upload, '%s' as date, %llu as start_ts, %llu as end_ts,
	MODE_TBL.by_mode,
	APP_TBL.by_app,
	SCENARIO_TBL.by_scenario,
	EG_TBL.energy,
	%d as version
from
    (
        select '[' || group_concat(by_mode, ',') || ']' as by_mode
        from (
            select '{"idx":' || idx || ',"app":"' || obfuscate(app) || '","total_du":' || '"' || total_du || '",' || '"ground_mode":' || '"' || ground_mode || '",' ||
			'"screen_mode":' || '"' || screen_mode || '",' || '"thermal_mode":' || '"' || thermal_mode || '",' || '"total_eg":' || '"' || total_eg || '",' ||
			'"tx_time":' || tx_time || ',' || '"rx_time":' || rx_time || ',' ||
			'"pl_time":' || '"[' || pl_0 || ',' || pl_1 || ',' || pl_2 || ',' || pl_3 || ',' || pl_4 || ',' || pl_5 || ',' ||
									pl_6 || ',' || pl_7 || ',' || pl_8 || ',' || pl_7 || ',' || pl_10 || ',' || pl_11 || ']"' ||
			'}' as by_mode
            from (
                     select app, sum(total_du) as total_du, ground_mode, power_mode
                        , screen_mode, thermal_mode, scenario, sum(energy) as total_eg,
						sum(tx_time) as tx_time, sum(rx_time) as rx_time,
						sum(pl_0) as pl_0, sum(pl_1) as pl_1, sum(pl_2) as pl_2, sum(pl_3) as pl_3,
						sum(pl_4) as pl_4, sum(pl_5) as pl_5, sum(pl_6) as pl_6, sum(pl_7) as pl_7,
						sum(pl_8) as pl_8, sum(pl_9) as pl_9, sum(pl_10) as pl_10, sum(pl_11) as pl_11,
						row_number() over (partition by ground_mode, power_mode, screen_mode, thermal_mode order by sum(energy) desc) as idx
                    from agg_bluetooth_app_hourly
                    where start_ts >= %llu
                        and end_ts <= %llu
                    group by app, power_mode, screen_mode, thermal_mode, ground_mode
                )
                where idx <= 10
            )
    ) MODE_TBL
	,(
		select '[' || group_concat(top_app) || ']' as by_app
		from (
			-- concat to oneline for each mode
			select '{' || '"app":' || '"' || obfuscate(app) || '"' || ',"total_du ":' || '"' || total_du || '"' || ',"total_eg":' || total_eg || ',"ground_mode":' || ground_mode || ',' ||
			       '"screen_mode":' || screen_mode || ',"thermal_mode":' || thermal_mode || ',"power_mode":' || power_mode || ',"scenario":' || '"' || scenario || '"' || ',"idx":' || idx ||
					'"tx_time":' || tx_time || ',' || '"rx_time":' || rx_time || ',' ||
					'"pl_time":' || '"[' || pl_0 || ',' || pl_1 || ',' || pl_2 || ',' || pl_3 || ',' || pl_4 || ',' || pl_5 || ',' ||
											pl_6 || ',' || pl_7 || ',' || pl_8 || ',' || pl_7 || ',' || pl_10 || ',' || pl_11 || ']"' ||
				   '}' as top_app
			from (
				select app, ground_mode, power_mode, screen_mode, thermal_mode,
					sum(total_du) as total_du, sum(energy) as total_eg, idx, scenario,
					sum(tx_time) as tx_time, sum(rx_time) as rx_time,
					sum(pl_0) as pl_0, sum(pl_1) as pl_1, sum(pl_2) as pl_2, sum(pl_3) as pl_3,
					sum(pl_4) as pl_4, sum(pl_5) as pl_5, sum(pl_6) as pl_6, sum(pl_7) as pl_7,
					sum(pl_8) as pl_8, sum(pl_9) as pl_9, sum(pl_10) as pl_10, sum(pl_11) as pl_11
				from (
					-- only interested in these apps
					select *
					from agg_bluetooth_app_hourly T1
						inner join (
							-- select top 10 apps consumes most energy
							select app, sum(energy) as total_eg, row_number() over (order by sum(energy) desc) as idx
							from agg_bluetooth_app_hourly
							where start_ts >= %llu
								and end_ts <= %llu
							group by app
							limit 10
						) T2
						on T1.app = T2.app
					where start_ts >= %llu
						and end_ts <= %llu
				)
				group by app, power_mode, screen_mode, thermal_mode, ground_mode, scenario
			)
			group by app, power_mode, screen_mode, thermal_mode, ground_mode, scenario
		)
	) APP_TBL
     ,(
        select '[' || group_concat(by_scenario, ',') || ']' as by_scenario
        from (
            select '{"idx":' || idx || ',"app":"' || obfuscate(app) || '","total_du":' || '"' || total_du || '",' || '"scenario":' || '"' || scenario || '",' || '"total_eg":' || total_eg ||
			'"tx_time":' || tx_time || ',' || '"rx_time":' || rx_time || ',' ||
			'"pl_time":' || '"[' || pl_0 || ',' || pl_1 || ',' || pl_2 || ',' || pl_3 || ',' || pl_4 || ',' || pl_5 || ',' ||
									pl_6 || ',' || pl_7 || ',' || pl_8 || ',' || pl_7 || ',' || pl_10 || ',' || pl_11 || ']"' ||
			'}' as by_scenario
            from (
                select *
                from (
                    select app, sum(total_du) as total_du, scenario, sum(energy) as total_eg,
					sum(tx_time) as tx_time, sum(rx_time) as rx_time,
					sum(pl_0) as pl_0, sum(pl_1) as pl_1, sum(pl_2) as pl_2, sum(pl_3) as pl_3,
					sum(pl_4) as pl_4, sum(pl_5) as pl_5, sum(pl_6) as pl_6, sum(pl_7) as pl_7,
					sum(pl_8) as pl_8, sum(pl_9) as pl_9, sum(pl_10) as pl_10, sum(pl_11) as pl_11,
					row_number() over (partition by scenario order by sum(energy) desc) as idx
                    from agg_bluetooth_app_hourly
                    where start_ts >= %llu
                        and end_ts <= %llu
                    group by app, scenario
                )
                where idx <= 10
            )
        )
    )SCENARIO_TBL,
	(
		select '[' || group_concat(energy, ',') || ']' as energy
		from (
			select '{"total_du":' || total_du || ',"total_eg":' || total_eg || ',"ground_mode":' || ground_mode || ',' ||
			'"screen_mode":' || screen_mode || ',"thermal_mode":' || thermal_mode || ',"power_mode":' || power_mode || ',"scenario":' || '"' || scenario || '",' ||
			'"tx_time":' || tx_time || ',' || '"rx_time":' || rx_time || ',' ||
			'"pl_time":' || '"[' || pl_0 || ',' || pl_1 || ',' || pl_2 || ',' || pl_3 || ',' || pl_4 || ',' || pl_5 || ',' ||
									pl_6 || ',' || pl_7 || ',' || pl_8 || ',' || pl_7 || ',' || pl_10 || ',' || pl_11 || ']"' ||
		    '}' as energy
			from (
				select sum(total_du) as total_du, ground_mode, power_mode, screen_mode,
					thermal_mode, scenario, sum(energy) as total_eg,
					sum(tx_time) as tx_time, sum(rx_time) as rx_time,
					sum(pl_0) as pl_0, sum(pl_1) as pl_1, sum(pl_2) as pl_2, sum(pl_3) as pl_3,
					sum(pl_4) as pl_4, sum(pl_5) as pl_5, sum(pl_6) as pl_6, sum(pl_7) as pl_7,
					sum(pl_8) as pl_8, sum(pl_9) as pl_9, sum(pl_10) as pl_10, sum(pl_11) as pl_11
				from agg_bluetooth_app_hourly
				where start_ts >= %llu
					and end_ts <= %llu
				group by power_mode, screen_mode, thermal_mode, ground_mode, scenario
			)
		)
	) EG_TBL;