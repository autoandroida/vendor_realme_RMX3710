INSERT INTO {}
  SELECT
       0 AS [upload],
       {} AS [date],
       {} AS [start_ts],
       {} AS [end_ts],
       [CNT_TBL].[count],
       [TOP_APP_BY_MODE_TBL].[top_app] AS [top_app_by_mode],
       [TOP_APP_BY_EG_TBL].[top_app] AS [top_app_by_energy],
       {} AS [version]
FROM   (SELECT '[' || GROUP_CONCAT ([oneline]) || ']' AS [count]
        FROM   (SELECT '{{"screen_mode":' || [screen_mode] || ', "power_mode":' || [power_mode] || ',"thermal_mode":' || [thermal_mode] || ',"subsystem_name":' || [subsystem_name] || ', "total_time":' || [total_time] || '}}' AS [oneline]
                FROM   (SELECT
                               [power_mode],
                               [screen_mode],
                               [thermal_mode],
                               [subsystem_name],
                               SUM ([sleep_duration]) AS [total_time]
                        FROM   [agg_subSystem_hourly]
                        WHERE  [start_ts] >= {} AND [end_ts] <= {}
                        GROUP  BY
                                  [power_mode],
                                  [screen_mode],
                                  [thermal_mode],
                                  [subsystem_name]))) CNT_TBL,
       (SELECT '[' || GROUP_CONCAT ([oneline]) || ']' AS [top_app]
        FROM   (SELECT '{{"subsystem_name":"' || [subsystem_name] || '","screen_mode":' || [screen_mode] || ',"power_mode":' || [power_mode] || ',"thermal_mode":' || [thermal_mode] || ',"idx":' || [idx] || ',"total_time":' || [total_time] || '}}' AS [oneline]
                FROM   (SELECT
                               [subsystem_name],
                               [screen_mode],
                               [power_mode],
                               [thermal_mode],
                               SUM ([sleep_duration]) AS [total_time],
                               [idx]
                        FROM   (SELECT
                                       [T1].[subsystem_name],
                                       [T1].[screen_mode],
                                       [T1].[power_mode],
                                       [T1].[thermal_mode],
                                       [T1].[sleep_duration],
                                       [T2].[idx]
                                FROM   [agg_subSystem_hourly] [T1]
                                       INNER JOIN (SELECT *
                                        FROM   (SELECT
                                                       [subsystem_name],
                                                       [screen_mode],
                                                       [power_mode],
                                                       [thermal_mode],
                                                       SUM ([sleep_duration]) AS [total_time],
                                                       ROW_NUMBER () OVER (PARTITION BY [screen_mode], [power_mode], [thermal_mode] ORDER BY SUM ([sleep_duration]) desc) AS [idx]
                                                FROM   [agg_subSystem_hourly]
                                                WHERE  [start_ts] >= {} AND [end_ts] <= {}
                                                GROUP  BY
                                                          [subsystem_name],
                                                          [screen_mode],
                                                          [power_mode],
                                                          [thermal_mode])
                                        WHERE  [idx] <= 10) T2 ON [T1].[subsystem_name] = [T2].[subsystem_name]
                                            AND [T1].[screen_mode] = [T2].[screen_mode]
                                            AND [T1].[power_mode] = [T2].[power_mode]
                                            AND [T1].[thermal_mode] = [T2].[thermal_mode]
                                WHERE  [start_ts] >= {} AND [end_ts] <= {})
                        GROUP  BY
                                  [subsystem_name],
                                  [screen_mode],
                                  [power_mode],
                                  [thermal_mode]))) TOP_APP_BY_MODE_TBL,
       (SELECT '[' || GROUP_CONCAT ([oneline]) || ']' AS [top_app]
        FROM   (SELECT '{{"subsystem_name":"' || [subsystem_name] || '","screen_mode":' || [screen_mode] || ',"power_mode":' || [power_mode] || ',"thermal_mode":' || [thermal_mode] || '","idx":' || [idx] || ',"total_time":' || [total_time] || '}}' AS [oneline]
                FROM   (SELECT
                               [subsystem_name],
                               [screen_mode],
                               [power_mode],
                               [thermal_mode],
                               SUM ([sleep_duration]) AS [total_time],
                               [idx]
                        FROM   (SELECT *
                                FROM   [agg_subSystem_hourly] [T1]
                                       INNER JOIN (SELECT *
                                        FROM   (SELECT
                                                       [subsystem_name],
                                                       SUM ([sleep_duration]) AS [total_time],
                                                       ROW_NUMBER () OVER (ORDER BY SUM ([sleep_duration]) desc) AS [idx]
                                                FROM   [agg_subSystem_hourly]
                                                WHERE  [start_ts] >= {} AND [end_ts] <= {}
                                                GROUP  BY [subsystem_name])
                                        WHERE  [idx] <= 10) T2 ON [T1].[subsystem_name] = [T2].[subsystem_name]
                                WHERE  [start_ts] >= {} AND [end_ts] <= {})
                        GROUP  BY
                                  [subsystem_name],
                                  [screen_mode],
                                  [power_mode],
                                  [thermal_mode]))) TOP_APP_BY_EG_TBL;

