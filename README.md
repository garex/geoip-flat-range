# GeoIP flat range

Are you still using something like this in your SQL or similar?

```sql
select country_code from countries_ips where
inet_aton('123.123.123.123') between range_start and range_end limit 1
```

Let's try new way:

```sql
select country_code from countries_ips_flat where
inet_aton('123.123.123.123') >= range_start order by range_start limit 1
```

## You are welcome

* To create more universal load code
* To improve transformation code or provide it for different DBMS
* To create something NoSQL but with similar conception
* To provide some native tools, that will do the same

## Credit
> &copy; Copyright 2012, [Alexander Ustimenko] ( http://vkontakte.ru/ustimenko_alexander )