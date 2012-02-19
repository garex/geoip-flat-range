-- Create intermediate table with 3 columns
drop table if exists t3;
create table t3
select
	range_start f, range_end t, country_code v	-- Change this to your columns
	from countries_ips							-- and/or table
;
alter table t3 add primary key (f,t,v);

-- Create target table with 2 columns and fill it with all distinct ranges borders
drop table if exists t2;
create table t2
select distinct border as f, (select max(v) from t3) as v from (
	select f-1 as border from t3
	union select f from t3
	union select t from t3
	union select t+1 from t3
) inn
order by f;
-- Here we just reset value column as it was filled by max value to have auto created column with needed type
update t2 set v = null;

-- We can add PK here, as all our range borders are unique
alter table t2 add primary key(f);

-- Adding diff column, that will help us to order ranges during main update
alter table t3 add column diff int unsigned, add unique index dif_f(diff, f);
update t3 set diff = t-f;

-- Create helper table, that will help to smooth main update
drop table if exists t3diff;
create table t3diff
select distinct diff from t3 order by diff;

-- Here are our MAIN update
update t3diff, t2, t3 set t2.v = t3.v where t3.diff = t3diff.diff and t2.f between t3.f and t3.t;

-- We dont' need 'em anymore
drop table if exists t3;
drop table if exists t3diff;

-- We should remove records, that points to the same value and is one after another
alter table t2 drop primary key;
alter table t2 add column row_number int unsigned not null auto_increment primary key;
alter table t2 add column next_row_number int unsigned not null;
update t2 set next_row_number = row_number + 1;
alter table t2 add unique index next_row_number_v (next_row_number, v);

delete t2.* from t2, (
	select cur.row_number from t2 as cur
	join t2 prev on cur.row_number = prev.next_row_number and cur.v = prev.v	
) as inn
where t2.row_number = inn.row_number;

-- Also we dont' need first record
delete from t2 where row_number = 1;

-- Removing extra columns, that will not help us anymore
-- And also adding primary key on key and value to just always use index instead of table
alter table t2
	drop column row_number,
	drop column next_row_number,
	drop primary key,
	drop index next_row_number_v,
	add primary key (f, v)
;

-- ... And renaming target table to more human readable form
-- Change table`s/columns` names/definitions to your tables/columns
drop table if exists countries_ips_flat;
alter table t2
	rename to countries_ips_flat,
	change column f range_start int unsigned not null default 0 first,
	change column v country_code varchar(2) not null default '' after range_start;

-- Comparing records count and check, that's all is ok
select
	(select count(*) from countries_ips) as default_range_records,
	(select count(*) from countries_ips_flat) as flat_range_records;