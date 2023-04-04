with
PARAM_VAR as (
select
    {} as var_wall_start_ts,
    {} as var_wall_end_ts,
    {} as var_start_ts,
    {} as var_end_ts,
    {} as notify_type,
    '{}' as var_msg,
    '{}' as related_data,
    start_ts as var_event_start_ts,
	end_ts as var_event_end_ts,
    ifnull((end_ts - start_ts), -1) as total_duration
	from (
		SELECT start_ts, end_ts
		from comp_uidstate_cpuagent_backward
		where end_ts = {}
			and screen_mode != -1
			and ground_mode != -1
			and pid = -1 and tgid = -1
		GROUP by end_ts
	)

),
related_table as (
    select '{{'
			||'"related_cpu_data":'|| '{{' || '"total_cpu_load":' || round((1.0*CPU_LOAD_TBL.total_cpu_du/ (total_duration)),3) || ','
			||'"cpu_data":' || '['|| ifnull(CPU_CONCAT_TBL.cpu_related_data, "")|| ']}},'
 			|| '"related_cellular_data":' || '[' || ifnull(CEL_CONCAT_TBL.cellular_related_data, "") || ']'
			|| '}}'
			as related_whole_data
	from (
        select group_concat(CPU_RELATED_TBL.cpu_related_data) as cpu_related_data
        from (
            select '{{' || '"screen_mode":' || screen_mode || ','
                        || '"ground_mode":' || ground_mode || ','
                        || '"uid_name":"' || obfuscate(uid_name) || '",'
                        || '"cpu_load_by_app":"' || round(((1.0 * total_cpu_du) / (total_duration)) ,3)|| '",'
                        ||  MapSumVectorJsonFormatII('"c$0_load_by_app"', 'round(sum(1.0*c$0_duration/($1 * total_duration)),3)', CpuClusterList, CpuCoreListList)
                        || '}}' as cpu_related_data
            from (
                select *, (SumVector2II('c$0_duration / $1', CpuClusterList, CpuCoreList)) as total_cpu_du
                from (
                    select  screen_mode,ground_mode,uid_name,
                             VectorSuffixSumVectorII(' as c$0_duration', 'sum(c$0_$1_du)', CpuClusterList, CpuFreqListList),
                             PARAM_VAR.total_duration as total_duration
                    from comp_uidstate_cpuagent_backward, PARAM_VAR
                    where start_ts >= PARAM_VAR.var_event_start_ts
                        and end_ts <= PARAM_VAR.var_event_end_ts
                        and screen_mode != -1
                        and ground_mode != -1
                        and pid = -1 and tgid = -1
                    group by screen_mode, ground_mode, uid_name
                    order by sum(total_eg) desc
                    limit 3
                )
                group by screen_mode, ground_mode, uid_name
            )
            group by screen_mode, ground_mode, uid_name
        ) CPU_RELATED_TBL

	) CPU_CONCAT_TBL,
	(
	    select total_duration, (SumVector2II('sum(c$0_duration) / $1', CpuClusterList, CpuCoreList)) as total_cpu_du
	    from (
            select  VectorSuffixSumVectorII(' as c$0_duration', 'sum(c$0_$1_du)', CpuClusterList, CpuFreqListList),
                    PARAM_VAR.total_duration as total_duration
            from comp_uidstate_cpuagent_backward, PARAM_VAR
            where start_ts >= PARAM_VAR.var_event_start_ts
                and end_ts <= PARAM_VAR.var_event_end_ts
                and screen_mode != -1
                and ground_mode != -1
                and pid = -1 and tgid = -1
	    )

	) CPU_LOAD_TBL,
    (
        select PARAM_VAR.related_data as cellular_related_data
        from PARAM_VAR
	) CEL_CONCAT_TBL
)

INSERT INTO comp_foreign_event
SELECT
PARAM_VAR.var_wall_start_ts,
PARAM_VAR.var_wall_end_ts,
PARAM_VAR.var_start_ts,
PARAM_VAR.var_end_ts,
PARAM_VAR.notify_type AS notify_type,
PARAM_VAR.var_msg as msg,
related_table.related_whole_data as related_data
FROM related_table, PARAM_VAR