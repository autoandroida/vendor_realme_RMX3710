with
PARAM_VAR as (
    select
        {} as var_start_ts,
        {} as var_end_ts
)

insert into agg_cellularUidState_hourly
select PARAM_VAR.var_start_ts as start_ts, PARAM_VAR.var_end_ts as end_ts, power_mode, thermal_mode, screen_mode
    , sum(incall_du) as incall_du, uid, name, ground_mode, sum(rx_trans_byte) as rx_trans_byte
	, sum(tx_trans_byte) as tx_trans_byte, networkType, duplexMode
	, dataActivity, signalLevel, simState, operatorName, bands
	, sum(sleep_time) AS sleep_time, sum(rx_time) AS rx_time, sum(rx_5g_time) AS rx_5g_time
	, sum(transceiver_eg) AS transceiver_eg, sum(pa_eg) AS pa_eg, sum(modem_eg) AS modem_eg
	, sum(total_eg) as total_eg,
	VectorI('sum(lvl$0_duration) as lvl$0_duration', CellularTxLevelDurationList),
    VectorI('sum(lvl$0_5g_duration) as lvl$0_5g_duration', CellularTx5gLevelDurationList)
from comp_cellularUidState_backward, PARAM_VAR
where start_ts >= PARAM_VAR.var_start_ts
	and end_ts <= PARAM_VAR.var_end_ts
	and power_mode != -1
	and thermal_mode != -1
	and screen_mode != -1
	and ground_mode != -1
group by ground_mode, uid, name, thermal_mode, screen_mode, power_mode
         , networkType, duplexMode, dataActivity, signalLevel, simState, operatorName, bands