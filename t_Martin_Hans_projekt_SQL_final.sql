
---- parciální tabulky --

create table covid19_tests_final
select 
    ct.date,
	lt.country,
    ct.tests_performed  
from lookup_table lt
join covid19_tests ct 
on lt.iso3=ct.ISO
group by date, country
order by date, country;

create table covid19_countries
select 
   distinct (lt.country),
    c.capital_city,
    c.median_age_2018,
    c.population_density 
from lookup_table lt
join countries c 
on lt.iso3=c.iso3;

create table covid19_info as
select 
  cbd.date,
  cbd.country,
  cbd.confirmed,
  case when weekday(cbd.date) in (5,6) then 1 else 0 end as weekend,
  case 
    when cbd.date < '2020-03-20' then 3
    when cbd.date >= '2020-03-20' then 0
    when cbd.date >= '2020-06-21' then 1
    when cbd.date >= '2020-09-22' then 2
    when cbd.date >= '2020-12-21' then 3
    else 0 end as period,
  ctf.tests_performed,
  round(cc.population_density,2) as population_density,
  cc.median_age_2018
from covid19_basic_differences cbd
left join covid19_tests_final ctf on
cbd.date=ctf.`date`
and cbd.country=ctf.country
left join covid19_countries cc on cbd.country=cc.country
order by date, country;

create table covid19_economies as
select 
   e.country,
   round (a.GDP/a.population, 2) as gdp_per_capita,
   round (avg(e.gini), 2) as gini_coeficient,
   round (avg(e.mortaliy_under5), 2) as child_mortality
from economies e
join (
select country, GDP, population 
from economies e2
where year=2020 group by country) a on a.country=e.country
group by e.country;

create table covid19_religion_rel_share
SELECT r.country , r.religion , 
    round( r.population / r2.total_population_2020 * 100, 2 ) as religion_share_2020
FROM religions r 
JOIN (
        SELECT r.country , r.year,  sum(r.population) as total_population_2020
        FROM religions r 
        WHERE r.year = 2020 and r.country != 'All Countries'
        GROUP BY r.country
    ) r2
    ON r.country = r2.country
    AND r.year = r2.year
    AND r.population > 0;
 
create table covid19_religions_pivot as   
 (select
    country,
    case when religion = "Buddhism" then religion_share_2020 end as Buddhism,
    case when religion = "Christianity" then religion_share_2020 end as Christianity,
    case when religion = "Folk Religions" then religion_share_2020 end as Folk_Religions,
    case when religion = "Hinduism" then religion_share_2020 end as Hinduism,
    case when religion = "Islam" then religion_share_2020 end as Islam,
    case when religion = "Judaism" then religion_share_2020 end as Judaism,
    case when religion = "Other Religions" then religion_share_2020 end as Other_Religions,
    case when religion = "Unaffiliated Religions" then religion_share_2020 end as Unaffiliated_Religions
 from covid19_country_rel_share);

create table covid19_religions_pivot2 as
(select 
  country,
  sum(Buddhism) as Buddhism,
  sum(Christianity) as Christianity,
  sum(Folk_Religions) as Folk_Religions,
  sum(Hinduism) as Hinduism,
  sum(Islam) as Islam,
  sum(Judaism) as Judaism,
  sum(Other_Religions) as Other_Religions,
  sum(Unaffiliated_Religions) as Unaffiliated_Religions 
from covid19_religions
group by country);

create table covid19_religions_pivot_final as
   (select
   country,
   coalesce (Buddhism, 0) as Buddhism,
   coalesce (Christianity, 0) as Christianity,
   coalesce (Folk_Religions, 0) as Folk_Religions,
   coalesce (Hinduism, 0) as Hinduism,
   coalesce (Islam, 0) as Islam,
   coalesce (Judaism, 0) as Judaism,
   coalesce (Other_Religions, 0) as Other_Religions,
   coalesce (Unaffiliated_Religions, 0) as Unaffiliated_Religions
from v_religions_pivot vrp
group by country);
    
create table covid19_life_expectancy as
SELECT a.country,
    round( b.life_exp_2015 - a.life_exp_1965, 2 ) as life_exp_diff_2015_1965
FROM (
    SELECT le.country , le.life_expectancy as life_exp_1965
    FROM life_expectancy le 
    WHERE year = 1965
    ) a JOIN (
    SELECT le.country , le.life_expectancy as life_exp_2015
    FROM life_expectancy le 
    WHERE year = 2015
    ) b
    ON a.country = b.country;

create table covid19_temp_wind_convert as
select
  w.city,
  w.date,
  w.time,
  cast(w2.temp as decimal) as temp, 
  cast(w2.wind as decimal) as wind
from weather w
join (select 
  date, 
  city,
  time,
  replace (temp,'°c',' ') as temp,
  substring (wind,1,2) as wind
from weather) w2
on w.city=w2.city 
and w.date=w2.date
and w.time=w2.time
where w.city is not null 
group by w.city,w.date, w.time;

create table covid19_temp_final as
select
	ctwc.date,
	cc.country,
	round (avg (ctwc.temp),2) as avg_temp
from covid19_temper_wind_convert ctwc 
join covid19_countries cc 
on cc.capital_city=ctwc.city
where city is not null and ctwc.time between '09:00' and '18:00'
group by ctwc.date, cc.country;

create table covid19_wind_final as
select
	ctwc.date,
	cc.country,
	max (ctwc.wind) as max_wind
from covid19_temper_wind_convert ctwc
join covid19_countries cc 
on cc.capital_city=ctwc.city
where ctwc.city is not null 
group by ctwc.date, cc.country;

CREATE TABLE covid19_hours_rain_conversion
select 
	`date`, 
	city, 
	case when rain != '0.0 mm' then 3 else 0 end as hours_rain 
from weather w
where city is not null
group by date,city, time;

create table covid19_hours_rain_final
select 
    chrc.date, 
    c.country,
    sum (chrc.hours_rain) as hours_rain
from countries c 
join covid19_hours_rain_conversion chrc 
on c.capital_city=chrc.city 
group by chrc.date, c.country;

---- finální skript --

create table t_Martin_Hans_projekt_SQL_final
select 
	ci.country,
	ci.date,
	ci.confirmed,
	ci.weekend,
	ci.period,
	ci.tests_performed,
	ci.population_density,
	ci.median_age_2018, 
	ce.gdp_per_capita,
	ce.gini_coeficient,
	ce.child_mortality,
	crpf.Buddhism,
	crpf.Christianity,
	crpf.Folk_Religions,
	crpf.Hinduism,
	crpf.Islam,
	crpf.Judaism,
	crpf.Other_Religions,
	crpf.Unaffiliated_Religions,
	cle.life_exp_diff_2015_1965,
	ctf.avg_temp,
	chrf.hours_rain,
	cwf.max_wind
from covid19_info ci
left join covid19_economies ce 
on ci.country=ce.country
left join covid19_religions_pivot_final crpf 
on crpf.country=ci.country
left join covid19_life_expectancy cle
on ci.country=cle.country
left join covid19_temp_final ctf
on ci.country=ctf.country and 
ci.date=ctf.date
left join covid19_hours_rain_final chrf 
on ci.country=chrf.country and 
ci.date=chrf.date
left join covid19_wind_final cwf 
on ci.country=cwf.country and 
ci.date=cwf.date
group by ci.country, ci.date
order by ci.date, ci.country;

