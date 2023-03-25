INSERT INTO agg_display_whole_hourly
SELECT
{} AS start_ts,
{} AS end_ts,
sum(time_delta) AS total_du,
power_mode,
screen_mode,
thermal_mode,
ground_mode,
FPS AS FPS,
brightness / 100 * 100,
(renderFps + 5) / 10 * 10,
sum(whole_eg) AS whole_eg
FROM comp_displayAgent_appPower_intv
where start_ts >= {} AND end_ts <= {}
    and ground_mode != -1
    and power_mode != -1
    and screen_mode != -1
    and thermal_mode != -1
GROUP BY power_mode,screen_mode,thermal_mode,ground_mode
ORDER BY whole_eg