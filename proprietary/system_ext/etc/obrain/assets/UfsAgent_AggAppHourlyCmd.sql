with
PARAM_VAR as (
    select
        {} as var_start_ts,
        {} as var_end_ts
)

INSERT INTO agg_ufs_app_hourly
SELECT
    PARAM_VAR.var_start_ts AS start_ts
    , PARAM_VAR.var_end_ts AS end_ts
    , app
    , sum(end_ts - start_ts) AS duration
    , ground_mode
    , screen_mode
    , charge_mode
    , thermal_mode
    , sum(vcc_power) AS vcc_power
    , sum(vccq_power) AS vccq_power
    , sum(total_power) AS total_power
FROM comp_table_whole_ufs_energy, PARAM_VAR
WHERE start_ts >= PARAM_VAR.var_start_ts AND end_ts <= PARAM_VAR.var_end_ts
    and ground_mode != -1
    and charge_mode != -1
    and screen_mode != -1
    and thermal_mode != -1
GROUP BY app, ground_mode, screen_mode, charge_mode, thermal_mode
