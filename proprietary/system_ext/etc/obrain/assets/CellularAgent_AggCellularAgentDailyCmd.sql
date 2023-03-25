with
PARAM_VAR as (
    select
        {} as var_date,
        {} as var_start_ts,
        {} as var_end_ts,
        {} as var_version
),
CELL_EG as (
    select json_group_array(cell_energy) as cell_energy
    from (
        select json_object('ground_mode', ground_mode, 'screen_mode', screen_mode, 'thermal_mode', thermal_mode
        , 'power_mode', power_mode, 'networkType', networkType, 'duplexMode', duplexMode
        , 'simState', simState, 'bands', bands, 'incall_du', sum(incall_du)
        , 'rx_trans_byte', sum(rx_trans_byte), 'tx_trans_byte', sum(tx_trans_byte)
        , '4g_du', json_array(VectorI('round(sum(lvl$0_duration), 2)', CellularTxLevelDurationList))
        , '5g_du', json_array(VectorI('round(sum(lvl$0_5g_duration), 2)', CellularTx5gLevelDurationList))
        , 'tx_4g_time', round(SumVectorI('sum(lvl$0_duration)', CellularTxLevelDurationList), 2)
        , 'tx_5g_time', round(SumVectorI('sum(lvl$0_5g_duration)', CellularTx5gLevelDurationList), 2)
        , 'sleep_time', round(sum(sleep_time), 2), 'rx_time', round(sum(rx_time), 2)
        , 'rx_5g_time', round(sum(rx_5g_time), 2), 'transceiver_eg', sum(transceiver_eg)
        , 'pa_eg', sum(pa_eg), 'modem_eg',  sum(modem_eg), 'total_eg', sum(total_eg)) as cell_energy
        from agg_cellularUidState_hourly, PARAM_VAR
        where start_ts >= PARAM_VAR.var_start_ts
            and end_ts <= PARAM_VAR.var_end_ts
        group by ground_mode, power_mode, screen_mode, thermal_mode, networkType, duplexMode, simState, bands
    )
),
TOP_APP_BY_MODE as (
    select json_group_array(top_app_by_mode) as top_app_by_mode
    from (
        select json_object('app', T1.uid, 'name', obfuscate(T1.name), 'idx', T1.idx
        , 'ground_mode', ground_mode, 'screen_mode', screen_mode, 'thermal_mode', thermal_mode
        , 'power_mode', power_mode, 'networkType', networkType, 'duplexMode', duplexMode
        , 'simState', simState, 'bands', bands, 'rx_trans_byte', sum(rx_trans_byte), 'tx_trans_byte', sum(tx_trans_byte)
        , '4g_du', json_array(VectorI('round(sum(lvl$0_duration), 2)', CellularTxLevelDurationList))
        , '5g_du', json_array(VectorI('round(sum(lvl$0_5g_duration), 2)', CellularTx5gLevelDurationList))
        , 'tx_4g_time', round(SumVectorI('sum(lvl$0_duration)', CellularTxLevelDurationList), 2)
        , 'tx_5g_time', round(SumVectorI('sum(lvl$0_5g_duration)', CellularTx5gLevelDurationList), 2)
        , 'sleep_time', round(sum(sleep_time), 2), 'rx_time', round(sum(rx_time), 2)
        , 'rx_5g_time', round(sum(rx_5g_time), 2), 'transceiver_eg', sum(transceiver_eg)
        , 'pa_eg', sum(pa_eg), 'modem_eg',  sum(modem_eg), 'total_eg', sum(total_eg)) as top_app_by_mode
        from (
            select *
            from agg_cellularUidState_hourly T1, PARAM_VAR
                inner join (
                    select *
                    from (
                        select uid, ground_mode, thermal_mode, power_mode, screen_mode, networkType, sum(total_eg),
                            row_number() over (partition by ground_mode, thermal_mode, power_mode, screen_mode, networkType order by sum(total_eg) desc) as idx
                        from agg_cellularUidState_hourly, PARAM_VAR
                        where start_ts >= PARAM_VAR.var_start_ts
                            and end_ts <= PARAM_VAR.var_end_ts
                        group by uid, power_mode, screen_mode, thermal_mode, ground_mode, networkType
                    )
                    where idx <= 10
                ) T2
                on T1.uid = T2.uid
                    and T1.ground_mode = T2.ground_mode
                    and T1.thermal_mode = T2.thermal_mode
                    and T1.power_mode = T2.power_mode
                    and T1.screen_mode = T2.screen_mode
                    and T1.networkType = T2.networkType
            where start_ts >= PARAM_VAR.var_start_ts
                and end_ts <= PARAM_VAR.var_end_ts
        ) T1
        group by uid, ground_mode, thermal_mode, power_mode, screen_mode, networkType, duplexMode, simState, bands
    )
),
MODEM_STATS as (
    -- single json object
    select by_rrc_stats as modem_stats
    from (
        select json_object('lte_rrc_c0', sum(lte_rrc_c0), 'lte_rrc_c1', sum(lte_rrc_c1), 'lte_rrc_t0', sum(lte_rrc_t0)
        , 'lte_rrc_t1', sum(lte_rrc_t1), 'nr_rrc_c0', sum(nr_rrc_c0), 'nr_rrc_c1', sum(nr_rrc_c1)
        , 'nr_rrc_t0', sum(nr_rrc_t0), 'nr_rrc_t1', sum(nr_rrc_t1)) as by_rrc_stats
        from comp_cellularagent_modem_info, PARAM_VAR
        where
            start_ts >= PARAM_VAR.var_start_ts
            and end_ts <= PARAM_VAR.var_end_ts
    )
),
SIGNAL_STATS as (
    select json_group_array(by_signal_level) as signal_du_stats
    from (
        select json_object('signalLevel', signalLevel, 'total_du', sum(total_du)) as by_signal_level
        from agg_cellularagent_hourly, PARAM_VAR
        where
            start_ts >= PARAM_VAR.var_start_ts
            and end_ts <= PARAM_VAR.var_end_ts
        group by signalLevel
    )
)

-----------------------------------
insert into agg_cellularagent_daily
select PARAM_VAR.var_date as DATE, PARAM_VAR.var_start_ts as start_ts, PARAM_VAR.var_end_ts as end_ts, '0' as upload
    , CELL_EG.cell_energy as cell_energy
	, TOP_APP_BY_MODE.top_app_by_mode as top_app_by_mode
	, MODEM_STATS.modem_stats as modem_stats
	, SIGNAL_STATS.signal_du_stats as signal_du_stats
	, PARAM_VAR.var_version as version
from  PARAM_VAR, CELL_EG, TOP_APP_BY_MODE, MODEM_STATS, SIGNAL_STATS
