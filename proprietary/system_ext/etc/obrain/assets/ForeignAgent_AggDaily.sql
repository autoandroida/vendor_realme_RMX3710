with
PARAM_VAR as (
select
    {} as var_start_ts,
    {} as var_end_ts,
    {} as var_date,
    {} as var_version
)
, agg_foreign_table as (
    select '[' || group_concat(foreign_msg, ', ') || ']' as foreign_msg
    from (
		select '{{' || '"notify_type":' || notify_type || ',' || '"msg":' || msg || ',' || '"related_data":' || '[' || group_concat(related_data)|| ']' || '}}'  as foreign_msg
        from comp_foreign_event, PARAM_VAR
        where start_ts >= PARAM_VAR.var_start_ts
            and end_ts <= PARAM_VAR.var_end_ts
        group by msg
        order by end_ts asc
        limit 5
    )

)
INSERT INTO agg_foreign_event_daily
SELECT '0' as upload, PARAM_VAR.var_date as date, PARAM_VAR.var_start_ts as start_ts, PARAM_VAR.var_end_ts as end_ts, agg_foreign_table.foreign_msg as foreign_msg, PARAM_VAR.var_version as version
from agg_foreign_table, PARAM_VAR