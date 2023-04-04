create view if not exists {}.diag_obrain_meta_self_check as
with AGG_JSON_TABLE as (
    select json_valid(obrainInfo) as json_result,
	    'agg_metaAgent_daily'  as table_name,
	    'obrainInfo' as fields
	from agg_metaAgent_daily
UNION
select json_valid(sysInfo) as json_result,
	'agg_metaAgent_daily'  as table_name,
	'sysInfo' as fields
	from agg_metaAgent_daily
),
JSON_RESULT_TABLE as (
    select
        'agg_metaAgent_daily' as table_name,
	    fields,
	    json_result
	from AGG_JSON_TABLE
),
JSON_ERROR_CHECK_TABLE as (
	select 'json_check' as item ,
		case
		    when count(*) = 0 then 'pass'
		    else 'fail'
		end as result ,
		count(*) as fail_cnt,
		json_group_array(table_name || ":" || fields) as detail
	from JSON_RESULT_TABLE
	    where json_result = 0
)
select * from JSON_ERROR_CHECK_TABLE