-- From simple explains we can see, that flat range method is better, than plain old range method
explain
select country_code from countries_ips where inet_aton('123.123.123.123') between range_start and range_end limit 1;
explain
select country_code from countries_ips_flat where inet_aton('123.123.123.123') >= range_start order by range_start desc limit 1;

-- Let's profile a little :)
-- On my home machine (WinXP, 2.8Ghz, 1.5Gb) it gives stable results in ~4 times better -- see last two results from queries below

-- Preparing...
flush status;
flush tables;
set session query_cache_type = off;
set session profiling_history_size = 2;
set session profiling = 1;

-- Actual queries
select country_code from countries_ips where inet_aton('123.123.123.123') between range_start and range_end limit 1;
select country_code from countries_ips_flat where inet_aton('123.123.123.123') >= range_start order by range_start desc limit 1;

-- Turn off profiling and let's see results
set session profiling = 0;
set @queries_count = 2;

set @min_query_id = (select min(QUERY_ID) from information_schema.PROFILING);

drop table if exists profile;
create table profile
select
	@query_run_number := QUERY_ID-@min_query_id+1				as query_run_number,
	@query_number_mod := mod(@query_run_number, @queries_count)	as query_number_mod,
	if(0=@query_number_mod, @queries_count, @query_number_mod)	as query_number,
	SEQ															as step_number,
	STATE														as step_name,
	DURATION*1000												as duration_ms
from
	information_schema.PROFILING;

select
	query_number, format(avg(total_ms), 4) as average_ms
from
	(select query_number, query_run_number, sum(duration_ms) total_ms from profile group by query_number, query_run_number) inn
group by query_number;

select
	query_number, concat(step_number, ': ', step_name) as step, format(avg(duration_ms), 4) as average_ms
from profile
group by query_number, step_number, step_name;

drop table if exists profile;

-- Also let's compare key reads: 6608 vs. 9
flush tables;
flush status;
select country_code from countries_ips where inet_aton('123.123.123.123') between range_start and range_end limit 1;
show status like 'Key_read_requests';
flush status;
select country_code from countries_ips_flat where inet_aton('123.123.123.123') >= range_start order by range_start desc limit 1;
show status like 'Key_read_requests';