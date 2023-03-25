INSERT INTO agg_bluetooth_app_hourly
SELECT
%llu AS start_ts,
%llu AS end_ts,
sum(time_delta) AS total_du,
app,
ground_mode,
power_mode,
screen_mode,
thermal_mode,
scenario,
sum(energy) AS energy,
sum(tx_time) AS tx_time,
sum(rx_time) AS rx_time,
sum(pl_0) AS pl_0,
sum(pl_1) AS pl_1,
sum(pl_2) AS pl_2,
sum(pl_3) AS pl_3,
sum(pl_4) AS pl_4,
sum(pl_5) AS pl_5,
sum(pl_6) AS pl_6,
sum(pl_7) AS pl_7,
sum(pl_8) AS pl_8,
sum(pl_9) AS pl_9,
sum(pl_10) AS pl_10,
sum(pl_11) AS pl_11
FROM comp_bluetoothAgent_appPower_intv
where start_ts >= %llu AND end_ts <= %llu
    and ground_mode != -1
    and power_mode != -1
    and screen_mode != -1
    and thermal_mode != -1
GROUP BY power_mode,screen_mode,thermal_mode,ground_mode,scenario,app
ORDER BY energy