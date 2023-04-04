INSERT INTO {}
  SELECT
       {} AS [start_ts],
       {} AS [end_ts],
       [power_mode],
       [screen_mode],
       [thermal_mode],
       [subsystem_name],
       SUM ([sleep_duration])
FROM   [comp_table_subsystem_backward]
WHERE  [start_ts] >= {}
         AND [end_ts] <= {}
         AND [power_mode] = 0
         AND [screen_mode] = 0
         AND [thermal_mode] != - 1
GROUP  BY
          [power_mode],
          [screen_mode],
          [thermal_mode],
          [subsystem_name];