select 
  date,
  country,
  confirmed,
  case when weekday(date) in (5,6) then 1 else 0 end as weekend,
  case 
    when date < '2020-03-20' then 3
    when date >= '2020-03-20' then 0
    when date >= '2020-06-21' then 1
    when date >= '2020-09-22' then 2
    when date >= '2020-12-21' then 3
    else 0 end as period
from covid19_basic_differences cbd;

select 
   country,
   population_density,
   median_age_2018
from countries c;

select 
   country,
   round (GDP/population, 2) as gdp_per_capita,
   gini as gini_coeficient,
   mortaliy_under5 as child_mortality
from economies e 
where year=2020;

select 
   r.year,
   r.country,
   r.religion,
   round (r.population/c.population *100,3) as religion_pop_share 
from religions r, countries c 
where r.country=c.country 
and r.year=2020;

create table t_country_rel_share
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
 
create view v_religions as   
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
 from t_country_rel_share tcrs);

create view v_religions_pivot as
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
from v_religions vr
group by country);

create view v_religions_pivot_final as
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
   
   
     SELECT a.country, round (a.Christianity, 2) as christianity , round (b.Islam, 2) as Islam 
FROM (
    SELECT tcrs.country , tcrs.religion_share_2020 as christianity
    FROM t_country_rel_share tcrs 
    WHERE religion = 'Christianity'
    ) a JOIN (
    SELECT tcrs.country , tcrs.religion_share_2020 as islam
    FROM t_country_rel_share tcrs 
    WHERE religion = 'Islam'
    ) b
    ON a.country = b.country
;
    
    SELECT a.country, round (a.life_exp_1965, 2) as life_exp_1965 , round (b.life_exp_2015, 2) as life_exp_2015,
    round( b.life_exp_2015 - a.life_exp_1965, 2 ) as life_exp_diff
FROM (
    SELECT le.country , le.life_expectancy as life_exp_1965
    FROM life_expectancy le 
    WHERE year = 1965
    ) a JOIN (
    SELECT le.country , le.life_expectancy as life_exp_2015
    FROM life_expectancy le 
    WHERE year = 2015
    ) b
    ON a.country = b.country
;

select 
	w.date,
	c.country,
	w.city,
	w2.avg_temp
from weather w 
join countries c 
on w.city=c.capital_city
join (select `date`, city, round (avg(temp),2) as avg_temp
	  from weather w
	  where time between '09:00' and '18:00'
	  group by date, city) w2
	  on w2.city=w.city 
	  and w2.date=w.`date` 
group by w.date	  
order by w.`date`;

select 
    w.date,
    c.country,
    w.city,
    sum (w2.hours_rain)
    from weather w 
join countries c 
 on w.city=c.capital_city 
join (select `date`, city, case when rain != '0.0 mm' then 3 else 0 end as hours_rain 
       from weather w
       where city is not null
       group by date,city,time) w2
       on w2.city=c.capital_city
       and w2.date=w.`date` 
 group by w2.`date` 
 order by w2.`date`; 

select 
	w.date,
	c.country,
	w.city,
	w2.max_wind
from weather w 
join countries c 
on w.city=c.capital_city
join (select `date`, city, round (max(wind),2) as max_wind
	  from weather w 
	  group by date, city) w2
	  on w2.city=w.city 
	  and w2.date=w.`date`
group by w.date	  
order by w.`date`;


CREATE TABLE t_hours_rain AS
select `date`, city, case when rain != '0.0 mm' then 3 else 0 end as hours_rain 
       from weather w
       where city is not null
       group by date,city,time;

select 
    thr.date, 
    c.country,
    sum (thr.hours_rain)
from countries c 
join t_hours_rain thr 
on c.capital_city=thr.city 
group by thr.date, c.country;
     
select `date`, city, sum (hours_rain) 
       from t_hours_rain thr 
       where city is not null
       group by date,city;
            
select 
    w.date,
    c.country,
    w.city,
    sum (w2.hours_rain)
    from weather w 
join countries c 
 on w.city=c.capital_city 
join (select `date`, city, case when rain != '0.0 mm' then 3 else 0 end as hours_rain 
       from weather w
       where city is not null
       group by date,city,time) w2
       on w2.city=c.capital_city
       and w2.date=w.`date` 
 group by w2.`date` 
 order by w2.`date`; 

SELECT c.country, c.date, c.confirmed , lt.iso3 , c2.capital_city , w.max_temp
FROM covid19_basic as c
JOIN lookup_table lt 
    on c.country = lt.country 
    and c.country = 'Czechia'
    and month(c.date) = 10
JOIN countries c2
    on lt.iso3 = c2.iso3
JOIN (  SELECT w.city , w.date , max(w.temp) as max_temp
        FROM weather w 
        GROUP BY w.city, w.date) w
    on c2.capital_city = w.city 
    and c.date = w.date
ORDER BY c.date desc
;


