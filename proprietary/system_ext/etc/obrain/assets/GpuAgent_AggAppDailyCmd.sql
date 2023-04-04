with
PARAM_VAR as (
    select
        {} as var_date,
        {} as var_start_ts,
        {} as var_end_ts,
        {} as var_version
),
FG_TBL as (
    select json_group_array(fg_top_app_by_eg) as fg_top_app_by_eg
	from (
        select json_object('idx', idx, 'app', obfuscate(app), 'screen_mode', screen_mode, 'thermal_mode', thermal_mode
        , 'power_mode', power_mode, 'gpu_du', json_array(VectorI('sum(g$0_du)', GpuDuList)), 'gpu_eg', json_array(VectorI('sum(g$0_eg)', GpuEgList))
        , 'slumber_du', sum(gpu_slumber_time_du), 'usually_utilize_rate', cast(round(usually_utilize_rate) as int)
        , 'fmax_utilize_rate', cast(round(fmax_utilize_rate) as int), 'total_du', sum(total_du)
        , 'total_eg', sum(total_eg)) as fg_top_app_by_eg
		from (
			select T1.app, idx, ground_mode, screen_mode, power_mode, thermal_mode
			    , sum(gpu_slumber_time_du) as gpu_slumber_time_du
                , VectorI('sum(g$0_du) AS g$0_du', GpuDuList)
                , VectorI('sum(g$0_eg) AS g$0_eg', GpuEgList)
				, (SumVectorI('sum(g$0_du)',  GpuDuList)) * 100 / sum(total_du) as usually_utilize_rate
				, ((SumVector2II('$0 * sum(g$1_du)', GpuFreqList, GpuDuList)) * 100.0 / (VectorI('$0', maxFreqlist) * sum(total_du)))  as fmax_utilize_rate
				, sum(total_du) as total_du
				, sum(whole_eg) as total_eg
			from (
				select *
				from agg_gpu_app_hourly, PARAM_VAR
				where start_ts >= PARAM_VAR.var_start_ts
					and end_ts <= PARAM_VAR.var_end_ts
			) T1
				inner join (
					select app, sum(whole_eg), row_number() over (order by sum(whole_eg) desc) as idx
					from agg_gpu_app_hourly, PARAM_VAR
					where ground_mode = 1
						and start_ts >= PARAM_VAR.var_start_ts
						and end_ts <= PARAM_VAR.var_end_ts
					group by app
					limit 10
				) T2
				on T1.app = T2.app
			group by T1.app, power_mode, screen_mode, thermal_mode
		)
		group by app, power_mode, screen_mode, thermal_mode
	)
),
GPU_EG_TBL as (
    select json_group_array(gpu_energy) as gpu_energy
    from (
        select json_object('screen_mode', screen_mode, 'ground_mode', ground_mode, 'thermal_mode', thermal_mode
        , 'power_mode', power_mode, 'gpu_du', json_array(VectorI('sum(g$0_du)', GpuDuList)), 'gpu_eg', json_array(VectorI('sum(g$0_eg)', GpuEgList))
        , 'slumber_du', sum(gpu_slumber_time_du), 'total_eg', sum(whole_eg)) as gpu_energy
        from agg_gpu_whole_hourly, PARAM_VAR
        where start_ts >= PARAM_VAR.var_start_ts
            and end_ts <= PARAM_VAR.var_end_ts
        group by screen_mode, thermal_mode, power_mode, ground_mode
    )
),
FG_MODE_TBL as (
    select json_group_array(fg_top_app_by_mode) as fg_top_app_by_mode
    from (
         select json_object('idx', idx, 'app', obfuscate(app), 'screen_mode', screen_mode, 'thermal_mode', thermal_mode
        , 'power_mode', power_mode, 'gpu_du', json_array(VectorI('sum(g$0_du)', GpuDuList)), 'gpu_eg', json_array(VectorI('sum(g$0_eg)', GpuEgList))
        , 'slumber_du', sum(gpu_slumber_time_du), 'usually_utilize_rate', cast(round(usually_utilize_rate) as int)
        , 'fmax_utilize_rate', cast(round(fmax_utilize_rate) as int), 'total_du', sum(total_du)
        , 'total_eg', sum(total_eg)) as fg_top_app_by_mode
        from (
            select app, ground_mode, power_mode, thermal_mode, screen_mode, gpu_slumber_time_du
                , VectorI('g$0_du', GpuDuList)
                , VectorI('g$0_eg', GpuEgList)
                , total_du, total_eg, idx, total_du, usually_utilize_rate, fmax_utilize_rate
            from (
                select app, ground_mode, power_mode, thermal_mode, screen_mode, gpu_slumber_time_du
                    , VectorI('g$0_du', GpuDuList)
                    , VectorI('g$0_eg', GpuEgList)
                    , usually_utilize_rate, fmax_utilize_rate
                    , total_du, total_eg, row_number() over (partition by ground_mode, power_mode, thermal_mode, screen_mode order by total_eg desc) as idx
                from (
                    select app, ground_mode, power_mode, thermal_mode, screen_mode
                        , sum(gpu_slumber_time_du) as gpu_slumber_time_du
                        , VectorI('sum(g$0_du) AS g$0_du', GpuDuList)
                        , VectorI('sum(g$0_eg) AS g$0_eg', GpuEgList)
                        , (SumVectorI('sum(g$0_du)',  GpuDuList)) * 100 / sum(total_du) as usually_utilize_rate
                        , ((SumVector2II('$0 * sum(g$1_du)', GpuFreqList, GpuDuList)) * 100.0 / (VectorI('$0', maxFreqlist) * sum(total_du)))  as fmax_utilize_rate
                        , sum(total_du) as total_du
                        , sum(whole_eg) as total_eg
                    from agg_gpu_app_hourly, PARAM_VAR
                    where start_ts >= PARAM_VAR.var_start_ts
                        and end_ts <= PARAM_VAR.var_end_ts
                    group by app, ground_mode, power_mode, thermal_mode, screen_mode
                )
            )
            where idx <= 10
        )
        group by app, power_mode, screen_mode, thermal_mode, ground_mode
    )
)

insert into agg_gpu_app_daily
select 0 as upload, PARAM_VAR.var_date as DATE, PARAM_VAR.var_start_ts as start_ts, PARAM_VAR.var_end_ts as end_ts
    , FG_TBL.fg_top_app_by_eg as fg_top_app_by_eg
	, FG_MODE_TBL.fg_top_app_by_mode
	, GPU_EG_TBL.gpu_energy
	, PARAM_VAR.var_version as version
from PARAM_VAR, FG_TBL, GPU_EG_TBL, FG_MODE_TBL