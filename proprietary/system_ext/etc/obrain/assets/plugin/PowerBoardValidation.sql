/* 0. delete original power_board table
drop table if exists power_board ;

*/


-- 1. first step: delete invalid data
delete from power_board where S18_DVDD_CORE_VPH_PWR_P is null or S19_DVDD_SRAM_CORE_VPH_PWR_P is null
or S23_DVDD_PROC_B_VPH_PWR_P is null 
or S24_DVDD_PROC_L_VPH_PWR_P is null
or S25_DVDD_SRAM_PROC_B_P is null
or S26_DVDD_SRAM_PROC_L_P is null;

-- 2. timestamp align

-- Power board's valid timestamp
select start_ts, start_ts + duration as end_ts, 	datetime(start_ts / 1000, 'unixepoch', 'localtime') as start_ts, datetime((start_ts + duration) / 1000, 'unixepoch', 'localtime') as start_ts
from (
select min(cast((cast(TimeOffset as decimal)+1601794428) * 1000 as int)) as start_ts, max(cast(TimeOffset as decimal))*1000 as duration
from power_board
);

-- MIDAS’s valid timestamp
select  start_ts, end_ts, datetime(start_ts / 1000, 'unixepoch', 'localtime') as start_ts
	, datetime(end_ts /1000 , 'unixepoch', 'localtime') as end_ts
	from comp_cpufreq_cpuagent_backward;
	
-- intersect timestamp
select T1.start_ts, T1.end_ts, datetime(T1.start_ts / 1000, 'unixepoch', 'localtime') as start_ts, datetime(T1.end_ts / 1000, 'unixepoch', 'localtime') as end_ts
from comp_cpufreq_cpuagent_backward T1,
(
select start_ts, start_ts + duration as end_ts
from (
	-- XXXXXX: replace it with actual value
	select min(cast((cast(TimeOffset as decimal)+1601794428) * 1000 as int)) as start_ts, max(cast(TimeOffset as decimal))*1000 as duration
	from power_board
)
) T2
where (T1.start_ts between T2.start_ts and T2.end_ts) and (T1.end_ts between T2.start_ts and T2.end_ts);


-- 3. check power board energy from intersect regsion
select 'power_board' as type
	, datetime(min(start_ts) / 1000, 'unixepoch', 'localtime') as start_ts
	, datetime(max(end_ts) /1000 , 'unixepoch', 'localtime') as end_ts
	, sum(S18_DVDD_CORE_VPH_PWR_P + S19_DVDD_SRAM_CORE_VPH_PWR_P + S23_DVDD_PROC_B_VPH_PWR_P + S24_DVDD_PROC_L_VPH_PWR_P 
		+ S25_DVDD_SRAM_PROC_B_P + S26_DVDD_SRAM_PROC_L_P) as total_eg
	, sum(duration) as duration
	, sum(S18_DVDD_CORE_VPH_PWR_P)
	, sum(S19_DVDD_SRAM_CORE_VPH_PWR_P)
	, sum(S23_DVDD_PROC_B_VPH_PWR_P)
	, sum(S24_DVDD_PROC_L_VPH_PWR_P)
	, sum(S25_DVDD_SRAM_PROC_B_P)
	, sum(S26_DVDD_SRAM_PROC_L_P)
from (
	select start_ts, end_ts, end_ts - start_ts as duration
		, S18_DVDD_CORE_VPH_PWR_P * (end_ts - start_ts)/1000.0/4/3600 as S18_DVDD_CORE_VPH_PWR_P
		, S19_DVDD_SRAM_CORE_VPH_PWR_P * (end_ts - start_ts)/1000.0/4/3600  as S19_DVDD_SRAM_CORE_VPH_PWR_P
		, S23_DVDD_PROC_B_VPH_PWR_P * (end_ts - start_ts)/1000.0/4/3600  as S23_DVDD_PROC_B_VPH_PWR_P
		, S24_DVDD_PROC_L_VPH_PWR_P * (end_ts - start_ts)/1000.0/4/3600  as S24_DVDD_PROC_L_VPH_PWR_P
		, S25_DVDD_SRAM_PROC_B_P * (end_ts - start_ts)/1000.0/4/3600  as S25_DVDD_SRAM_PROC_B_P
		, S26_DVDD_SRAM_PROC_L_P * (end_ts - start_ts)/1000.0/4/3600  as S26_DVDD_SRAM_PROC_L_P
	from (
		select datetime(T3.start_ts / 1000, 'unixepoch', 'localtime') as x, datetime(T3.end_ts / 1000, 'unixepoch', 'localtime') as y, T3.*
		from
		(
			-- XXXXXX: replace it with actual value
			select 
			cast((cast(TimeOffset as decimal)+1601794428) * 1000 as int) as start_ts, lead(cast((cast(TimeOffset as decimal)+1601794428) * 1000 as int)) over (order by cast(TimeOffset as decimal) asc) as end_ts, *
					from power_board
		) T3,
		(
			select min(T1.start_ts) as start_ts, max(T1.end_ts) as end_ts, datetime(min(T1.start_ts)  / 1000, 'unixepoch', 'localtime') as start_ts, datetime(max(T1.end_ts) / 1000, 'unixepoch', 'localtime') as end_ts
			from comp_cpufreq_cpuagent_backward T1,
			(
				select start_ts, start_ts + duration as end_ts
				from (
					-- XXXXXX: replace it with actual value
					select min(cast((cast(TimeOffset as decimal)+1601794428) * 1000 as int)) as start_ts, max(cast(TimeOffset as decimal))*1000 as duration
					from power_board
				)
			) T2
			where (T1.start_ts between T2.start_ts and T2.end_ts) and (T1.end_ts between T2.start_ts and T2.end_ts)
		) T4
		where T3.start_ts >= T4.start_ts and T3.end_ts <= T4.end_ts
	)

);


select 'midas' as type
	, datetime(min(T3.start_ts) / 1000, 'unixepoch', 'localtime') as start_ts
	, datetime(max(T3.end_ts) / 1000, 'unixepoch', 'localtime') as end_ts
	, sum(T3.end_ts - T3.start_ts) as duration
	, sum(total_eg)/1000000.0 as total_eg
	, sum(total_eg)/1000000.0/((sum(T3.end_ts - T3.start_ts) )/1000.0/3600.0) as avg_current
from comp_cpufreq_cpuagent_backward T3,
(
	select min(T1.start_ts) as start_ts, max(T1.end_ts) as end_ts, datetime(min(T1.start_ts)  / 1000, 'unixepoch', 'localtime') as start_ts, datetime(max(T1.end_ts) / 1000, 'unixepoch', 'localtime') as end_ts
	from comp_cpufreq_cpuagent_backward T1,
	(
		select start_ts, start_ts + duration as end_ts
		from (
		-- XXXXXX: replace it with actual value
		select min(cast((cast(TimeOffset as decimal)+1601794428) * 1000 as int)) as start_ts, max(cast(TimeOffset as decimal))*1000 as duration
		from power_board
		)
	) T2
	where (T1.start_ts between T2.start_ts and T2.end_ts) and (T1.end_ts between T2.start_ts and T2.end_ts)
) T4
where T3.start_ts >= T4.start_ts and T3.end_ts <= T4.end_ts