-- - Total energy
select 'power:' || power_mode || ',screen:' || screen_mode || ',thermal:' || thermal_mode as name
	, sum(total_eg) / 1000000.0 as mAh
	, case
		when sum(total_eg) / 1000000.0 < 100.0
			and sum(total_eg) / 1000000.0 >= 0
		then 'pass'
		else 'fail'
	end as result
from (
	select power_mode, screen_mode, thermal_mode, value as total_eg
	from (
		select json_extract(one_mode, '$.total_eg') as total_eg
			, json_extract(one_mode, '$.power_mode') as power_mode
			, json_extract(one_mode, '$.screen_mode') as screen_mode
			, json_extract(one_mode, '$.thermal_mode') as thermal_mode
		from (
			select value as one_mode
			from agg_displayAgent_daily, json_each(agg_displayAgent_daily.energy)
		)
	) T1, json_each(T1.total_eg)
)
group by 'power:' || power_mode || ',screen:' || screen_mode || ',thermal:' || thermal_mode
order by sum(total_eg) / 1000000.0 desc;

---- cross table result check
select *
	, case
		when modetable_total_eg <= egtable_total_eg
			and modetable_total_eg > 0
			and egtable_total_eg < 2000
		then 'pass'
		else 'fail'
	end as result
from (
	select sum(value) / 1000000.0 as egtable_total_eg
	from (
		select json_extract(one_mode, '$.total_eg') as total_eg
		from (
			select value as one_mode
			from agg_displayAgent_daily, json_each(agg_displayAgent_daily.energy)
		)
	) T1, json_each(T1.total_eg)
) T2, (
		select sum(value) / 1000000.0 as modetable_total_eg
		from (
			select json_extract(one_mode, '$.total_eg') as total_eg
			from (
				select value as one_mode
				from agg_displayAgent_daily, json_each(agg_displayAgent_daily.by_mode)
			)
		) T3, json_each(T3.total_eg)
	) T4;


--- Display per app ground mode check
select name || '_ground_mode' || ground_mode as APP
	, sum(total_eg) / 1000000.0 as mAh, case when sum(total_eg) / 1000000.0 < 100.0 and sum(total_eg) / 1000000.0 >= 0 then 'pass' else 'fail' end as result
from (
	select power_mode, screen_mode, thermal_mode, ground_mode, value as total_eg, name
	from (
		select json_extract(one_mode, '$.total_eg') as total_eg
			, json_extract(one_mode, '$.power_mode') as power_mode
			, json_extract(one_mode, '$.screen_mode') as screen_mode
			, json_extract(one_mode, '$.thermal_mode') as thermal_mode
			, json_extract(one_mode, '$.ground_mode') as ground_mode
			, json_extract(one_mode, '$.app') as name
		from (
			select value as one_mode
			from agg_displayAgent_daily, json_each(agg_displayAgent_daily.by_mode)
		)
	) T1, json_each(T1.total_eg)
)
group by name
order by sum(total_eg) / 1000000.0 desc;

--- Display per app power mode check
select name || '_power_mode' || power_mode as APP
	, sum(total_eg) / 1000000.0 as mAh, case when sum(total_eg) / 1000000.0 < 100.0 and sum(total_eg) / 1000000.0 >= 0 then 'pass' else 'fail' end as result
from (
	select power_mode, screen_mode, thermal_mode, ground_mode, value as total_eg, name
	from (
		select json_extract(one_mode, '$.total_eg') as total_eg
			, json_extract(one_mode, '$.power_mode') as power_mode
			, json_extract(one_mode, '$.screen_mode') as screen_mode
			, json_extract(one_mode, '$.thermal_mode') as thermal_mode
			, json_extract(one_mode, '$.ground_mode') as ground_mode
			, json_extract(one_mode, '$.app') as name
		from (
			select value as one_mode
			from agg_displayAgent_daily, json_each(agg_displayAgent_daily.by_mode)
		)
	) T1, json_each(T1.total_eg)
)
group by name || '_power_mode' || power_mode
order by sum(total_eg) / 1000000.0 desc;


--- Display per app screen mode check
select name || '_screen_mode' || screen_mode as APP
	, sum(total_eg) / 1000000.0 as mAh, case when sum(total_eg) / 1000000.0 < 100.0 and sum(total_eg) / 1000000.0 >= 0 then 'pass' else 'fail' end as result
from (
	select power_mode, screen_mode, thermal_mode, ground_mode, value as total_eg, name
	from (
		select json_extract(one_mode, '$.total_eg') as total_eg
			, json_extract(one_mode, '$.power_mode') as power_mode
			, json_extract(one_mode, '$.screen_mode') as screen_mode
			, json_extract(one_mode, '$.thermal_mode') as thermal_mode
			, json_extract(one_mode, '$.ground_mode') as ground_mode
			, json_extract(one_mode, '$.app') as name
		from (
			select value as one_mode
			from agg_displayAgent_daily, json_each(agg_displayAgent_daily.by_mode)
		)
	) T1, json_each(T1.total_eg)
)
group by name || '_screen_mode' || screen_mode
order by sum(total_eg) / 1000000.0 desc;


--- thermal mode

select name || '_thermal_mode' || thermal_mode as APP
	, sum(total_eg) / 1000000.0 as mAh, case when sum(total_eg) / 1000000.0 < 100.0 and sum(total_eg) / 1000000.0 >= 0 then 'pass' else 'fail' end as result
from (
	select power_mode, screen_mode, thermal_mode, ground_mode, value as total_eg, name
	from (
		select json_extract(one_mode, '$.total_eg') as total_eg
			, json_extract(one_mode, '$.power_mode') as power_mode
			, json_extract(one_mode, '$.screen_mode') as screen_mode
			, json_extract(one_mode, '$.thermal_mode') as thermal_mode
			, json_extract(one_mode, '$.ground_mode') as ground_mode
			, json_extract(one_mode, '$.app') as name
		from (
			select value as one_mode
			from agg_displayAgent_daily, json_each(agg_displayAgent_daily.by_mode)
		)
	) T1, json_each(T1.total_eg)
)
group by name || '_thermal_mode' || thermal_mode
order by sum(total_eg) / 1000000.0 desc;

-- brightness check
select value as brightness, case when value < 1024 and value >= 0 then 'pass' else 'fail' end as result
from (
    select json_extract(one_mode, '$.brightness') as brightness

    from (
        select value as one_mode
        from agg_displayAgent_daily, json_each(agg_displayAgent_daily.energy)
    )
) T1, json_each(T1.brightness)