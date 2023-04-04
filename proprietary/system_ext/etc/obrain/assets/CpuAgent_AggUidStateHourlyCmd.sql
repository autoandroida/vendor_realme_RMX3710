with
uidstate_tmp as (
    select  power_mode, screen_mode, thermal_mode, ground_mode
                    , case when pid = -1 and tgid = -1 then 0 else 1 end as type
                    , pid_name, tgid_name, uid_name
                    , VectorVectorII('sum(c$0_$1_du) as c$0_$1_du', CpuClusterList, CpuFreqListList)
                    , VectorSuffixSumVectorII(' as c$0_duration', 'sum(c$0_$1_du)', CpuClusterList, CpuFreqListList)
                    , case when ground_mode = 1 then sum(end_ts - start_ts) else 0 end as wall_du
                    , sum(total_eg) as total_eg, sum(pmu_total_eg) as pmu_total_eg
    from comp_uidstate_cpuagent_backward
    where start_ts >= {} and end_ts <= {} and power_mode != -1 and screen_mode != -1 and thermal_mode != -1 and ground_mode != -1
    group by power_mode, screen_mode, thermal_mode, ground_mode, case when (pid = -1 and tgid = -1) then 0 else 1 end, pid_name, tgid_name, uid_name, start_ts, end_ts
)
insert into agg_uidstate_cpuagent_hourly
(
start_ts,
end_ts,
power_mode,
screen_mode,
thermal_mode,
ground_mode,
type,
pid_name,
tgid_name,
uid_name,
VectorVectorII('c$0_$1_du', CpuClusterList, CpuFreqListList),
VectorI('c$0_duration', CpuClusterList),
total_duration,
wall_du,
total_eg,
pmu_total_eg
)
select {} as start_ts, {} as end_ts, power_mode, screen_mode, thermal_mode, ground_mode, type, pid_name, tgid_name, uid_name,
    VectorVectorII('sum(c$0_$1_du) as c$0_$1_du', CpuClusterList, CpuFreqListList),
    VectorSuffixSumVectorII(' as c$0_duration', 'sum(c$0_$1_du)', CpuClusterList, CpuFreqListList),
    SumVectorI('sum(c$0_duration)', CpuClusterList) as total_du,
    sum(wall_du) as wall_du,
    sum(total_eg) as total_eg,
    sum(pmu_total_eg) as pmu_total_eg
from uidstate_tmp
group by power_mode, screen_mode, thermal_mode, ground_mode, type, pid_name, tgid_name, uid_name;
