--- Total energy
select  'power:' || power_mode || ',screen:' || screen_mode || ',thermal:' || thermal_mode as name
	, sum(total_eg) / 1000000.0 as mAh, case when sum(total_eg) / 1000000.0 < 100.0 and sum(total_eg) / 1000000.0 >= 0 then 'pass' else 'fail' end as result
from (
	select json_extract(one_mode, '$.total_eg') as total_eg
		, json_extract(one_mode, '$.power_mode') as power_mode
		, json_extract(one_mode, '$.screen_mode') as screen_mode
		, json_extract(one_mode, '$.thermal_mode') as thermal_mode
	from (
		select value as one_mode
		from agg_gpu_app_daily, json_each(agg_gpu_app_daily.gpu_energy)
	)
)
group by 'power:' || power_mode || ',screen:' || screen_mode || ',thermal:' || thermal_mode
order by sum(total_eg) / 1000000.0 desc;

---- cross table result check
select *, (case when apptable_total_eg < egtable_total_eg and egtable_total_eg > 0 and egtable_total_eg < 2000 then 'pass' else 'fail' end) as result
from
(
	select sum(json_extract(T1.one_mode, '$.total_eg'))/1000000.0 as egtable_total_eg, sum(json_extract(T2.one_mode, '$.total_eg'))/1000000.0 as apptable_total_eg
	from (
		select value as one_mode
		from agg_gpu_app_daily, json_each(agg_gpu_app_daily.gpu_energy)
	) T1,
	(
		select value as one_mode
		from agg_gpu_app_daily, json_each(agg_gpu_app_daily.fg_top_app_by_mode)
	) T2
);


--- GPU per app check
select name  as APP
	, sum(total_eg) / 1000000.0 as mAh, case when sum(total_eg) / 1000000.0 < 100.0 and sum(total_eg) / 1000000.0 >= 0 then 'pass' else 'fail' end as result
from (
	select json_extract(one_mode, '$.total_eg') as total_eg
		, json_extract(one_mode, '$.app') as name
		, json_extract(one_mode, '$.power_mode') as power_mode
		, json_extract(one_mode, '$.screen_mode') as screen_mode
		, json_extract(one_mode, '$.thermal_mode') as thermal_mode
	from (
		select value as one_mode
		from agg_gpu_app_daily, json_each(agg_gpu_app_daily.fg_top_app_by_mode)
	)
)
group by name
order by sum(total_eg) / 1000000.0 desc;

--- GPU per app power mode check
select name || '_power_mode' || power_mode as APP
	, sum(total_eg) / 1000000.0 as mAh, case when sum(total_eg) / 1000000.0 < 100.0 and sum(total_eg) / 1000000.0 >= 0 then 'pass' else 'fail' end as result
from (
	select json_extract(one_mode, '$.total_eg') as total_eg
		, json_extract(one_mode, '$.app') as name
		, json_extract(one_mode, '$.power_mode') as power_mode
		, json_extract(one_mode, '$.screen_mode') as screen_mode
		, json_extract(one_mode, '$.thermal_mode') as thermal_mode
	from (
		select value as one_mode
		from agg_gpu_app_daily, json_each(agg_gpu_app_daily.fg_top_app_by_mode)
	)
)
group by name || '_power_mode' || power_mode
order by sum(total_eg) / 1000000.0 desc;


--- GPU per app screen mode check
select name || '_screen_mode' || screen_mode as APP
	, sum(total_eg) / 1000000.0 as mAh, case when sum(total_eg) / 1000000.0 < 100.0 and sum(total_eg) / 1000000.0 >= 0 then 'pass' else 'fail' end as result
from (
	select json_extract(one_mode, '$.total_eg') as total_eg
		, json_extract(one_mode, '$.app') as name
		, json_extract(one_mode, '$.power_mode') as power_mode
		, json_extract(one_mode, '$.screen_mode') as screen_mode
		, json_extract(one_mode, '$.thermal_mode') as thermal_mode
	from (
		select value as one_mode
		from agg_gpu_app_daily, json_each(agg_gpu_app_daily.fg_top_app_by_mode)
	)
)
group by name || '_screen_mode' || screen_mode
order by sum(total_eg) / 1000000.0 desc;


--- thermal mode

select name || '_thermal_mode' || thermal_mode as APP
	, sum(total_eg) / 1000000.0 as mAh, case when sum(total_eg) / 1000000.0 < 100.0 and sum(total_eg) / 1000000.0 >= 0 then 'pass' else 'fail' end as result
from (
	select json_extract(one_mode, '$.total_eg') as total_eg
		, json_extract(one_mode, '$.app') as name
		, json_extract(one_mode, '$.power_mode') as power_mode
		, json_extract(one_mode, '$.screen_mode') as screen_mode
		, json_extract(one_mode, '$.thermal_mode') as thermal_mode
	from (
		select value as one_mode
		from agg_gpu_app_daily, json_each(agg_gpu_app_daily.fg_top_app_by_mode)
	)
)
group by name || '_thermal_mode' || thermal_mode
order by sum(total_eg) / 1000000.0 desc;

