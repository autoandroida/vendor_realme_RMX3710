with
PARAM_VAR as (
    select
        {} as var_start_ts,
        {} as var_end_ts
)

INSERT INTO agg_cellularagent_hourly
SELECT
PARAM_VAR.var_start_ts AS start_ts,
PARAM_VAR.var_end_ts AS end_ts,
sum(total_du) AS total_du,
fg_app,
power_mode,
thermal_mode,
screen_mode,
sum(incall_du) AS incall_du,
sum(rx_trans_byte) AS rx_trans_byte,
sum(tx_trans_byte) AS tx_trans_byte,
sum(sleep_time) AS sleep_time,
sum(rx_time) AS rx_time,
sum(rx_5g_time) AS rx_5g_time,
networkType,
duplexMode,
dataActivity,
signalLevel,
simState,
operatorName,
bands,
sum(transceiver_eg) AS transceiver_eg,
sum(pa_eg) AS pa_eg,
sum(modem_eg) AS modem_eg,
sum(total_eg) AS total_eg,
VectorI('sum(lvl$0_duration) as lvl$0_duration', CellularTxLevelDurationList),
VectorI('sum(lvl$0_5g_duration) as lvl$0_5g_duration', CellularTx5gLevelDurationList)
FROM comp_cellularagent_backward, PARAM_VAR
where start_ts >= PARAM_VAR.var_start_ts AND end_ts <= PARAM_VAR.var_end_ts
    and power_mode != -1
    and thermal_mode != -1
    and screen_mode != -1
GROUP BY fg_app, power_mode, thermal_mode, screen_mode, networkType, duplexMode, dataActivity, signalLevel, simState, operatorName, bands
ORDER BY total_eg
DESC