with
PARAM_VAR as (
    select
        {} as var_start_ts,
        {} as var_end_ts
)
insert into agg_flashlight_app_hourly
select
start_ts,
end_ts,
sum(Torch_dur) as Torch_dur,
power_mode,
screen_mode,
thermal_mode,
ground_mode,
TorchName,
sum(Torch_eg) as Torch_eg
from comp_flashlight_appPower_intv, PARAM_VAR
where start_ts >= PARAM_VAR.var_start_ts and end_ts < PARAM_VAR.var_end_ts
    and ground_mode != -1
    and power_mode != -1
    and screen_mode != -1
    and thermal_mode != -1
group by power_mode, ground_mode, thermal_mode, screen_mode, TorchName