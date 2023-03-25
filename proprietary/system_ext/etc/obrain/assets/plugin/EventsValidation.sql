-- -------- 事件准确度 --------------
-- -(1）screen_mode事件
select distinct *
from (
	select wtime as time, datetime(wtime/1000, 'unixepoch', 'localtime') as wall_time_human, state, comp_cpufreq_cpuagent_backward.screen_mode as cpu_screen_mode, comp_gpuPower_gpuAgent_intv.screen_mode as gpu_screen_mode, comp_uidstate_cpuagent_backward.screen_mode as uidstate_screen_mode
		, comp_batteryAgent_appPower_intv.screen_mode as battery_screen_mode, comp_batteryAgent_mode_intv.screen_mode as battery_mode_screen_mode, comp_wifi_agent_intv.screen_mode as wifi_screen_mode, comp_cellularagent_backward.screen_mode as cellular_screen_mode, comp_audioPower_audioAgent_intv.screen_mode as audio_screen_mode
	from trig_displayOnOff_screenState_eventAgent
		left join comp_cpufreq_cpuagent_backward
		on trig_displayOnOff_screenState_eventAgent.wtime >= comp_cpufreq_cpuagent_backward.start_ts
			and trig_displayOnOff_screenState_eventAgent.wtime < comp_cpufreq_cpuagent_backward.end_ts
		left join comp_gpuPower_gpuAgent_intv
		on trig_displayOnOff_screenState_eventAgent.wtime >= comp_gpuPower_gpuAgent_intv.start_ts
			and trig_displayOnOff_screenState_eventAgent.wtime < comp_gpuPower_gpuAgent_intv.end_ts
		left join comp_uidstate_cpuagent_backward
		on trig_displayOnOff_screenState_eventAgent.wtime >= comp_uidstate_cpuagent_backward.start_ts
			and trig_displayOnOff_screenState_eventAgent.wtime < comp_uidstate_cpuagent_backward.end_ts
		left join comp_batteryAgent_appPower_intv
		on trig_displayOnOff_screenState_eventAgent.wtime >= comp_batteryAgent_appPower_intv.start_ts
			and trig_displayOnOff_screenState_eventAgent.wtime < comp_batteryAgent_appPower_intv.end_ts
		left join comp_batteryAgent_mode_intv
		on trig_displayOnOff_screenState_eventAgent.wtime >= comp_batteryAgent_mode_intv.start_ts
			and trig_displayOnOff_screenState_eventAgent.wtime < comp_batteryAgent_mode_intv.end_ts
		left join comp_wifi_agent_intv
		on trig_displayOnOff_screenState_eventAgent.wtime >= comp_wifi_agent_intv.start_ts
			and trig_displayOnOff_screenState_eventAgent.wtime < comp_wifi_agent_intv.end_ts
		left join comp_cellularagent_backward
		on trig_displayOnOff_screenState_eventAgent.wtime >= comp_cellularagent_backward.start_ts
			and trig_displayOnOff_screenState_eventAgent.wtime < comp_cellularagent_backward.end_ts
		left join comp_audioPower_audioAgent_intv
		on trig_displayOnOff_screenState_eventAgent.wtime >= comp_audioPower_audioAgent_intv.start_ts
			and trig_displayOnOff_screenState_eventAgent.wtime < comp_audioPower_audioAgent_intv.end_ts
);

-- -- （2）app ground_mode 事件
select distinct *
from (
	select wtime as time, datetime(wtime/1000, 'unixepoch', 'localtime') AS wall_time_human, info, comp_gpuPower_gpuAgent_intv.app as gpu_app_name, comp_batteryAgent_appPower_intv.app as battery_app_name, comp_batteryAgent_appPower_intv.app as battery_mode_app_name
		, comp_wifi_agent_intv.app as wifi_app_name, comp_cellularagent_backward.fg_app as cellular_app_name, comp_audioPower_audioAgent_intv.app as audio_app_name
	from trig_appName_fgBgChanged_eventAgent
		left join comp_gpuPower_gpuAgent_intv
		on trig_appName_fgBgChanged_eventAgent.wtime >= comp_gpuPower_gpuAgent_intv.start_ts
			and trig_appName_fgBgChanged_eventAgent.wtime < comp_gpuPower_gpuAgent_intv.end_ts
		left join comp_batteryAgent_appPower_intv
		on trig_appName_fgBgChanged_eventAgent.wtime >= comp_batteryAgent_appPower_intv.start_ts
			and trig_appName_fgBgChanged_eventAgent.wtime < comp_batteryAgent_appPower_intv.end_ts
		left join comp_wifi_agent_intv
		on trig_appName_fgBgChanged_eventAgent.wtime >= comp_wifi_agent_intv.start_ts
			and trig_appName_fgBgChanged_eventAgent.wtime < comp_wifi_agent_intv.end_ts
		left join comp_cellularagent_backward
		on trig_appName_fgBgChanged_eventAgent.wtime >= comp_cellularagent_backward.start_ts
			and trig_appName_fgBgChanged_eventAgent.wtime < comp_cellularagent_backward.end_ts
		left join comp_audioPower_audioAgent_intv
		on trig_appName_fgBgChanged_eventAgent.wtime >= comp_audioPower_audioAgent_intv.start_ts
			and trig_appName_fgBgChanged_eventAgent.wtime < comp_audioPower_audioAgent_intv.end_ts
);

-- (3) power_mode
select distinct *
from (
	select wtime as time, datetime(wtime/1000, 'unixepoch', 'localtime') AS wall_time_human, state, comp_cpufreq_cpuagent_backward.power_mode as cpu_power_mode, comp_gpuPower_gpuAgent_intv.power_mode as gpu_power_mode, comp_uidstate_cpuagent_backward.power_mode as uidstate_power_mode
		, comp_batteryAgent_appPower_intv.power_mode as battery_power_mode, comp_batteryAgent_mode_intv.power_mode as battery_mode_power_mode, comp_wifi_agent_intv.power_mode as wifi_power_mode, comp_cellularagent_backward.power_mode as cellular_power_mode, comp_audioPower_audioAgent_intv.power_mode as audio_power_mode
	from trig_charging_chargerState_eventAgent
		left join comp_cpufreq_cpuagent_backward
		on trig_charging_chargerState_eventAgent.wtime >= comp_cpufreq_cpuagent_backward.start_ts
			and trig_charging_chargerState_eventAgent.wtime < comp_cpufreq_cpuagent_backward.end_ts
		left join comp_gpuPower_gpuAgent_intv
		on trig_charging_chargerState_eventAgent.wtime >= comp_gpuPower_gpuAgent_intv.start_ts
			and trig_charging_chargerState_eventAgent.wtime < comp_gpuPower_gpuAgent_intv.end_ts
		left join comp_uidstate_cpuagent_backward
		on trig_charging_chargerState_eventAgent.wtime >= comp_uidstate_cpuagent_backward.start_ts
			and trig_charging_chargerState_eventAgent.wtime < comp_uidstate_cpuagent_backward.end_ts
		left join comp_batteryAgent_appPower_intv
		on trig_charging_chargerState_eventAgent.wtime >= comp_batteryAgent_appPower_intv.start_ts
			and trig_charging_chargerState_eventAgent.wtime < comp_batteryAgent_appPower_intv.end_ts
		left join comp_batteryAgent_mode_intv
		on trig_charging_chargerState_eventAgent.wtime >= comp_batteryAgent_mode_intv.start_ts
			and trig_charging_chargerState_eventAgent.wtime < comp_batteryAgent_mode_intv.end_ts
		left join comp_wifi_agent_intv
		on trig_charging_chargerState_eventAgent.wtime >= comp_wifi_agent_intv.start_ts
			and trig_charging_chargerState_eventAgent.wtime < comp_wifi_agent_intv.end_ts
		left join comp_cellularagent_backward
		on trig_charging_chargerState_eventAgent.wtime >= comp_cellularagent_backward.start_ts
			and trig_charging_chargerState_eventAgent.wtime < comp_cellularagent_backward.end_ts
		left join comp_audioPower_audioAgent_intv
		on trig_charging_chargerState_eventAgent.wtime >= comp_audioPower_audioAgent_intv.start_ts
			and trig_charging_chargerState_eventAgent.wtime < comp_audioPower_audioAgent_intv.end_ts
);


select distinct *
from (
	select wtime as time, datetime(wtime/1000, 'unixepoch', 'localtime') AS wall_time_human, state, comp_cpufreq_cpuagent_backward.thermal_mode as cpu_thermal_mode, comp_gpuPower_gpuAgent_intv.thermal_mode as gpu_thermal_mode, comp_uidstate_cpuagent_backward.thermal_mode as uidstate_thermal_mode
		, comp_batteryAgent_appPower_intv.thermal_mode as battery_thermal_mode, comp_batteryAgent_mode_intv.thermal_mode as battery_mode_thermal_mode, comp_wifi_agent_intv.thermal_mode as wifi_thermal_mode, comp_cellularagent_backward.thermal_mode as cellular_thermal_mode, comp_audioPower_audioAgent_intv.thermal_mode as audio_thermal_mode
	from trig_state_thermal_eventAgent
		left join comp_cpufreq_cpuagent_backward
		on trig_state_thermal_eventAgent.wtime >= comp_cpufreq_cpuagent_backward.start_ts
			and trig_state_thermal_eventAgent.wtime < comp_cpufreq_cpuagent_backward.end_ts
		left join comp_gpuPower_gpuAgent_intv
		on trig_state_thermal_eventAgent.wtime >= comp_gpuPower_gpuAgent_intv.start_ts
			and trig_state_thermal_eventAgent.wtime < comp_gpuPower_gpuAgent_intv.end_ts
		left join comp_uidstate_cpuagent_backward
		on trig_state_thermal_eventAgent.wtime >= comp_uidstate_cpuagent_backward.start_ts
			and trig_state_thermal_eventAgent.wtime < comp_uidstate_cpuagent_backward.end_ts
		left join comp_batteryAgent_appPower_intv
		on trig_state_thermal_eventAgent.wtime >= comp_batteryAgent_appPower_intv.start_ts
			and trig_state_thermal_eventAgent.wtime < comp_batteryAgent_appPower_intv.end_ts
		left join comp_batteryAgent_mode_intv
		on trig_state_thermal_eventAgent.wtime >= comp_batteryAgent_mode_intv.start_ts
			and trig_state_thermal_eventAgent.wtime < comp_batteryAgent_mode_intv.end_ts
		left join comp_wifi_agent_intv
		on trig_state_thermal_eventAgent.wtime >= comp_wifi_agent_intv.start_ts
			and trig_state_thermal_eventAgent.wtime < comp_wifi_agent_intv.end_ts
		left join comp_cellularagent_backward
		on trig_state_thermal_eventAgent.wtime >= comp_cellularagent_backward.start_ts
			and trig_state_thermal_eventAgent.wtime < comp_cellularagent_backward.end_ts
		left join comp_audioPower_audioAgent_intv
		on trig_state_thermal_eventAgent.wtime >= comp_audioPower_audioAgent_intv.start_ts
			and trig_state_thermal_eventAgent.wtime < comp_audioPower_audioAgent_intv.end_ts
);
