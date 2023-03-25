with
PARAM_VAR as (
    select
        {} as var_date,
        {} as var_version,
        {} as var_start_ts,
        {} as var_end_ts
)
insert into agg_cameraAgent_daily
-- energy table
select 0 as upload, PARAM_VAR.var_date as date, PARAM_VAR.var_start_ts, PARAM_VAR.var_end_ts, EG_TBL.energy
	, TOP_APP_BY_MODE_TBL.top_app as top_app_by_mode, TOP_APP_BY_EG_TBL.top_app as top_app_by_energy, EXPLORER_TBL.explorer as explorer, PARAM_VAR.var_version as version
from (
	select json_group_array(oneline) as energy
	from (
		select json_object('screen_mode', screen_mode, 'ground_mode', ground_mode, 'power_mode'
		, power_mode, 'thermal_mode', thermal_mode, 'camera_number', camera_number
		, 'fps', fps, 'camera_Id', camera_Id, 'resolution', resolution, 'camera_eg'
		, camera_eg, 'laser_eg', laser_eg,'osi_eg', osi_eg,'motor_eg', motor_eg
		,'total_du', duration) as oneline
		from (
			-- -- total duration and energy for each mode
			select screen_mode, ground_mode, power_mode, thermal_mode, camera_number, fps,  camera_Id, resolution
				  , sum(total_du) as duration, sum(camera_eg) as camera_eg, sum(laser_eg) as laser_eg
                  ,sum(osi_eg) as osi_eg, sum(motor_eg) as motor_eg
			from agg_camera_app_hourly, PARAM_VAR
			where start_ts >= PARAM_VAR.var_start_ts and end_ts < PARAM_VAR.var_end_ts
			group by ground_mode, screen_mode, power_mode, thermal_mode, camera_number, fps, camera_Id, resolution
		)
		group by screen_mode, ground_mode, power_mode, thermal_mode, camera_number, fps, camera_Id, resolution
	)
) EG_TBL, (
		select json_group_array(oneline) as top_app
		from (
			select json_object('camera_app', obfuscate(camera_app), 'screen_mode', screen_mode
			, 'ground_mode', ground_mode, 'power_mode', power_mode, 'thermal_mode'
			, thermal_mode, 'camera_number', camera_number, 'fps', fps, 'camera_Id'
			, camera_Id, 'resolution', resolution, 'idx', idx, 'duration'
			, duration, 'camera_eg', camera_eg, 'laser_eg'
           , laser_eg,'osi_eg', osi_eg,'motor_eg', motor_eg) as oneline
			from (
				select camera_app, screen_mode, ground_mode, power_mode, thermal_mode
					, camera_number, fps, camera_Id, resolution, sum(duration) as duration , sum(camera_eg) as camera_eg, sum(laser_eg) as laser_eg
                       ,sum(osi_eg) as osi_eg, sum(motor_eg) as motor_eg, idx
				from (
					select T1.camera_app, T1.camera_number, T1.fps, T1.camera_Id, T1.resolution, T1.screen_mode, T1.ground_mode, T1.power_mode, T1.thermal_mode
						, total_du as duration, T1.camera_eg as camera_eg, T1.laser_eg as laser_eg, T1.osi_eg as osi_eg, T1.motor_eg as motor_eg,T2.idx
					from PARAM_VAR, agg_camera_app_hourly T1
						inner join (
							select *
							from (
								-- add idx for each partition
								select camera_app, screen_mode, ground_mode, power_mode, thermal_mode
									, sum(camera_eg) as camera_eg, sum(laser_eg) as laser_eg,sum(osi_eg) as osi_eg,
									sum(motor_eg) as motor_eg, row_number() over (partition by screen_mode, ground_mode,
									power_mode, thermal_mode order by sum(camera_eg) ,sum(laser_eg),sum(osi_eg),sum(motor_eg) desc) as idx
								from agg_camera_app_hourly, PARAM_VAR
								where start_ts >= PARAM_VAR.var_start_ts and end_ts < PARAM_VAR.var_end_ts
								group by camera_app, ground_mode, screen_mode, power_mode, thermal_mode
							)
							where idx <= 10
						) T2
						on T1.camera_app = T2.camera_app
							and T1.ground_mode = T2.ground_mode
							and T1.screen_mode = T2.screen_mode
							and T1.power_mode = T2.power_mode
							and T1.thermal_mode = T2.thermal_mode
						where start_ts >= PARAM_VAR.var_start_ts and end_ts < PARAM_VAR.var_end_ts
				)
				group by camera_app, screen_mode, ground_mode, power_mode, thermal_mode, camera_number, fps, camera_Id, resolution
			)
		)
	) TOP_APP_BY_MODE_TBL, (
		select json_group_array(oneline) as top_app
		from (
			select json_object('camera_app', obfuscate(camera_app), 'screen_mode', screen_mode
			, 'ground_mode', ground_mode, 'power_mode', power_mode, 'thermal_mode'
			, thermal_mode, 'camera_number', camera_number, 'fps', fps, 'camera_Id'
			, camera_Id, 'resolution', resolution, 'idx', idx, 'duration'
			, duration, 'camera_eg', camera_eg, 'laser_eg', laser_eg,'osi_eg'
			, osi_eg,'motor_eg', motor_eg) as oneline
			from (
				select camera_app, screen_mode, ground_mode, power_mode, thermal_mode
					, camera_number, fps, camera_Id, resolution, sum(total_du) as duration, sum(camera_eg) as camera_eg,
					sum(laser_eg) as laser_eg,sum(osi_eg) as osi_eg, sum(motor_eg) as motor_eg
					, idx
				from (
					select *
					from PARAM_VAR, agg_camera_app_hourly T1
						inner join (
							select *
							from (
								-- get top app by energy and add idx
								select camera_app,  sum(camera_eg) as camera_eg, sum(laser_eg) as laser_eg,sum(osi_eg) as osi_eg, sum(motor_eg) as motor_eg, row_number() over (order by sum(camera_eg) ,sum(laser_eg),sum(osi_eg),sum(motor_eg) desc) as idx
								from agg_camera_app_hourly, PARAM_VAR
								where start_ts >= PARAM_VAR.var_start_ts and end_ts < PARAM_VAR.var_end_ts
								group by camera_app
							)
							where idx <= 10
						) T2
						on T1.camera_app = T2.camera_app
						where start_ts >= PARAM_VAR.var_start_ts and end_ts < PARAM_VAR.var_end_ts
				)
				group by camera_app, screen_mode, ground_mode, power_mode, thermal_mode, camera_number,
				fps, camera_Id, resolution
			)
		)
	) TOP_APP_BY_EG_TBL, (
        select json_group_array(oneline) as explorer
        from (
            select json_object('operationMode', operationMode, 'explorer_start_ts', explorer_start_ts, 'explorer_end_ts', explorer_end_ts
               , 'moduleId', moduleId, 'majorType', majorType, 'minorType', minorType
               , 'level', level, 'action', action, 'RunTimes', json_array(HDRRunTimes, AINRRunTimes, HDR_AINRRunTimes
               , OtherModeRuntimes),'Duration', json_array(HDRDuration, AINRDuration, HDR_AINRDuration, OtherModeDuration)
               , 'sensorDur', json_array(VectorI('sensorDur_$0', sensorDurList)), 'DDRTemp', json_array(DDRTemp_0
               , DDRTemp_1), 'NPUTemp', json_array(NPUTemp_0, NPUTemp_1), 'ISPTemp', json_array(ISPTemp_0
               , ISPTemp_1), 'MAXCPUTemp', json_array(MAXCPUTemp_0, MAXCPUTemp_1), 'surfaceTemp'
               , json_array(surfaceTemp_0, surfaceTemp_1)) as oneline
            from comp_cameraAgent_explorer, PARAM_VAR
            where start_ts >= PARAM_VAR.var_start_ts and end_ts < PARAM_VAR.var_end_ts and moduleId != 0
                and power_mode != -1
                and screen_mode != -1
                and thermal_mode != -1
                and ground_mode != -1
            limit 10
        )
    ) EXPLORER_TBL, PARAM_VAR
