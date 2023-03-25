with
PARAM_VAR as (
    select
        {} as var_date,
        {} as var_start_ts,
        {} as var_end_ts,
        {} as var_version,
        {} as var_top_app_num_uid,
        {} as var_top_app_num_pid,
        {} as var_top_app_num_tid,
        {} as var_leakage,
        {} as var_revision
),
-- TOP_TBL -----------------------------------------------------------------------------------------
-- TOP_UID --------------------------------------
TOP_UID_TMP as (
    select null as pid_name, null as tgid_name, uid_name, power_mode, screen_mode, thermal_mode, ground_mode
        , VectorSuffixSumVectorII('as c$0_duration', 'sum(c$0_$1_du)', CpuClusterList, CpuFreqListList)
        , VectorVectorII('sum(c$0_$1_du) as c$0_$1_du', CpuClusterList, CpuFreqListList)
        , sum(pmu_total_eg) as pmu_total_eg
        , sum(total_eg) as total_eg
        , sum(wall_du) as wall_du
        , row_number() over (partition by power_mode, screen_mode, thermal_mode, ground_mode order by sum(total_eg) desc) as idx
    from agg_uidstate_cpuagent_hourly, PARAM_VAR
    where type = 0 and start_ts >= PARAM_VAR.var_start_ts and end_ts <= PARAM_VAR.var_end_ts
    group by power_mode, screen_mode, thermal_mode, ground_mode, uid_name
),
TOP_UID as (
    select 'uid' as type, obfuscate(uid_name) as name, null as parent, null as grand_parent, TOP_UID_TMP.*
    from TOP_UID_TMP, PARAM_VAR
    where idx <= PARAM_VAR.var_top_app_num_uid
),
-- TOP_TGID ---------------------------------------
T2 as (
    select tgid_name, uid_name, power_mode, screen_mode, thermal_mode, ground_mode
        , VectorSuffixSumVectorII('  as c$0_duration', 'sum(c$0_$1_du)', CpuClusterList, CpuFreqListList)
        , VectorVectorII('sum(c$0_$1_du) as c$0_$1_du', CpuClusterList, CpuFreqListList)
        , sum(pmu_total_eg) as pmu_total_eg
        , sum(total_eg) as total_eg
        , 0 as wall_du
    from agg_uidstate_cpuagent_hourly, PARAM_VAR
    where type = 1 and start_ts >= PARAM_VAR.var_start_ts and end_ts <= PARAM_VAR.var_end_ts
    group by tgid_name, uid_name, power_mode, screen_mode, thermal_mode, ground_mode
),
TOP_TGID_TMP as (
    select null as pid_name, T2.tgid_name, T1.uid_name, T1.power_mode, T1.screen_mode, T1.thermal_mode, T1.ground_mode
        , VectorI('T2.c$0_duration', CpuClusterList)
        , VectorVectorII('T2.c$0_$1_du', CpuClusterList, CpuFreqListList)
        , T2.pmu_total_eg as pmu_total_eg
        , T2.total_eg as total_eg
        , T2.wall_du as wall_du
        , row_number() over (partition by T1.power_mode, T1.screen_mode, T1.thermal_mode, T1.ground_mode, T1.uid_name order by T2.total_eg desc) as idx
    from TOP_UID T1 inner join T2
    on T1.power_mode = T2.power_mode
        and T1.screen_mode = T2.screen_mode
        and T1.thermal_mode = T2.thermal_mode
        and T1.ground_mode = T2.ground_mode
        and T1.uid_name = T2.uid_name
),
TOP_TGID as (
    select 'process' as type, tgid_name as name, obfuscate(uid_name) as parent, null as grand_parent, TOP_TGID_TMP.*
    from TOP_TGID_TMP, PARAM_VAR
    where idx <= PARAM_VAR.var_top_app_num_pid
),
-- TOP_T3T4 --------------------------------------
T4 as (
    select pid_name, tgid_name, uid_name, power_mode, screen_mode, thermal_mode, ground_mode
        , VectorSuffixSumVectorII('  as c$0_duration', 'sum(c$0_$1_du)', CpuClusterList, CpuFreqListList)
        , VectorVectorII('sum(c$0_$1_du) as c$0_$1_du', CpuClusterList, CpuFreqListList)
        , sum(pmu_total_eg) as pmu_total_eg
        , sum(total_eg) as total_eg
        , sum(wall_du) as wall_du
    from agg_uidstate_cpuagent_hourly, PARAM_VAR
    where type = 1 and start_ts >= PARAM_VAR.var_start_ts and end_ts <= PARAM_VAR.var_end_ts
    group by power_mode, screen_mode, thermal_mode, ground_mode, uid_name, tgid_name, pid_name
),
T3T4 as (
    select T4.pid_name, T3.tgid_name, T3.uid_name, T3.power_mode, T3.screen_mode, T3.thermal_mode, T3.ground_mode
        , VectorI('T4.c$0_duration', CpuClusterList)
        , VectorVectorII('T4.c$0_$1_du', CpuClusterList, CpuFreqListList)
        , T4.pmu_total_eg as pmu_total_eg
        , T4.total_eg as total_eg
        , T4.wall_du as wall_du
        , row_number() over (partition by T3.power_mode, T3.screen_mode, T3.thermal_mode, T3.ground_mode, T3.uid_name, T3.tgid_name order by T4.total_eg desc) as idx
    from TOP_TGID T3 inner join T4
    on T3.power_mode = T4.power_mode
        and T3.screen_mode = T4.screen_mode
        and T3.thermal_mode = T4.thermal_mode
        and T3.ground_mode = T4.ground_mode
        and T3.tgid_name = T4.tgid_name
        and T3.uid_name = T4.uid_name
),
TOP_T3T4 as (
    select 'thread' as type, pid_name as name, tgid_name as parent, uid_name as grand_parent, pid_name, tgid_name, obfuscate(uid_name), power_mode, screen_mode, thermal_mode, ground_mode
        , VectorI('c$0_duration', CpuClusterList)
        , VectorVectorII('c$0_$1_du', CpuClusterList, CpuFreqListList)
        , pmu_total_eg
        , total_eg
        , wall_du
        , idx
    from T3T4, PARAM_VAR
    where idx <= PARAM_VAR.var_top_app_num_tid
),
-----------------------------------------------------
ALL_TOP as (
    select * from TOP_UID
    union
    select * from TOP_TGID
    union
    select * from TOP_T3T4
),
TOP_TBL_TMP as (
select '{{' || '"name":' || '"' || name || '",' || '"idx":' || '"' || idx || '",' || '"screen_mode":' || '"' || screen_mode || '",' || '"thermal_mode":' || '"' || thermal_mode || '",' || '"power_mode":' || '"' || power_mode || '",' || '"ground_mode":"' || ground_mode || '",'
            || MapJsonFormatI('"c$0_duration"', 'c$0_duration', CpuClusterList) || ','
            || MapVectorJsonFormatII('"c$0_freq_duration"', "c$0_$1_du", CpuClusterList, CpuFreqListList) || ","
            || '"type":"' || type || '",'
            || '"parent":"' || ifnull(parent, '') || '",'
            || '"grand_parent":"' || ifnull(grand_parent, '') || '",'
            || '"wall_du":"' || wall_du || '",'
            || '"pmu_total_eg":"' || pmu_total_eg || '",'
            || '"total_eg":"' || total_eg || '"}}' as oneline
        from ALL_TOP
),
TOP_TBL as (
    select '[' || group_concat(oneline) || ']' as energy
    from TOP_TBL_TMP
),
-- CPU_FG_EG_TBL -----------------------------------------------------------------------------------
CPU_FG_EG_TBL_TMP as (
    select "{{" || '"screen_mode":' || '"' || screen_mode || '",' || '"thermal_mode":' || '"' || thermal_mode || '",' || '"power_mode":' || '"' || power_mode || '",'
        || MapSumVectorJsonFormatII('"c$0_duration"', 'sum(c$0_$1_du)', CpuClusterList, CpuFreqListList) || ","
        || MapVectorJsonFormatII('"c$0_freq_duration"', 'sum(c$0_$1_du)', CpuClusterList, CpuFreqListList) || ","
        || '"pmu_total_eg":' || '"' || sum(pmu_total_eg) || '",'
        || '"wall_du":' || '"' || (PARAM_VAR.var_end_ts - PARAM_VAR.var_start_ts) || '",'
        || '"total_eg":' || '"' || sum(total_eg) || '"' || "}}" as by_category
    from agg_uidstate_cpuagent_hourly, PARAM_VAR
    where ground_mode = 1 and type = 0 and start_ts >= PARAM_VAR.var_start_ts and end_ts <= PARAM_VAR.var_end_ts
    group by screen_mode, thermal_mode, power_mode
),
CPU_FG_EG_TBL as (
    select '[' || group_concat(by_category, ', ') || ']' as fg_cpu_energy
    from CPU_FG_EG_TBL_TMP
),
-- PWR_TBL -----------------------------------------------------------------------------------------
CPU_BG_EG_TBL_TMP as (
    select "{{" || '"screen_mode":' || '"' || screen_mode || '",' || '"thermal_mode":' || '"' || thermal_mode || '",' || '"power_mode":' || '"' || power_mode || '",'
        || MapSumVectorJsonFormatII('"c$0_duration"', 'sum(c$0_$1_du)', CpuClusterList, CpuFreqListList) || ","
        || MapVectorJsonFormatII('"c$0_freq_duration"', 'sum(c$0_$1_du)', CpuClusterList, CpuFreqListList) || ","
        || '"wall_du":' || '"' || (PARAM_VAR.var_end_ts - PARAM_VAR.var_start_ts) || '",'
        || '"pmu_total_eg":' || '"' || sum(pmu_total_eg) || '",'
        || '"total_eg":' || '"' || sum(total_eg) || '"' || "}}" as by_category
    from agg_uidstate_cpuagent_hourly, PARAM_VAR
    where ground_mode = 0 and type = 0 and start_ts >= PARAM_VAR.var_start_ts and end_ts <= PARAM_VAR.var_end_ts
    group by screen_mode, thermal_mode, power_mode
),
CPU_BG_EG_TBL as (
    select '[' || group_concat(by_category, ', ') || ']' as bg_cpu_energy
    from CPU_BG_EG_TBL_TMP
),
PWR_TBL as (
    select '{{' ||
        MapVectorJsonFormatID('"c$0_factor"', '$1', CpuClusterList, CpuFreqFactorListList) || ','
        || MapVectorJsonFormatII('"c$0_volt"', '$1', CpuClusterList, CpuCoreVoltListList) || ','
        || '"leakage":' || PARAM_VAR.var_leakage || ','
        || '"revision":' || PARAM_VAR.var_revision ||'}}' as power_table
    from PARAM_VAR
)
----------------------------------------------------------------------------------------------------
insert into agg_cpuagent_daily
select PARAM_VAR.var_date as DATE, PARAM_VAR.var_start_ts as start_ts, PARAM_VAR.var_end_ts as end_ts, '0' as upload, TOP_TBL.energy as top_app
    , CPU_FG_EG_TBL.fg_cpu_energy as fg_cpu_energy, CPU_BG_EG_TBL.bg_cpu_energy as bg_cpu_energy,
    PWR_TBL.power_table as power_table, PARAM_VAR.var_version as version
from TOP_TBL, CPU_FG_EG_TBL, CPU_BG_EG_TBL, PWR_TBL, PARAM_VAR