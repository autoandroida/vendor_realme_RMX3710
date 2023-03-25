with
PARAM_VAR as (
    select
        {} as var_date,
        {} as var_start_ts,
        {} as var_end_ts,
        {} as var_version
),
EG_TBL as (
    select json_group_array(oneline) as energy
	from (
		select json_object('screen_mode', screen_mode, 'ground_mode', ground_mode, 'power_mode', power_mode
		, 'thermal_mode', thermal_mode, 'total_du', total_du
		, 'total_eg', total_eg, 'vcc_power', vcc_power, 'vccq_power', vccq_power) as oneline
		from (
			-- -- total duration and energy for each mode
			select screen_mode, ground_mode, charge_mode as power_mode, thermal_mode
				, sum(vcc_power) as vcc_power, sum(vccq_power) as vccq_power
				, sum(total_power) as total_eg, sum(duration) as total_du
			from agg_ufs_app_hourly, PARAM_VAR
			where start_ts >= PARAM_VAR.var_start_ts
				and end_ts <= PARAM_VAR.var_end_ts
			group by ground_mode, screen_mode, charge_mode, thermal_mode
		)
		group by screen_mode, ground_mode, power_mode, thermal_mode
	)
),
TOP_APP_BY_MODE_TBL as (
    select json_group_array(oneline) as top_app
    from (
        select json_object('app', obfuscate(app), 'screen_mode', screen_mode, 'ground_mode', ground_mode, 'power_mode', power_mode
        , 'thermal_mode', thermal_mode, 'idx', idx, 'vcc_power', vcc_power, 'vccq_power', vccq_power
        , 'total_eg', total_eg, 'total_du', total_du) as oneline
        from (
            select app, screen_mode, ground_mode, power_mode, thermal_mode
                , sum(vcc_power) as vcc_power, sum(vccq_power) as vccq_power
                , sum(energy) as total_eg, sum(duration) as total_du, idx
            from (
                select T1.app, T1.screen_mode, T1.ground_mode, T1.charge_mode as power_mode, T1.thermal_mode
                    , T1.vcc_power, T1.vccq_power, T1.total_power as energy, T1.duration, T2.idx
                from (
                    select *
                    from agg_ufs_app_hourly, PARAM_VAR
                    where start_ts >= PARAM_VAR.var_start_ts
                        and end_ts <= PARAM_VAR.var_end_ts
                ) T1
                    inner join (
                        select *
                        from (
                            -- add idx for each partition
                            select app, screen_mode, ground_mode, charge_mode, thermal_mode
                                , sum(total_power) as total_eg, row_number() over (partition by screen_mode, ground_mode, charge_mode, thermal_mode order by sum(total_power) desc) as idx
                            from agg_ufs_app_hourly, PARAM_VAR
                            where start_ts >= PARAM_VAR.var_start_ts
                                and end_ts <= PARAM_VAR.var_end_ts
                            group by app, ground_mode, screen_mode, charge_mode, thermal_mode
                        )
                        where idx <= 10
                    ) T2
                    on T1.app = T2.app
                        and T1.ground_mode = T2.ground_mode
                        and T1.screen_mode = T2.screen_mode
                        and T1.charge_mode = T2.charge_mode
                        and T1.thermal_mode = T2.thermal_mode
            )
            group by app, screen_mode, ground_mode, power_mode, thermal_mode
        )
    )
),
TOP_APP_BY_EG_TBL as (
    select json_group_array(oneline) as top_app
    from (
        select json_object('app', obfuscate(app), 'screen_mode', screen_mode, 'ground_mode', ground_mode, 'power_mode', power_mode
        , 'thermal_mode', thermal_mode, 'idx', idx, 'vcc_power', vcc_power, 'vccq_power', vccq_power
        , 'total_eg', total_eg, 'total_du', total_du) as oneline
        from (
            select app, screen_mode, ground_mode, power_mode, thermal_mode
                , sum(vcc_power) as vcc_power, sum(vccq_power) as vccq_power
                , sum(energy) as total_eg, sum(duration) as total_du, idx
            from (
                select T1.app, T1.screen_mode, T1.ground_mode, T1.charge_mode as power_mode, T1.thermal_mode
                    , T1.vcc_power, T1.vccq_power, T1.total_power as energy, T1.duration, T2.idx
                from (
                    select *
                    from agg_ufs_app_hourly, PARAM_VAR
                    where start_ts >= PARAM_VAR.var_start_ts
                        and end_ts <= PARAM_VAR.var_end_ts
                ) T1
                    inner join (
                        select *
                        from (
                            -- get top app by energy and add idx
                            select app, sum(total_power) as total_eg, row_number() over (order by sum(total_power) desc) as idx
                            from agg_ufs_app_hourly, PARAM_VAR
                            where start_ts >= PARAM_VAR.var_start_ts
                                and end_ts <= PARAM_VAR.var_end_ts
                            group by app
                        )
                        where idx <= 10
                    ) T2
                    on T1.app = T2.app
            )
            group by app, screen_mode, ground_mode, power_mode, thermal_mode
        )
    )
)

-----------------------------
insert into agg_ufs_app_daily
select 0 as upload, PARAM_VAR.var_date as date, PARAM_VAR.var_start_ts as start_ts, PARAM_VAR.var_end_ts as end_ts
    , EG_TBL.energy
	, TOP_APP_BY_MODE_TBL.top_app as top_app_by_mode
	, TOP_APP_BY_EG_TBL.top_app as top_app_by_energy
	, PARAM_VAR.var_version as version
from PARAM_VAR, EG_TBL, TOP_APP_BY_MODE_TBL, TOP_APP_BY_EG_TBL
