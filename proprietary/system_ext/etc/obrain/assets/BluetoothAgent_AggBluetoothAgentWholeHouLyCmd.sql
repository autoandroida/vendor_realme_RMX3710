INSERT INTO agg_bluetooth_whole_hourly
SELECT
%llu AS start_ts,
%llu AS end_ts,
sum(time_delta) AS total_du,
ground_mode,
power_mode,
screen_mode,
thermal_mode,
scenario,
sum(energy) AS energy
FROM comp_bluetoothAgent_appPower_intv
where start_ts >= %llu AND end_ts <= %llu
    and ground_mode != -1
    and power_mode != -1
    and screen_mode != -1
    and thermal_mode != -1
GROUP BY power_mode,screen_mode,thermal_mode,ground_mode,scenario
ORDER BY energy