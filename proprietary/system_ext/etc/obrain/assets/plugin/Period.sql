select datetime(start_ts / 1000, 'unixepoch', 'localtime') as start_ts
	, datetime(end_ts / 1000, 'unixepoch', 'localtime') as end_ts
	, (end_ts - start_ts) / 1000.0 / 3600 as duration_hour
from (
	select (
			select value
			from persist_properties
			where name = 'main.db_created_wall_time'
		) as start_ts
		, (
			select value
			from persist_properties
			where name = 'main.db_last_access_obrain_time'
		) as end_ts
)