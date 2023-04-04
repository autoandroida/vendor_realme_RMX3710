select 'cpu' as type, sum(total_eg)/1000000.0 as mAh from comp_uidstate_cpuagent_backward where pid=-1
union
select 'gpu' as type, sum(whole_eg)/1000000.0 as mAh from comp_gpuPower_gpuAgent_intv
union
select 'display' as type, sum(whole_eg)/1000000.0 as mAh from comp_displayAgent_appPower_intv
union
select 'ddr' as type, sum(app_eg)/1000000.0 as mAh from comp_ddrAgent_whole_energy
union
select 'wifi' as type, sum(total_eg)/1000000.0 as mAh from comp_wifi_agent_intv
union
select 'cellular' as type, sum(total_eg)/1000000.0 as mAh from comp_cellularagent_backward
union
select 'gnss' as type, sum(energy)/1000000.0 as mAh from comp_gpsPower_gpsAgent_intv
union
select 'audio' as type, sum(whole_eg)/1000000.0 as mAh from comp_audioPower_audioAgent_intv
union
select 'battery' as type, sum(whole_eg)/1000000.0 as mAh from comp_batteryAgent_appPower_intv
where power_mode = 0
order by mAh desc;