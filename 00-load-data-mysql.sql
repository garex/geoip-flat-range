drop database if exists geoip_flat_range;
create database geoip_flat_range;
use geoip_flat_range;

create table countries_ips (
	ip_start char(15) not null default '0.0.0.0',
	ip_end char(15) not null default '0.0.0.0',
	range_start int unsigned not null default 0,
	range_end int unsigned not null default 0,
	country_code char(2) not null default '',
	primary key (range_start, range_end, country_code)
) engine=MyISAM;

/**
 * @see http://www.maxmind.com/app/geoip_country
 * Change to your local path
 */
load data infile 'D:\\Docs\\Private\\Publication\\GeoIP\\geoip-flat-range\\GeoIPCountryWhois.csv'
into table countries_ips columns terminated by ',' enclosed by '"';

alter table countries_ips
	drop column ip_start,
	drop column ip_end;

select * from countries_ips limit 10;