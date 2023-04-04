INSERT INTO agg_camera_whole_daily
SELECT
%lld AS start_ts,
%lld AS end_ts,
app,
power_mode,
screen_mode,
thermal_mode,
ground_mode,
camera_app,
camera_number,
fps,
camera_id,
resolution,
sum(whole_eg) AS total_energy
FROM agg_camera_app_hourly
WHERE end_ts >= %lld AND end_ts <= %lld
GROUP BY app,power_mode,screen_mode,thermal_mode,ground_mode,camera_app,camera_number,fps,camera_id,resolution
ORDER BY total_energy
DESC
LIMIT 10
