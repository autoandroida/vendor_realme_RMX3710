select name, group_concat(tgid, '->') as tgid
	, count(*) as cnt
from (
	select distinct name, tgid
	from comp_uidstate_cpuagent_backward
	where tgid = pid
		and tgid != -1
	order by name
)
group by name
having cnt > 1
and name not like 'kworker%'
and name not like 'irq/%'
and name not like 'sleep@%'
and name not like 'sh@%'
and name not like 'logcat@%'
and name not like 'autochmod.sh%'
and name not like 'date@%'
and name not like 'cat@%'
and name not like 'top@%'
and name not like 'getprop@%'
and name not like 'setprop@%'
and name not like 'dumpsys@%'
and name not like 'mkdir@%'
and name not like 'awk@%'
and name not like 'cp@%'
and name not like 'wc@%'
and name not like 'rm@%'
and name not like 'grep@%'
and name not like 'mv@%'
and name not like 'du@%'
and name not like 'chmod@%'
and name not like 'mv@%'
and name not like 'chown@%'
and name not like 'ps@%'
and name not like 'tar@%'
and name not like 'ls@%'
and name not like 'ping@%'
order by cnt desc;