with
PARAM_VAR as (
    select
        {} as var_start_ts,
        {} as var_end_ts
)
insert into agg_camera_app_hourly
select
start_ts,
end_ts,
sum(duration) as total_du,
power_mode,
screen_mode,
thermal_mode,
ground_mode,
camera_app,
camera_number,
(cast(fps as int) + 5) / 10 * 10 as fps,
camera_id,
resolution,
sum(camera_eg) as camera_eg,
sum(laser_eg) as laser_eg,
sum(osi_eg) as osi_eg,
sum(motor_eg) as motor_eg
from comp_cameraAgent_appPower_intv, PARAM_VAR
where start_ts >= PARAM_VAR.var_start_ts and end_ts < PARAM_VAR.var_end_ts
    and ground_mode != -1
    and power_mode != -1
    and screen_mode != -1
    and thermal_mode != -1
    and camera_app != 'camera_null'
    and camera_id != 'null'
    and resolution != 'null'
group by power_mode, ground_mode, thermal_mode, screen_mode, camera_app, camera_number, camera_id, resolution, (cast(fps as int) + 5) / 10 * 10