with
PARAM_VAR as (
    select
        {} as var_start_ts,
        {} as var_end_ts
)

INSERT INTO agg_gpu_whole_hourly
SELECT
    PARAM_VAR.var_start_ts AS start_ts,
    PARAM_VAR.var_end_ts AS end_ts,
    ground_mode,
    screen_mode,
    power_mode,
    thermal_mode,
    sum(time_delta) AS total_du,
    sum(whole_eg) AS whole_eg,
    sum(gpu_slumber_time_du) AS gpu_slumber_time_du,
    VectorI('sum(g$0_du) AS g$0_du', GpuDuList),
    VectorI('sum(g$0_eg) AS g$0_eg', GpuEgList)
FROM comp_gpuPower_gpuAgent_intv, PARAM_VAR
WHERE start_ts >= PARAM_VAR.var_start_ts AND end_ts <= PARAM_VAR.var_end_ts
    and ground_mode != -1
    and screen_mode != -1
    and power_mode != -1
    and thermal_mode != -1
GROUP BY ground_mode,screen_mode,power_mode,thermal_mode