with
PARAM_VAR as (
    select
        {} as var_start_ts,
        {} as var_end_ts
)
insert into agg_thermalAgent_hourly
select PARAM_VAR.var_start_ts as start_ts, PARAM_VAR.var_end_ts as end_ts, fg_app, screen_mode, power_mode, thermal_mode, network_type, zone_name
    , max(max_temp) as max_temp
    , sum(up_trend) as up_trend
    , sum(down_trend) as down_trend
    , sum(keep_trend) as keep_trend
    , round(avg(max_rate), 2) as max_rate
    , VectorI('sum(zone$0) AS zone$0', ThermalList)
from comp_thermalAgent_backward, PARAM_VAR
where start_ts >= PARAM_VAR.var_start_ts and end_ts <= PARAM_VAR.var_end_ts
    and power_mode != -1
    and screen_mode != -1
    and thermal_mode != -1
group by fg_app, screen_mode, power_mode, thermal_mode, network_type, zone_name