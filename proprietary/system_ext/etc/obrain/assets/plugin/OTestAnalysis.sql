
select T1.scene, T1.number, sum(T2.total_eg) / 1000000.0 as mAh
	, T2.type
from (
	select start_ts, end_ts, scene, row_number() over (partition by scene) as number
	from comp_otestagent_backward
) T1
	inner join (
		select start_ts, end_ts, total_eg, 'cpu' as type
		from comp_uidstate_cpuagent_backward
		union
		select start_ts, end_ts, whole_eg, 'display' as type
		from comp_displayAgent_appPower_intv
		union
		select start_ts, end_ts, whole_eg, 'gpu' as type
		from comp_gpuPower_gpuAgent_intv
		union
		select start_ts, end_ts, whole_eg, 'battery' as type
		from comp_batteryAgent_appPower_intv
		where power_mode = 0
		union
		select start_ts, end_ts, total_eg, 'wifi' as type
		from comp_wifi_agent_intv
		union
		select start_ts, end_ts, total_eg, 'cellular' as type
		from comp_cellularUidState_backward
		union
		select start_ts, end_ts, whole_eg, 'audio' as type
		from comp_audioPower_audioAgent_intv
		union
		select start_ts, end_ts, whole_eg, 'dsp' as type
		from comp_dsp_data
	) T2
	on T1.start_ts <= T2.start_ts
		and T1.end_ts >= T2.end_ts
group by T1.scene, T1.number, T2.type
order by scene, number asc, mAh desc, type;


select *
from (
	select *, row_number() over (partition by scene, number order by mAh desc) as idx
	from (
		select T1.scene, T1.number, sum(T2.total_eg) / 1000000.0 as mAh
			, T2.app
		from (
			select start_ts, end_ts, scene, row_number() over (partition by scene ) as number
			from comp_otestagent_backward
		) T1
			inner join (
				select start_ts, end_ts, total_eg, name as app
				from comp_uidstate_cpuagent_backward
				union
				select start_ts, end_ts, whole_eg, app
				from comp_displayAgent_appPower_intv
				union
				select start_ts, end_ts, whole_eg, app
				from comp_gpuPower_gpuAgent_intv
				union
				select start_ts, end_ts, total_eg, package_name as app
				from comp_wifi_agent_intv
				union
				select start_ts, end_ts, total_eg, name as app
				from comp_cellularUidState_backward
				union
				select start_ts, end_ts, whole_eg, player_app as app
				from comp_audioPower_audioAgent_intv
				union
				select start_ts, end_ts, whole_eg, app
				from comp_dsp_data
			) T2
			on T1.start_ts <= T2.start_ts
				and T1.end_ts >= T2.end_ts
		group by T1.scene, T1.number, T2.app
	)
)
where idx <= 10