INSERT INTO agg_wifi_agent_app_hourly
SELECT
  {} AS start_ts,
  {} AS end_ts,
  sum(tx_time + rx_time) AS busy_du,
  sum(time_delta) AS total_du,
  app,
  screen_mode,
  power_mode,
  thermal_mode,
  ground_mode,
  {} AS wifi_id,
  enable,
  hotspot,
  frequency_band,
  standard,
  band_width,
  antenna,
  uid,
  package_name,
  SUM(tx_byte) AS tx_byte,
  SUM(rx_byte) AS rx_byte,
  SUM(tx_time) AS tx_time,
  SUM(rx_time) AS rx_time,
  SUM(idle_time) AS idle_time,
  SUM(tx_packet) AS tx_packet,
  SUM(rx_packet) AS rx_packet,
  SUM(total_eg) AS total_eg
FROM comp_wifi_agent_intv
WHERE start_ts >= {} AND end_ts <= {} AND wifi_id = {}
    and screen_mode != -1
    and power_mode != -1
    and thermal_mode != -1
    and ground_mode != -1
GROUP BY app, power_mode, screen_mode, thermal_mode, ground_mode, wifi_id, enable, hotspot, frequency_band, standard,
band_width, antenna, uid, package_name