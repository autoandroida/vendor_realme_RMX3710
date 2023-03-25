with
PARAM_VAR as (
    select
        {} as var_date,
        {} as var_start_ts,
        {} as var_end_ts,
        {} as var_version
),
TOP_APP_BY_MODE_TBL as (
	--  group concat each record to single one
	select json_group_array(top_app) as top_app_by_mode
	from (
		--  Join original table with top 10 app table, then group each mode and finally concact every mode to one single string
        select json_object('package_name', obfuscate(T1.package_name), 'idx', idx, 'screen_mode', T1.screen_mode
        , 'ground_mode', T1.ground_mode, 'power_mode', T1.power_mode, 'thermal_mode', T1.thermal_mode, 'tx_byte', sum(tx_byte)
        , 'rx_byte', sum(rx_byte), 'tx_time', round(sum(tx_time), 2), 'rx_time', round(sum(rx_time), 2), 'tx_packet', sum(tx_packet)
        , 'rx_packet', sum(rx_packet), 'total_eg', sum(T1.total_eg), 'total_du', sum(total_du), 'busy_du', round(sum(busy_du), 2)
        , 'wifi_id', wifi_id, 'enable', enable, 'hotspot', hotspot, 'freqency_band', frequency_band, 'standard', standard) as top_app
		from (
			--  Original table
			select *
			from agg_wifi_agent_app_hourly, PARAM_VAR
			where start_ts >= PARAM_VAR.var_start_ts
				and end_ts <= PARAM_VAR.var_end_ts
		) T1
			inner join (
				--  Select top 10 applications
				select *
				from (
					--  partition each mode and add idx value
					select package_name, screen_mode, power_mode, thermal_mode, ground_mode
						, row_number() over (partition by power_mode, ground_mode, screen_mode, thermal_mode order by sum(total_eg) desc) as idx
					from agg_wifi_agent_app_hourly, PARAM_VAR
					where start_ts >= PARAM_VAR.var_start_ts
						and end_ts <= PARAM_VAR.var_end_ts
					group by package_name, power_mode, ground_mode, screen_mode, thermal_mode
				)
				where idx <= 10
			) T2
			on T1.package_name = T2.package_name
				and T1.screen_mode = T2.screen_mode
				and T1.power_mode = T2.power_mode
				and T1.thermal_mode = T2.thermal_mode
				and T1.ground_mode = T2.ground_mode
		group by T1.package_name, T1.screen_mode, T1.power_mode, T1.thermal_mode, T1.ground_mode, wifi_id, enable, hotspot, frequency_band, standard
	)
),
EG_TBL as (
	select json_group_array(oneline) as energy
	from (
		 select json_object('screen_mode', screen_mode, 'power_mode', power_mode, 'thermal_mode', thermal_mode, 'ground_mode', ground_mode
		 , 'tx_byte', tx_byte, 'rx_byte', rx_byte, 'tx_time', round(tx_time, 2), 'rx_time', round(rx_time, 2), 'tx_packet', tx_packet
         , 'rx_packet', rx_packet, 'total_eg', total_eg, 'total_du', total_du, 'busy_du', round(busy_du, 2)
         , 'wifi_id', wifi_id, 'enable', enable, 'hotspot', hotspot, 'freqency_band', frequency_band, 'standard', standard) as oneline
		from (
			select screen_mode, power_mode, thermal_mode, ground_mode, wifi_id
				, enable, hotspot
				, frequency_band, standard
				, sum(tx_byte) as tx_byte
				, sum(rx_byte) as rx_byte
				, sum(tx_time) as tx_time
				, sum(rx_time) as rx_time
				, sum(tx_packet) as tx_packet
				, sum(rx_packet) as rx_packet
				, sum(total_du) as total_du
				, sum(busy_du) as busy_du
				, sum(total_eg) as total_eg
			from agg_wifi_agent_app_hourly, PARAM_VAR
			where start_ts >= PARAM_VAR.var_start_ts
				and end_ts <= PARAM_VAR.var_end_ts
			group by screen_mode, power_mode, thermal_mode, ground_mode, wifi_id, enable, hotspot, frequency_band, standard
		)
	)
),
TOP_TIME_APP as (
	select json_group_array(top_time_app) as top_time_app from (
	    select json_object('package_name', obfuscate(package_name), 'total_du', total_du, 'tx_byte', tx_byte, 'rx_byte', rx_byte
		 , 'tx_time', round(tx_time, 2), 'rx_time', round(rx_time, 2)) as top_time_app
		from (
			select
				package_name, sum(total_du) as total_du,
				sum(tx_byte) as tx_byte, sum(rx_byte) as rx_byte,
				sum(tx_time) as tx_time, sum(rx_time) as rx_time
			from agg_wifi_agent_app_hourly
			where ground_mode = 1
			group by package_name
			order by sum(total_du) desc
			limit 10
		)
	)
),
TOP_TX_APP as (
	select json_group_array(top_tx_app) as top_tx_app from (
		select json_object('package_name', obfuscate(package_name), 'tx_byte', tx_byte, 'rx_byte', rx_byte
		 , 'tx_time', round(tx_time, 2), 'rx_time', round(rx_time, 2)) as top_tx_app
		from (
			select package_name,
			sum(tx_byte) as tx_byte, sum(rx_byte) as rx_byte,
			sum(tx_time) as tx_time, sum(rx_time) as rx_time
			from agg_wifi_agent_app_hourly
			group by package_name
			order by sum(tx_byte) desc
			limit 10
		)
	)
),
TOP_RX_APP as (
	select json_group_array(top_rx_app) as top_rx_app from (
		select json_object('package_name', obfuscate(package_name), 'tx_byte', tx_byte, 'rx_byte', rx_byte
		 , 'tx_time', round(tx_time, 2), 'rx_time', round(rx_time, 2)) as top_rx_app
		from (
			select package_name,
			sum(tx_byte) as tx_byte, sum(rx_byte) as rx_byte,
			sum(tx_time) as tx_time, sum(rx_time) as rx_time
			from agg_wifi_agent_app_hourly
			group by package_name
			order by sum(rx_byte) desc
			limit 10
		)
	)
),
BY_ANTENNA as (
	select json_group_array(by_antenna) as by_antenna from (
		select json_object('frequency_band', frequency_band, 'standard', standard, 'band_width', band_width
		 , 'antenna', antenna, 'total_du', total_du) as by_antenna
		from (
			select frequency_band, standard, band_width, antenna,
					sum(total_du) as total_du
			from agg_wifi_agent_app_hourly
			where ground_mode = 1
			group by frequency_band, standard, band_width, antenna
		)
	)
),
BY_STANDARD as (
	select json_group_array(by_standard) as by_standard from (
		select json_object('frequency_band', frequency_band, 'standard', standard, 'band_width', band_width
		 , 'antenna', antenna, 'tx_byte', tx_byte, 'rx_byte', rx_byte, 'tx_time', round(tx_time, 2)
		 , 'rx_time', round(rx_time, 2), 'total_eg', total_eg) as by_standard
		from (
			select frequency_band, standard, band_width, antenna,
					sum(tx_byte) as tx_byte, sum(rx_byte) as rx_byte,
					sum(tx_time) as tx_time, sum(rx_time) as rx_time,
					sum(total_eg) as total_eg
			from agg_wifi_agent_app_hourly
			group by frequency_band, standard, band_width, antenna
		)
	)
),
ATTACHMENT as (
    select json_object(
        'top_time_app', json(top_time_app)
        , 'top_tx_app', json(top_tx_app)
        , 'top_rx_app', json(top_rx_app)
        , 'by_antenna', json(by_antenna)
        , 'by_standard', json(by_standard)) as attach
	from TOP_TIME_APP, TOP_TX_APP, TOP_RX_APP, BY_ANTENNA, BY_STANDARD
)

-----------------------------
insert into agg_wifi_agent_daily
select 0 as upload, PARAM_VAR.var_date as date, PARAM_VAR.var_start_ts as start_ts, PARAM_VAR.var_end_ts as end_ts
    , EG_TBL.energy
	, TOP_APP_BY_MODE_TBL.top_app_by_mode
	, ATTACHMENT.attach as attach
	, PARAM_VAR.var_version as version
from PARAM_VAR, TOP_APP_BY_MODE_TBL, EG_TBL, ATTACHMENT;