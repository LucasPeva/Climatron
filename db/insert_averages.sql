/*
This is just a thingy i did to insert daily temp. and humid. averages directly in
Supabase, i probably should automate it using the API but eh whatever
*/
insert into public.daily_averages (date, avg_temperature, avg_humidity)
select 
    timestamp as date,
    avg(temperature) as avg_temperature,
    avg(humidity) as avg_humidity
from 
    public.readings
group by 
    timestamp
on conflict (date) do update set
    avg_temperature = excluded.avg_temperature,
    avg_humidity = excluded.avg_humidity;