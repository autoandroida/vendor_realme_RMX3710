create view if not exists {}.diag_obrain_binder_self_check as
with COMP_CHECK_TABLE as(
    select
        case
            when count(*) = 0 then 'fail'
            else 'pass'
        end as result,
		'comp_binderstats_binderagent_backward' as tbl_name
	from comp_binderstats_binderagent_backward
),
COMP_TABLE_EMPTY_CHECK as(
    select
        'empty_table_check' as item,
        case
            when count(*) != 0 then 'fail'
            else 'pass'
	    end as result,
        count(*) as fail_cnt,
        json_group_array('tbl_name:' || tbl_name) as detail
    from COMP_CHECK_TABLE where result = 'fail'
),

AGG_JSON_TABLE as (
    select json_valid(binder_stats) as json_result,
		   'binder_stats' as fields
	from agg_binderagent_daily
),
JSON_RESULT_TABLE as (
	select
		'agg_binderagent_daily' as table_name,
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
union
select * from COMP_TABLE_EMPTY_CHECK