insert into  agg_camera_whole_hourly
select %llu as start_ts, %llu as end_ts,  power_mode
    , screen_mode, thermal_mode, ground_mode, camera_app, camera_number
	, (cast(fps as int) + 5) / 10 * 10 as fps
	, resolution, sum(camera_eg) as camera_eg, sum(laser_eg) as laser_eg
	,sum(osi_eg) as osi_eg, sum(motor_eg) as motor_eg
from comp_cameraAgent_appPower_intv
where end_ts >= %llu and end_ts < %llu
    and ground_mode != -1
    and power_mode != -1
    and screen_mode != -1
    and thermal_mode != -1
group by power_mode, ground_mode, thermal_mode, screen_mode, camera_app, camera_number, camera_id, resolution, (cast(fps as int) + 5) / 10 * 10;
