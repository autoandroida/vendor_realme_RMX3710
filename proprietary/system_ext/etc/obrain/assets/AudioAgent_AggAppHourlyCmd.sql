with
PARAM_VAR as (
    select
        {} as var_start_ts,
        {} as var_end_ts
)
INSERT INTO agg_audio_app_hourly
SELECT
PARAM_VAR.var_start_ts AS start_ts,
PARAM_VAR.var_end_ts AS end_ts,
sum(duration) AS duration,
app,
player_app,
ground_mode,
screen_mode,
power_mode,
thermal_mode,
audio_number,
volume,
channel,
sum(whole_eg) AS whole_eg
FROM comp_audioPower_audioAgent_intv,PARAM_VAR
WHERE start_ts >= PARAM_VAR.var_start_ts AND end_ts <= PARAM_VAR.var_end_ts
    and ground_mode != -1
    and screen_mode != -1
    and power_mode != -1
    and thermal_mode != -1
GROUP BY app,player_app,ground_mode,screen_mode,power_mode,thermal_mode,volume
