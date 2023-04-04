INSERT INTO agg_battery_whole_hourly
SELECT
%llu AS start_ts,
%llu AS end_ts,
sum(time_delta) AS total_du,
power_mode,
screen_mode,
thermal_mode,
sum(battery_passed_chgq_reset_count_delta) AS battery_passed_chgq_reset_count,
sum(battery_level_delta) AS battery_level_delta,
sum(input_usb_eg) AS input_usb_eg,
sum(whole_eg) AS whole_eg,
sum(rm_delta) AS rm_eg,
sum(fcc_jump) AS total_fcc_jump,
sum(passchq_jump) AS total_passchq_jump,
charge_tech,
fast_chg_type
FROM comp_batteryAgent_appPower_intv
where start_ts >= %llu and end_ts <= %llu
    and power_mode != -1
    and screen_mode != -1
    and thermal_mode != -1
GROUP BY power_mode,screen_mode,thermal_mode,charge_tech,fast_chg_type