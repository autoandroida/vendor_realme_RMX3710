with
PARAM_VAR as (
    select
        {} as var_start_ts,
        {} as var_end_ts
)

insert into agg_gpu_app_hourly
select
    PARAM_VAR.var_start_ts AS start_ts
    , PARAM_VAR.var_end_ts AS end_ts
    , app
    , ground_mode
    , screen_mode
    , power_mode
    , thermal_mode
	, sum(time_delta) as total_du
	, sum(whole_eg) as whole_eg
	, sum(gpu_slumber_time_du) as gpu_slumber_time_du
    , VectorI('sum(g$0_du) AS g$0_du', GpuDuList)
    , VectorI('sum(g$0_eg) AS g$0_eg', GpuEgList)
from comp_gpuPower_gpuAgent_intv, PARAM_VAR
where start_ts >= PARAM_VAR.var_start_ts
    and end_ts <= PARAM_VAR.var_end_ts
	and ground_mode != -1
	and screen_mode != -1
	and power_mode != -1
	and thermal_mode != -1
group by app, ground_mode, screen_mode, power_mode, thermal_mode