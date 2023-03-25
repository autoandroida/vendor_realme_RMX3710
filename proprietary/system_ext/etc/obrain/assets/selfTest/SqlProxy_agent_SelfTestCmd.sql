create view if not exists {}.diag_obrain_agent_self_check as
with all_agent_table as (
select 'rndm' as Agent
UNION
select 'binder' as Agent
UNION
select 'dsp' as Agent
UNION
select 'alarm' as Agent
UNION
select 'wifi' as Agent
UNION
select 'gnss' as Agent
UNION
select 'audio' as Agent
UNION
select 'thermal' as Agent
UNION
select 'ddr' as Agent
UNION
select 'gpu' as Agent
UNION
select 'resume' as Agent
UNION
select 'ufs' as Agent
UNION
select 'camera' as Agent
UNION
select 'cpu' as Agent
UNION
select 'meta' as Agent
UNION
select 'display' as Agent
UNION
select 'battery' as Agent
UNION
select 'cellular' as Agent
UNION
select 'foreign' as Agent
UNION
select 'flashlight' as Agent
),

none_agent_table as (
    select Agent from all_agent_table
        where Agent not in (
            select DISTINCT DES
            from log_running_event where EVENT = 'DCS'
        )
),

upload_check as (
select 'upload_check' as item,
	case
	    when count(*) > 0 then 'fail'
        else 'pass'
    end as result,
	count(*) as fail_cnt,
    json_group_array('agent:' || Agent) as detail
from none_agent_table
),

LOG_ERR_CHECK_TBL as (
    select 'logic_error_check' as item,
        case
            when count(*) > 0 then 'fail'
            else 'pass'
        end as result,
		count(*) as fail_cnt,
        json_group_array(DATE || ':' || EVENT || ':' || DES) as detail
    from log_running_event
    where EVENT='ERROR'
)

select * from LOG_ERR_CHECK_TBL
UNION
select * from upload_check
;