
--- CPU per app ground mode check
select name || '_ground_mode:' || ground_mode as APP
	, sum(total_eg) / 1000000.0 as mAh, sum(c0_eg)/1000000.0 as c0_mAh,sum(c1_eg)/1000000.0 as c1_mAh,sum(c2_eg)/1000000.0 as c2_mAh
	, case when sum(total_eg) / 1000000.0 < 1000 and sum(c0_eg)/1000000.0 < 1000 and sum(c1_eg)/1000000.0 < 1000 and ifnull(sum(c2_eg)/1000000.0, 0) < 1000 then 'pass' else 'fail' end as result
from (
	select json_extract(one_mode, '$.c0_eg') as c0_eg
		, json_extract(one_mode, '$.c1_eg') as c1_eg
		, json_extract(one_mode, '$.c2_eg') as c2_eg
		, json_extract(one_mode, '$.total_eg') as total_eg
		, json_extract(one_mode, '$.name') as name
		, json_extract(one_mode, '$.power_mode') as power_mode
		, json_extract(one_mode, '$.screen_mode') as screen_mode
		, json_extract(one_mode, '$.thermal_mode') as thermal_mode
		, json_extract(one_mode, '$.ground_mode') as ground_mode
	from (
		select json_patch(value, '{"ground_mode":"1"}') as one_mode
		from agg_cpuagent_daily, json_each(agg_cpuagent_daily.fg_top_app)
		union
		select json_patch(value, '{"ground_mode":"0"}') as one_mode
		from agg_cpuagent_daily, json_each(agg_cpuagent_daily.bg_top_app)
	)
)
group by name || '_ground_mode:' || ground_mode
order by sum(total_eg) / 1000000.0 desc;

--- CPU per app power mode check
select name || '_power_mode:' || power_mode as APP
	, sum(total_eg) / 1000000.0 as mAh, sum(c0_eg)/1000000.0 as c0_mAh,sum(c1_eg)/1000000.0 as c1_mAh,sum(c2_eg)/1000000.0 as c2_mAh
	, case when sum(total_eg) / 1000000.0 < 1000 and sum(c0_eg)/1000000.0 < 1000 and sum(c1_eg)/1000000.0 < 1000 and ifnull(sum(c2_eg)/1000000.0, 0) < 1000 then 'pass' else 'fail' end as result
from (
	select json_extract(one_mode, '$.c0_eg') as c0_eg
		, json_extract(one_mode, '$.c1_eg') as c1_eg
		, json_extract(one_mode, '$.c2_eg') as c2_eg
		, json_extract(one_mode, '$.total_eg') as total_eg
		, json_extract(one_mode, '$.name') as name
		, json_extract(one_mode, '$.power_mode') as power_mode
		, json_extract(one_mode, '$.screen_mode') as screen_mode
		, json_extract(one_mode, '$.thermal_mode') as thermal_mode
		, json_extract(one_mode, '$.ground_mode') as ground_mode
	from (
		select json_patch(value, '{"ground_mode":"1"}') as one_mode
		from agg_cpuagent_daily, json_each(agg_cpuagent_daily.fg_top_app)
		union
		select json_patch(value, '{"ground_mode":"0"}') as one_mode
		from agg_cpuagent_daily, json_each(agg_cpuagent_daily.bg_top_app)
	)
)
group by name || '_power_mode:' || ground_mode
order by sum(total_eg) / 1000000.0 desc;


--- CPU per app screen mode check
select name || '_screen_mode:' || screen_mode as APP
	, sum(total_eg) / 1000000.0 as mAh, sum(c0_eg)/1000000.0 as c0_mAh,sum(c1_eg)/1000000.0 as c1_mAh,sum(c2_eg)/1000000.0 as c2_mAh
	, case when sum(total_eg) / 1000000.0 < 1000 and sum(c0_eg)/1000000.0 < 1000 and sum(c1_eg)/1000000.0 < 1000 and ifnull(sum(c2_eg)/1000000.0, 0) < 1000 then 'pass' else 'fail' end as result
from (
	select json_extract(one_mode, '$.c0_eg') as c0_eg
		, json_extract(one_mode, '$.c1_eg') as c1_eg
		, json_extract(one_mode, '$.c2_eg') as c2_eg
		, json_extract(one_mode, '$.total_eg') as total_eg
		, json_extract(one_mode, '$.name') as name
		, json_extract(one_mode, '$.power_mode') as power_mode
		, json_extract(one_mode, '$.screen_mode') as screen_mode
		, json_extract(one_mode, '$.thermal_mode') as thermal_mode
		, json_extract(one_mode, '$.ground_mode') as ground_mode
	from (
		select json_patch(value, '{"ground_mode":"1"}') as one_mode
		from agg_cpuagent_daily, json_each(agg_cpuagent_daily.fg_top_app)
		union
		select json_patch(value, '{"ground_mode":"0"}') as one_mode
		from agg_cpuagent_daily, json_each(agg_cpuagent_daily.bg_top_app)
	)
)
group by name || '_screen_mode:' || screen_mode
order by sum(total_eg) / 1000000.0 desc;


--- thermal mode

select name || '_thermal_mode:' || thermal_mode as APP
	, sum(total_eg) / 1000000.0 as mAh, sum(c0_eg)/1000000.0 as c0_mAh,sum(c1_eg)/1000000.0 as c1_mAh,sum(c2_eg)/1000000.0 as c2_mAh
	, case when sum(total_eg) / 1000000.0 < 1000 and sum(c0_eg)/1000000.0 < 1000 and sum(c1_eg)/1000000.0 < 1000 and ifnull(sum(c2_eg)/1000000.0, 0) < 1000 then 'pass' else 'fail' end as result
from (
	select json_extract(one_mode, '$.c0_eg') as c0_eg
		, json_extract(one_mode, '$.c1_eg') as c1_eg
		, json_extract(one_mode, '$.c2_eg') as c2_eg
		, json_extract(one_mode, '$.total_eg') as total_eg
		, json_extract(one_mode, '$.name') as name
		, json_extract(one_mode, '$.power_mode') as power_mode
		, json_extract(one_mode, '$.screen_mode') as screen_mode
		, json_extract(one_mode, '$.thermal_mode') as thermal_mode
		, json_extract(one_mode, '$.ground_mode') as ground_mode
	from (
		select json_patch(value, '{"ground_mode":"1"}') as one_mode
		from agg_cpuagent_daily, json_each(agg_cpuagent_daily.fg_top_app)
		union
		select json_patch(value, '{"ground_mode":"0"}') as one_mode
		from agg_cpuagent_daily, json_each(agg_cpuagent_daily.bg_top_app)
	)
)
group by name || '_screen_mode:' || thermal_mode
order by sum(total_eg) / 1000000.0 desc;

-- #################### COMP TABLE VALIDATION ###########################
--- Change threshold to value you want
with threshold as (select 50), cluster_eg_tbl as (
		select c0_0_du + c0_1_du + c0_2_du + c0_3_du + c0_4_du + c0_5_du + c0_6_du + c0_7_du + c0_8_du + c0_9_du + c0_10_du + c0_11_du + c0_12_du + c0_13_du + c0_14_du + c0_15_du as cluster0_du
			, c0_0_eg + c0_1_eg + c0_2_eg + c0_3_eg + c0_4_eg + c0_5_eg + c0_6_eg + c0_7_eg + c0_8_eg + c0_9_eg + c0_10_eg + c0_11_eg + c0_12_eg + c0_13_eg + c0_14_eg + c0_15_eg as cluster0_eg
			, c1_0_du + c1_1_du + c1_2_du + c1_3_du + c1_4_du + c1_5_du + c1_6_du + c1_7_du + c1_8_du + c1_9_du + c1_10_du + c1_11_du + c1_12_du + c1_13_du + c1_14_du + c1_15_du as cluster1_du
			, c1_0_eg + c1_1_eg + c1_2_eg + c1_3_eg + c1_4_eg + c1_5_eg + c1_6_eg + c1_7_eg + c1_8_eg + c1_9_eg + c1_10_eg + c1_11_eg + c1_12_eg + c1_13_eg + c1_14_eg + c1_15_eg as cluster1_eg
			, total_eg, name, start_ts, end_ts
		from comp_uidstate_cpuagent_backward
	)
select group_concat(details) as details
	, case
		when count(*) > 1 then 'fail'
		else 'success'
	end as cluster_energy_vs_total_energy_validation_case
from (
	select result || ':' || count(*) as details
	from (
		select 'start_ts:' || start_ts || ', end_ts:' || end_ts || ', name:' || name || ',diff_pct:' || abs((total_eg - cluster0_eg - cluster1_eg) * 100.0 / total_eg) || ',total_diff:' || (total_eg - cluster0_eg - cluster1_eg) as details
			, case
				when abs((total_eg - cluster0_eg - cluster1_eg) * 100.0 / total_eg) < 1 then 'pass'
				else
					case
						when abs(total_eg - cluster0_eg - cluster1_eg) > (select * from threshold) then 'fail'
						else 'pass'
					end
			end as result
		from cluster_eg_tbl
	)
	group by result
)

union

select 'start_ts:' || start_ts || ', end_ts:' || end_ts || ', name:' || name || ',diff_pct:' || abs((total_eg - cluster0_eg - cluster1_eg) * 100.0 / total_eg) || ',total_diff:' || (total_eg - cluster0_eg - cluster1_eg) as details
	, case
		when abs((total_eg - cluster0_eg - cluster1_eg) * 100.0 / total_eg) < 1 then 'pass'
		else
			case
				when abs(total_eg - cluster0_eg - cluster1_eg) > (select * from threshold) then 'fail'
				else 'pass'
			end
	end as result
from cluster_eg_tbl
where result = 'fail';

-- -- 0/1000 拆分验证
with orig_tbl as (
		select start_ts, end_ts, uid, total_eg, c0_0_du + c0_1_du + c0_2_du + c0_3_du + c0_4_du + c0_5_du + c0_6_du + c0_7_du + c0_8_du + c0_9_du + c0_10_du + c0_11_du + c0_12_du + c0_13_du + c0_14_du + c0_15_du as cluster0_du,
			c1_0_du + c1_1_du + c1_2_du + c1_3_du + c1_4_du + c1_5_du + c1_6_du + c1_7_du + c1_8_du + c1_9_du + c1_10_du + c1_11_du + c1_12_du + c1_13_du + c1_14_du + c1_15_du as cluster1_du
			, case
				when pid = -1 then 'uid'
				else 'pid'
			end as type
		from comp_uidstate_cpuagent_backward
		where uid in (0, 1000)
	)
select 'uid:' || uid || ',energy_diff:' || (json_extract('{' || group_concat(oneline) || '}', '$.uid.energy') - json_extract('{' || group_concat(oneline) || '}', '$.pid.energy')) || ',cluster0_diff:' || (json_extract('{' || group_concat(oneline) || '}', '$.uid.cluster0_du') - json_extract('{' || group_concat(oneline) || '}', '$.pid.cluster0_du'))
				|| ',cluster1_diff:' || (json_extract('{' || group_concat(oneline) || '}', '$.uid.cluster1_du') - json_extract('{' || group_concat(oneline) || '}', '$.pid.cluster1_du')) as detail
	, case
		when abs(json_extract('{' || group_concat(oneline) || '}', '$.uid.energy') - json_extract('{' || group_concat(oneline) || '}', '$.pid.energy'))*100.0/ json_extract('{' || group_concat(oneline) || '}', '$.uid.energy') > 1 then 'fail'
		else 'success'
	end as uid_0_1000_splitting_validation_case
from (
	select uid, '"' || type || '":{"energy":' || energy  || ',"cluster0_du":' || cluster0_du || ',"cluster1_du":' || cluster1_du || '}'as oneline
	from (
		select uid, type, sum(total_eg) as energy, sum(cluster0_du) as cluster0_du, sum(cluster1_du) as cluster1_du
		from orig_tbl
		group by uid, type
	)
)
group by uid;

-- check if duration match timestamp
with cluster_eg_tbl as (
		select c0_0_du + c0_1_du + c0_2_du + c0_3_du + c0_4_du + c0_5_du + c0_6_du + c0_7_du + c0_8_du + c0_9_du + c0_10_du + c0_11_du + c0_12_du + c0_13_du + c0_14_du + c0_15_du as cluster0_du
			, c1_0_du + c1_1_du + c1_2_du + c1_3_du + c1_4_du + c1_5_du + c1_6_du + c1_7_du + c1_8_du + c1_9_du + c1_10_du + c1_11_du + c1_12_du + c1_13_du + c1_14_du + c1_15_du as cluster1_du
			, total_eg, name, start_ts, end_ts, pid
		from comp_uidstate_cpuagent_backward
	)
select group_concat(details) as details
	, case
		when count(*) > 1 then 'fail'
		else 'success'
	end as cluster_duration_vs_timestamp_validation_case
from (
	select result || ':' || count(*) as details
	from (
		select 'start_ts:' || start_ts || ', end_ts:' || end_ts || ', name:' || name || ',cluster0_load_pct' || (cluster0_du * 100.0 / (end_ts - start_ts)) || ',cluster1_load_pct:' || (cluster1_du * 100.0 / (end_ts - start_ts)) as details
			, case
				when (cluster0_du * 100.0 / (end_ts - start_ts) > 400
					or cluster1_du * 100.0 / (end_ts - start_ts) > 400) and (abs(cluster1_du + cluster0_du - end_ts + start_ts) > 320)
				then 'fail'
				else 'success'
			end as result
		from cluster_eg_tbl
		where pid != -1
	)
	group by result
)
union
select 'start_ts:' || start_ts || ', end_ts:' || end_ts || ', name:' || name || ',cluster0_load_pct:' || (cluster0_du * 100.0 / (end_ts - start_ts)) || ',cluster1_load_pct:' || (cluster1_du * 100.0 / (end_ts - start_ts)) || ',time_diff:' || (end_ts - start_ts) || ',cluster0_du:' || cluster0_du || ',cluster1_du:' || cluster1_du || ',diff:' || (cluster1_du + cluster0_du - end_ts + start_ts) as details
	, case
		when (cluster0_du * 100.0 / (end_ts - start_ts) > 400
					or cluster1_du * 100.0 / (end_ts - start_ts) > 400) and (abs(cluster1_du + cluster0_du - end_ts + start_ts) > 320)
		then 'fail'
		else 'success'
	end as result
from cluster_eg_tbl
where pid != -1
	and result = 'fail';

-- Total energy vs total uid validation
select 'cpufreq_tbl_cluster0_du:' ||  cpufreq_eg_tbl.cluster0_du || ',uid_eg_tbl_cluster0_du:' || uid_eg_tbl.cluster0_du || ',cpufreq_tbl_cluster1_du:' ||  cpufreq_eg_tbl.cluster1_du || ',uid_eg_tbl_cluster1_du:' || uid_eg_tbl.cluster1_du
	|| ',cpufreq_tbl_total_eg:' ||  cpufreq_eg_tbl.total_eg || ',uid_eg_tbl_cluster0_du:' || uid_eg_tbl.total_eg
	|| ', cluster0_du_diff_pct:' || (abs(cpufreq_eg_tbl.cluster0_du - uid_eg_tbl.cluster0_du) * 100.0/cpufreq_eg_tbl.cluster0_du)
	|| ', cluster1_du_diff_pct:' || (abs(cpufreq_eg_tbl.cluster1_du - uid_eg_tbl.cluster1_du) * 100.0/cpufreq_eg_tbl.cluster1_du)
	|| ', total_eg_diff_pct:' || (abs(cpufreq_eg_tbl.total_eg - uid_eg_tbl.total_eg) * 100.0/cpufreq_eg_tbl.total_eg)
		as total_eg_vs_total_uid_eg_validation,
	case when abs(cpufreq_eg_tbl.cluster0_du - uid_eg_tbl.cluster0_du) * 100.0/cpufreq_eg_tbl.cluster0_du > 1 or  abs(cpufreq_eg_tbl.cluster1_du - uid_eg_tbl.cluster1_du ) * 100.0/cpufreq_eg_tbl.cluster1_du > 1 or abs(cpufreq_eg_tbl.total_eg - uid_eg_tbl.total_eg) * 100.0/cpufreq_eg_tbl.total_eg > 1 then 'fail' else 'success' end as result
from
(
	select
			sum(cpu0_0_du + cpu0_1_du + cpu0_2_du + cpu0_3_du + cpu0_4_du + cpu0_5_du + cpu0_6_du + cpu0_7_du + cpu0_8_du + cpu0_9_du + cpu0_10_du + cpu0_11_du + cpu0_12_du + cpu0_13_du + cpu0_14_du + cpu0_15_du +
			cpu1_0_du + cpu1_1_du + cpu1_2_du + cpu1_3_du + cpu1_4_du + cpu1_5_du + cpu1_6_du + cpu1_7_du + cpu1_8_du + cpu1_9_du + cpu1_10_du + cpu1_11_du + cpu1_12_du + cpu1_13_du + cpu1_14_du + cpu1_15_du +
			cpu2_0_du + cpu2_1_du + cpu2_2_du + cpu2_3_du + cpu2_4_du + cpu2_5_du + cpu2_6_du + cpu2_7_du + cpu2_8_du + cpu2_9_du + cpu2_10_du + cpu2_11_du + cpu2_12_du + cpu2_13_du + cpu2_14_du + cpu2_15_du +
			cpu3_0_du + cpu3_1_du + cpu3_2_du + cpu3_3_du + cpu3_4_du + cpu3_5_du + cpu3_6_du + cpu3_7_du + cpu3_8_du + cpu3_9_du + cpu3_10_du + cpu3_11_du + cpu3_12_du + cpu3_13_du + cpu3_14_du + cpu3_15_du) as cluster0_du,
			sum(cpu4_0_du + cpu4_1_du + cpu4_2_du + cpu4_3_du + cpu4_4_du + cpu4_5_du + cpu4_6_du + cpu4_7_du + cpu4_8_du + cpu4_9_du + cpu4_10_du + cpu4_11_du + cpu4_12_du + cpu4_13_du + cpu4_14_du + cpu4_15_du +
			cpu5_0_du + cpu5_1_du + cpu5_2_du + cpu5_3_du + cpu5_4_du + cpu5_5_du + cpu5_6_du + cpu5_7_du + cpu5_8_du + cpu5_9_du + cpu5_10_du + cpu5_11_du + cpu5_12_du + cpu5_13_du + cpu5_14_du + cpu5_15_du +
			cpu6_0_du + cpu6_1_du + cpu6_2_du + cpu6_3_du + cpu6_4_du + cpu6_5_du + cpu6_6_du + cpu6_7_du + cpu6_8_du + cpu6_9_du + cpu6_10_du + cpu6_11_du + cpu6_12_du + cpu6_13_du + cpu6_14_du + cpu6_15_du +
			cpu7_0_du + cpu7_1_du + cpu7_2_du + cpu7_3_du + cpu7_4_du + cpu7_5_du + cpu7_6_du + cpu7_7_du + cpu7_8_du + cpu7_9_du + cpu7_10_du + cpu7_11_du + cpu7_12_du + cpu7_13_du + cpu7_14_du + cpu7_15_du) as cluster1_du,
			sum(total_eg) as total_eg
		from comp_cpufreq_cpuagent_backward
	) cpufreq_eg_tbl,
(
	select
			 sum(c0_0_du + c0_1_du + c0_2_du + c0_3_du + c0_4_du + c0_5_du + c0_6_du + c0_7_du + c0_8_du + c0_9_du + c0_10_du + c0_11_du + c0_12_du + c0_13_du + c0_14_du + c0_15_du) as cluster0_du,
			 sum(c1_0_du + c1_1_du + c1_2_du + c1_3_du + c1_4_du + c1_5_du + c1_6_du + c1_7_du + c1_8_du + c1_9_du + c1_10_du + c1_11_du + c1_12_du + c1_13_du + c1_14_du + c1_15_du) as cluster1_du,
			 sum(total_eg) as total_eg
	from comp_uidstate_cpuagent_backward
	where tgid = -1 and pid = -1
	) uid_eg_tbl;

-- uidstate duration vs energy validation
select *
from
(
	select '1' as uidstate_duration_vs_energy_validation, sum(c0_0_du)*36.07*1000000 /1000/3600 as c0_0_du, sum(c0_1_du) *  45.8*1000000 /1000/3600 as c0_1_du, sum(c0_2_du)*47.25 *1000000 /1000/3600 as c0_2_du, sum(c0_3_du)*47.45*1000000 /1000/3600 as c0_3_du, sum(c0_4_du)*48.42*1000000 /1000/3600 as c0_4_du, sum(c0_5_du)*50.68*1000000 /1000/3600 as c0_5_du, sum(c0_6_du) *51.46*1000000 /1000/3600 as c0_6_du, sum(c0_7_du) *53.8*1000000 /1000/3600 as c0_7_du, sum(c0_8_du)* 55.65*1000000 /1000/3600 as c0_8_du, sum(c0_9_du)*56.77 *1000000 /1000/3600 as c0_9_du, sum(c0_10_du) *58.02*1000000 /1000/3600 as c0_10_du, sum(c0_11_du)*59.89 *1000000 /1000/3600 as c0_11_du, sum(c0_12_du) * 61.6*1000000 /1000/3600 as c0_12_du, sum(c0_13_du) *62.6*1000000 /1000/3600 as c0_13_du, sum(c0_14_du) *63.35*1000000 /1000/3600 as c0_14_du, sum(c0_15_du)*64.29 *1000000 /1000/3600 as c0_15_du
	from comp_uidstate_cpuagent_backward
	where tgid = -1
	union
	select '2' as uidstate_duration_vs_energy_validation, sum(c0_0_eg) as c0_0_eg, sum(c0_1_eg) as c0_1_eg, sum(c0_2_eg) as c0_2_eg, sum(c0_3_eg) as c0_3_eg, sum(c0_4_eg) as c0_4_eg, sum(c0_5_eg) as c0_5_eg, sum(c0_6_eg) as c0_6_eg, sum(c0_7_eg) as c0_7_eg, sum(c0_8_eg) as c0_8_eg, sum(c0_9_eg) as c0_9_eg, sum(c0_10_eg) as c0_10_eg, sum(c0_11_eg) as c0_11_eg, sum(c0_12_eg) as c0_12_eg, sum(c0_13_eg) as c0_13_eg, sum(c0_14_eg) as c0_14_eg, sum(c0_15_eg) as c0_15_eg
	from comp_uidstate_cpuagent_backward
	where tgid = -1
	union
	select '3' as uidstate_duration_vs_energy_validation, sum(c1_0_du)*47.08*1000000 /1000/3600 as c1_0_du, sum(c1_1_du) *  49.95*1000000 /1000/3600 as c1_1_du, sum(c1_2_du)*53.83 *1000000 /1000/3600 as c1_2_du, sum(c1_3_du)*58.26*1000000 /1000/3600 as c1_3_du, sum(c1_4_du)*63.1*1000000 /1000/3600 as c1_4_du, sum(c1_5_du)*67.98*1000000 /1000/3600 as c1_5_du, sum(c1_6_du) *71.56*1000000 /1000/3600 as c1_6_du, sum(c1_7_du) *80.83*1000000 /1000/3600 as c1_7_du, sum(c1_8_du)* 87.07*1000000 /1000/3600 as c1_8_du, sum(c1_9_du)*93.63 *1000000 /1000/3600 as c1_9_du, sum(c1_10_du) *103.32*1000000 /1000/3600 as c1_10_du, sum(c1_11_du)*114.26 *1000000 /1000/3600 as c1_11_du, sum(c1_12_du) * 129.69*1000000 /1000/3600 as c1_12_du, sum(c1_13_du) *137.84*1000000 /1000/3600 as c1_13_du, sum(c1_14_du) *148.68*1000000 /1000/3600 as c1_14_du, sum(c1_15_du)*154.51 *1000000 /1000/3600 as c1_15_du
	from comp_uidstate_cpuagent_backward
	where tgid = -1
	union
	select '4' as uidstate_duration_vs_energy_validation, sum(c1_0_eg) as c1_0_eg, sum(c1_1_eg) as c1_1_eg, sum(c1_2_eg) as c1_2_eg, sum(c1_3_eg) as c1_3_eg, sum(c1_4_eg) as c1_4_eg, sum(c1_5_eg) as c1_5_eg, sum(c1_6_eg) as c1_6_eg, sum(c1_7_eg) as c1_7_eg, sum(c1_8_eg) as c1_8_eg, sum(c1_9_eg) as c1_9_eg, sum(c1_10_eg) as c1_10_eg, sum(c1_11_eg) as c1_11_eg, sum(c1_12_eg) as c1_12_eg, sum(c1_13_eg) as c1_13_eg, sum(c1_14_eg) as c1_14_eg, sum(c1_15_eg) as c1_15_eg
	from comp_uidstate_cpuagent_backward
	where tgid = -1
)
order by uidstate_duration_vs_energy_validation asc;
