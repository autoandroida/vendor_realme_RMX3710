with TOP_UID as (
		select 'uid' as type, uid_name as name, null as parent, *
		from (
			-- - XXX: eliminated uid name here.
			select null as pid_name, null as tgid_name, uid_name, power_mode, screen_mode
				, thermal_mode, ground_mode
				,sum(total_eg) as total_eg
				, row_number() over (partition by power_mode, screen_mode, thermal_mode, ground_mode order by sum(total_eg) desc) as idx
			from comp_uidstate_cpuagent_backward
			where pid = -1
			group by power_mode, screen_mode, thermal_mode, ground_mode, uid_name
		)
		where idx <= 10
	),
	TOP_TGID as (
		select 'process' as type, tgid_name as name, uid_name as parent, *
		from (
			-- - select all top tgids from top uid
			select null as pid_name, T2.tgid_name, T1.uid_name, T1.power_mode, T1.screen_mode
				, T1.thermal_mode, T1.ground_mode, T2.total_eg as total_eg
				, row_number() over (partition by T1.power_mode, T1.screen_mode, T1.thermal_mode, T1.ground_mode, T1.uid_name order by T2.total_eg desc) as idx
			from TOP_UID T1
				inner join (
					-- - top tgid's energy and duration （sum all pids in task group)
					select tgid_name, uid_name, power_mode, screen_mode, thermal_mode
						, ground_mode
						, sum(total_eg) as total_eg
					from comp_uidstate_cpuagent_backward
					where pid != -1
					group by tgid_name, uid_name, power_mode, screen_mode, thermal_mode, ground_mode
				) T2
				on T1.power_mode = T2.power_mode
					and T1.screen_mode = T2.screen_mode
					and T1.thermal_mode = T2.thermal_mode
					and T1.ground_mode = T2.ground_mode
					and T1.uid_name = T2.uid_name
		)
		where idx <= 10
	)
select *
from TOP_UID
union
select *
from TOP_TGID
union
select 'thread' as type, pid_name as name, tgid_name as parent, pid_name, tgid_name
	, uid_name, power_mode, screen_mode, thermal_mode, ground_mode
	, total_eg, idx
from (
	select T4.pid_name, T3.tgid_name, T3.uid_name, T3.power_mode, T3.screen_mode
		, T3.thermal_mode, T3.ground_mode, T4.total_eg as total_eg
		, row_number() over (partition by T3.power_mode, T3.screen_mode, T3.thermal_mode, T3.ground_mode, T3.uid_name, T3.tgid_name order by T4.total_eg desc) as idx
	from TOP_TGID T3
		inner join (
			-- - top PID table
			select pid_name, tgid_name, uid_name, power_mode, screen_mode
				, thermal_mode, ground_mode
				, sum(total_eg) as total_eg
			from comp_uidstate_cpuagent_backward
			where pid != -1
			group by power_mode, screen_mode, thermal_mode, ground_mode, uid_name, tgid_name, pid_name
		) T4
		on T3.power_mode = T4.power_mode
			and T3.screen_mode = T4.screen_mode
			and T3.thermal_mode = T4.thermal_mode
			and T3.ground_mode = T4.ground_mode
			and T3.tgid_name = T4.tgid_name
			and T3.uid_name = T4.uid_name
)
where idx <= 10
order by total_eg desc