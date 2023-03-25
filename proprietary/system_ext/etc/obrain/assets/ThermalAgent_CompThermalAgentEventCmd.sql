INSERT INTO comp_thermalAgent_statis
SELECT
'tz0' as zone_name,
%llu AS start_ts,
%llu AS end_ts,
fg_app,
battery_current,
sum(case when tz0 <= 25000 then 1 else 0 end) * 10,
sum(case when tz0 > 25000 and tz0 <= 30000 then 1 else 0 end) * 10,
sum(case when tz0 > 30000 and tz0 <= 35000 then 1 else 0 end) * 10,
sum(case when tz0 > 35000 and tz0 <= 40000 then 1 else 0 end) * 10,
sum(case when tz0 > 40000 and tz0 <= 45000 then 1 else 0 end) * 10,
sum(case when tz0 > 45000 then 1 else 0 end) * 10
FROM raw_thermalAgent_temp
where time > %llu AND time <= %llu
GROUP BY end_ts
union
SELECT
'tz1' as zone_name,
%llu AS start_ts,
%llu AS end_ts,
fg_app,
battery_current,
sum(case when tz1 <= 25000 then 1 else 0 end) * 10,
sum(case when tz1 > 25000 and tz1 <= 30000 then 1 else 0 end) * 10,
sum(case when tz1 > 30000 and tz1 <= 35000 then 1 else 0 end) * 10,
sum(case when tz1 > 35000 and tz1 <= 40000 then 1 else 0 end) * 10,
sum(case when tz1 > 40000 and tz1 <= 45000 then 1 else 0 end) * 10,
sum(case when tz1 > 45000 then 1 else 0 end) * 10
FROM raw_thermalAgent_temp
where time > %llu AND time <= %llu
GROUP BY end_ts
union
SELECT
'tz2' as zone_name,
%llu AS start_ts,
%llu AS end_ts,
fg_app,
battery_current,
sum(case when tz2 <= 25000 then 1 else 0 end) * 10,
sum(case when tz2 > 25000 and tz2 <= 30000 then 1 else 0 end) * 10,
sum(case when tz2 > 30000 and tz2 <= 35000 then 1 else 0 end) * 10,
sum(case when tz2 > 35000 and tz2 <= 40000 then 1 else 0 end) * 10,
sum(case when tz2 > 40000 and tz2 <= 45000 then 1 else 0 end) * 10,
sum(case when tz2 > 45000 then 1 else 0 end) * 10
FROM raw_thermalAgent_temp
where time > %llu AND time <= %llu
GROUP BY end_ts
union
SELECT
'tz3' as zone_name,
%llu AS start_ts,
%llu AS end_ts,
fg_app,
battery_current,
sum(case when tz3 <= 25000 then 1 else 0 end) * 10,
sum(case when tz3 > 25000 and tz3 <= 30000 then 1 else 0 end) * 10,
sum(case when tz3 > 30000 and tz3 <= 35000 then 1 else 0 end) * 10,
sum(case when tz3 > 35000 and tz3 <= 40000 then 1 else 0 end) * 10,
sum(case when tz3 > 40000 and tz3 <= 45000 then 1 else 0 end) * 10,
sum(case when tz3 > 45000 then 1 else 0 end)
FROM raw_thermalAgent_temp
where time > %llu AND time <= %llu
GROUP BY end_ts
union
SELECT
'tz4' as zone_name,
%llu AS start_ts,
%llu AS end_ts,
fg_app,
battery_current,
sum(case when tz4 <= 25000 then 1 else 0 end) * 10,
sum(case when tz4 > 25000 and tz1 <= 30000 then 1 else 0 end) * 10,
sum(case when tz4 > 30000 and tz1 <= 35000 then 1 else 0 end) * 10,
sum(case when tz4 > 35000 and tz1 <= 40000 then 1 else 0 end) * 10,
sum(case when tz4 > 40000 and tz1 <= 45000 then 1 else 0 end) * 10,
sum(case when tz4 > 45000 then 1 else 0 end) * 10
FROM raw_thermalAgent_temp
where time > %llu AND time <= %llu
GROUP BY end_ts
union
SELECT
'tz5' as zone_name,
%llu AS start_ts,
%llu AS end_ts,
fg_app,
battery_current,
sum(case when tz5 <= 25000 then 1 else 0 end) * 10,
sum(case when tz5 > 25000 and tz5 <= 30000 then 1 else 0 end) * 10,
sum(case when tz5 > 30000 and tz5 <= 35000 then 1 else 0 end) * 10,
sum(case when tz5 > 35000 and tz5 <= 40000 then 1 else 0 end) * 10,
sum(case when tz5 > 40000 and tz5 <= 45000 then 1 else 0 end) * 10,
sum(case when tz5 > 45000 then 1 else 0 end) * 10
FROM raw_thermalAgent_temp
where time > %llu AND time <= %llu
GROUP BY end_ts
union
SELECT
'tz6' as zone_name,
%llu AS start_ts,
%llu AS end_ts,
fg_app,
battery_current,
sum(case when tz6 <= 25000 then 1 else 0 end) * 10,
sum(case when tz6 > 25000 and tz6 <= 30000 then 1 else 0 end) * 10,
sum(case when tz6 > 30000 and tz6 <= 35000 then 1 else 0 end) * 10,
sum(case when tz6 > 35000 and tz6 <= 40000 then 1 else 0 end) * 10,
sum(case when tz6 > 40000 and tz6 <= 45000 then 1 else 0 end) * 10,
sum(case when tz6 > 45000 then 1 else 0 end) * 10
FROM raw_thermalAgent_temp
where time > %llu AND time <= %llu
GROUP BY end_ts
union
SELECT
'tz7' as zone_name,
%llu AS start_ts,
%llu AS end_ts,
fg_app,
battery_current,
sum(case when tz7 <= 25000 then 1 else 0 end) * 10,
sum(case when tz7 > 25000 and tz7 <= 30000 then 1 else 0 end) * 10,
sum(case when tz7 > 30000 and tz7 <= 35000 then 1 else 0 end) * 10,
sum(case when tz7 > 35000 and tz7 <= 40000 then 1 else 0 end) * 10,
sum(case when tz7 > 40000 and tz7 <= 45000 then 1 else 0 end) * 10,
sum(case when tz7 > 45000 then 1 else 0 end) * 10
FROM raw_thermalAgent_temp
where time > %llu AND time <= %llu
GROUP BY end_ts