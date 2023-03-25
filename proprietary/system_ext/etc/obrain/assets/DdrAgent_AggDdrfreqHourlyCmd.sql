with
PARAM_VAR as (
    select
        {} as var_start_ts,
        {} as var_end_ts
)
insert into agg_ddr_app_hourly
select PARAM_VAR.var_start_ts as start_ts, PARAM_VAR.var_end_ts as end_ts, app, power_mode, screen_mode
	, thermal_mode, ground_mode, EG_TBL.key as freq, sum(DU_TBL.value) as duration
	, sum(EG_TBL.value) as energy
from (comp_ddrAgent_whole_energy, json_each(comp_ddrAgent_whole_energy.app_eg) EG_TBL)
	join json_each(comp_ddrAgent_whole_energy.freq_du) DU_TBL on EG_TBL.key = DU_TBL.key,PARAM_VAR
where power_mode != -1
	and screen_mode != -1
	and thermal_mode != -1
	and ground_mode != -1
	and start_ts >= PARAM_VAR.var_start_ts
	and end_ts < PARAM_VAR.var_end_ts
group by app, power_mode, screen_mode, thermal_mode, ground_mode, EG_TBL.key