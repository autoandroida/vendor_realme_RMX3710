insert into {}
select 0 as upload, '{}' as date, (select min(otime) from log_running_event where WTIME>={} and WTIME <={} ) as start_ts, (select max(otime) from log_running_event where WTIME>={} and WTIME <= {}) as end_ts, '{}' as sysInfo
	, json_patch((
		select '{{' || group_concat(oneline) || '}}' as obrain
		from (
			select '"avg_' || key || '":' || avg(value) || ',"max_' || key || '":' || max(value) as oneline
			from log_running_event, json_each(log_running_event.DES)
			where EVENT = 'Memory' and WTIME >= {} and WTIME < {}
			group by key
			union
			select '"boot_count":' || count(*)
			from log_running_event
			where EVENT = 'START' and WTIME >= {} and WTIME < {}
			union
			select '"dcs":[' || group_concat('"' || DES || '"') || ']'
			from log_running_event
			where EVENT = 'DCS' and WTIME >= {} and WTIME < {}
			union
            select '"log":' || json_group_array(DATE || ':' || EVENT || ':' || DES) from (
                select *
                from log_running_event
                where EVENT != 'DCS' and EVENT != 'Cpu' and EVENT != 'Memory' and WTIME >= {} and WTIME < {}
                limit 25
            )
		)
		limit 1
	), '{}') as obrainInfo, {} as version;
