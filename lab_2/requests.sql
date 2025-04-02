-- 1. Инструкция SELECT, использующая предикат сравнения
-- Выбрать пилотов побеждавших в гонках моложе 25 лет
select distinct name
from driver
         join pilots_results on driver.id = pilots_results.pilot_id
where now() - interval '25 year' <= birth_date
  and finish_position = 1;
-- 2. Инструкция SELECT, использующая предикат BETWEEN
-- Выбрать трассы для которых протяженность круга от 2 до 5 километров
select name, country
from track
where lap_length between 2.0 and 5.0;
-- 3. Инструкция SELECT, использующая предикат LIKE
-- Выбрать все городские трассы (содержат city в названии)
select name, country
from track
where name like '%City%';
-- 4. Инструкция SELECT, использующая предикат IN с вложенным подзапросом
-- Вывести всех пилотов из Аргентины набиравших хоть раз очки в гонках
select name
from driver
where id in (select pilot_id from pilots_results where points > 0)
  and country = 'Argentina';
-- 5. Инструкция SELECT, использующая предикат EXISTS с вложенным подзапросом
-- Вывести команды в которых были гонщики из России
select name
from team
where exists (select team_id
              from pilots_results
                       join driver on pilots_results.pilot_id = driver.id
                       join team on pilots_results.team_id = team.id
              where team.id = pilots_results.team_id
                and driver.country = 'Russian Federation');
-- 6. Инструкция SELECT, использующая предикат сравнения с квантором
-- Вывести гонщиков набиравших очки во всех гонках 1970 года в которых они принимали участие
with races_by_pilots_in_1970 as (select array_agg(points) points_all_races, pilot_id
                                 from race
                                          join pilots_results on race.id = pilots_results.race_id
                                 where date_part('year', race_date) = 1970
                                 group by pilot_id)
select driver.name
from driver
         join races_by_pilots_in_1970 as prep on driver.id = prep.pilot_id
where 0 < all (points_all_races);
-- 7. Инструкция SELECT, использующая агрегатные функции в выражениях столбцов
-- Вывести пилотов с наибольшим количеством очков в каждой стране
with prep as (select pilot_id as pilot_id, sum(points) as total_points
              from pilots_results
              group by pilot_id)
select driver.name, driver.country, prep.total_points
from prep
         join driver on prep.pilot_id = driver.id
where (prep.total_points, driver.country) in (select max(total_points), country
                                              from prep
                                                       join driver on driver.id = prep.pilot_id
                                              group by driver.country)
order by total_points desc;
-- 8. Инструкция SELECT, использующая скалярные подзапросы в выражениях столбцов
-- Вывести суммарное количество кругов для всех гонок в каждом чемпионате за все время
select championship.name,
       (select sum(race.total_laps) from race where race.championship_id = championship.id) as sum_laps,
       (select count(*) from race where race.championship_id = championship.id)             as total_races
from championship
order by total_races, sum_laps;
-- 9. Инструкция SELECT, использующая простое выражение CASE
-- Вывести для каждой гонки сезон: этого года, прошлого, сколько лет назад
select track.name,
       championship.name,
       race_date,
       case date_part('year', race_date)
           when date_part('year', now()) then 'This season'
           when date_part('year', now()) - 1 then 'Last season'
           else (date_part('year', now()) - date_part('year', race_date))::text || ' seasons ago'::text
           end as how_long
from race
         join track on race.track_id = track.id
         join championship on race.championship_id = championship.id;
-- 10. Вывести для каждой трассы : городская (содержит слов City) или нет
select name, case when name like ('%City%') then 'City track' else 'Not city track' end as is_city
from track;
-- 10. Инструкция SELECT, использующая поисковое выражение CASE
-- Вывести для каждой гонки: короткая - меньше 30 км, средняя до 500 км, длинная до 1500 км, очень длинная больше 1500
select track.name,
       championship.name,
       total_laps,
       track.lap_length,
       race_date,
       total_laps * track.lap_length as total_length,
       case
           when total_laps * lap_length <= 30 then 'Short'
           when total_laps * lap_length <= 500 then 'Medium'
           when total_laps * lap_length <= 1500 then 'Long'
           else 'Very long'
           end                       as how_long
from race
         join track on race.track_id = track.id
         join championship on race.championship_id = championship.id;
-- 11. Создание новой временной локальной таблицы из результирующего набора данных инструкции SELECT
-- Создать временную таблицу сходов с дистанции (кругов пройдено меньше, чем всего)
drop table if exists dnf;
create temp table dnf as
    (select driver.name       as pilot,
            race.race_date,
            championship.name as championshp,
            pilots_results.laps_passed,
            race.total_laps,
            track.name        as track
     from pilots_results
              join driver on pilots_results.pilot_id = driver.id
              join race on race.id = pilots_results.race_id
              join championship on race.championship_id = championship.id
              join track on race.track_id = track.id
     where laps_passed < race.total_laps);
select *
from dnf;
-- 12. Инструкция SELECT, использующая вложенные коррелированные подзапросы в качестве производных таблиц в предложении FROM
-- Для каждого пилота посчитать число сходов с дистанции (кругов пройдено меньше, чем всего)
select count(*) as cnt_dnf, pilot
from (select driver.name       as pilot,
             race.race_date,
             championship.name as championshp,
             pilots_results.laps_passed,
             race.total_laps,
             track.name        as track
      from pilots_results
               join driver on pilots_results.pilot_id = driver.id
               join race on race.id = pilots_results.race_id
               join championship on race.championship_id = championship.id
               join track on race.track_id = track.id
      where laps_passed < race.total_laps) as prep
group by pilot
order by cnt_dnf desc;
-- 13. Инструкция SELECT, использующая вложенные подзапросы с уровнем вложенности 3
-- Выбрать всех пилотов прошедших за всю карьеру максимальное число кругов в сумме среди всех пилотов
select name, total_laps
from driver
         join (select sum(laps_passed) as total_laps, pilot_id
               from pilots_results
               group by pilot_id
               having sum(laps_passed) = (select max(total_laps)
                                          from (select sum(laps_passed) as total_laps
                                                from pilots_results
                                                group by pilot_id) as laps_per_pilot)) as max_laps_per_pilot
              on max_laps_per_pilot.pilot_id = driver.id;
-- 14. Инструкция SELECT, консолидирующая данные с помощью предложения GROUP BY, но без предложения HAVING
-- Вывести сколько кругов прошел каждый пилот за всю карьеру
select name, total_laps
from driver
         join (select sum(laps_passed) as total_laps, pilot_id from pilots_results group by pilot_id) as laps_per_pilot
              on driver.id = laps_per_pilot.pilot_id
order by total_laps desc;
-- 15. Инструкция SELECT, консолидирующая данные с помощью предложения GROUP BY и предложения HAVING
-- Вывести пилотов прошедших менее 20 000 кругов за всю карьеру
select name, total_laps
from driver
         join (select sum(laps_passed) as total_laps, pilot_id
               from pilots_results
               group by pilot_id
               having sum(laps_passed) < 20000) as laps_per_pilot
              on driver.id = laps_per_pilot.pilot_id
order by total_laps desc;
-- 16. Однострочная инструкция INSERT, выполняющая вставку в таблицу одной строки значений
-- В таблицу сходов с дистанции дописать сход
insert into dnf
values ('Alex Bell', '14.01.2020', 'Formula 1', 25, 68, 'Las Vegas Motor Speedway');
select *
from dnf
where pilot = 'Alex Bell';
-- 17. Многострочная инструкция INSERT, выполняющая вставку в таблицу результирующего набора данных вложенного подзапроса
-- Для каждой команды во временную таблицу вставить гонщиков из страны создания этой команды, выступавших за нее
drop table if exists national_teams;
create temp table national_teams
(
    team    text,
    pilots  text[],
    country text
);
insert into national_teams
select team.name, array_agg(distinct driver.name), driver.country
from pilots_results
         join driver on pilots_results.pilot_id = driver.id
         join team on pilots_results.team_id = team.id
where driver.country = team.base_country
group by team.name, country;
select *
from national_teams;
-- 18. Простая инструкция UPDATE
-- В таблице dnf выставиь lap_passed равным total_laps если было пройдено больше половины дистанции
select *
from dnf;
update dnf
set laps_passed=total_laps
where laps_passed > 0.5 * total_laps;
select *
from dnf
where laps_passed = total_laps;
-- 19. Инструкция UPDATE со скалярным подзапросом в предложении SET
-- Установить число кругов в гонках чемпионата DTM равным среднему числу кругов во всех гонках
drop table if exists copy_race;
create temp table if not exists copy_race
(
    id              integer,
    track_id        integer,
    race_date       date,
    championship_id integer,
    total_laps      integer
);
insert into copy_race
select *
from race;
select *
from copy_race
where championship_id = (select id from public.championship where name = 'DTM');
update copy_race
set total_laps = (select avg(total_laps)::integer from race)
where championship_id = (select id from championship where name = 'DTM');
select *
from copy_race
where championship_id = (select id from public.championship where name = 'DTM');
-- 20. Простая инструкция DELETE
-- Удалить из copy_race все гонки чемпионата DTM
delete
from copy_race
where championship_id = (select id from championship where name = 'DTM');
select *
from copy_race
where championship_id = (select id from championship where name = 'DTM');
-- 21. Инструкция DELETE с вложенным коррелированным подзапросом в предложении WHERE
-- Удалить все гонки на трассах в Испании
select *
from copy_race
         join track on copy_race.track_id = track.id
where track.country = 'Spain';
delete
from copy_race
where (select country from track where id = copy_race.track_id) = 'Spain';
select *
from copy_race
         join track on copy_race.track_id = track.id
where track.country = 'Spain';
-- 22. Инструкция SELECT, использующая простое обобщенное табличное выражение
-- Выбрать записи о результатах гонщиков, где они прошли больше средней пройденной всеми гонщиками дистанции в этой гонке, но не всю
with mean_laps_per_race as (select avg(laps_passed)::integer as avg_laps_passed, race_id
                            from pilots_results
                            group by race_id)
select driver.name, team.name, laps_passed, avg_laps_passed, total_laps, championship.name, track.name
from pilots_results
         join mean_laps_per_race
              on mean_laps_per_race.race_id = pilots_results.race_id
         join driver on pilots_results.pilot_id = driver.id
         join team on pilots_results.team_id = team.id
         join race on pilots_results.race_id = race.id
         join track on race.track_id = track.id
         join championship on race.championship_id = championship.id
where laps_passed > avg_laps_passed
  and laps_passed <> race.total_laps;
-- 23. Инструкция SELECT, использующая рекурсивное обобщенное табличное выражение
-- Результаты гонок для пилотов участвовавших в предыдущих гонках того же чемпионата
with recursive RaceResults as (select race.id              as race_id,
                                      race.championship_id as champ_id,
                                      race.track_id,
                                      race.race_date,
                                      pilots_results.pilot_id,
                                      pilots_results.finish_position,
                                      pilots_results.points
                               from race
                                        join pilots_results on race.id = pilots_results.race_id
                               union all
                               select race.id,
                                      race.championship_id,
                                      race.track_id,
                                      race.race_date,
                                      pilots_results.pilot_id,
                                      pilots_results.finish_position,
                                      pilots_results.points
                               from race
                                        join pilots_results on race.id = pilots_results.race_id
                               where pilots_results.pilot_id in (select pilot_id
                                                                 from pilots_results
                                                                 where race_id =
                                                                       (select max(id)
                                                                        from race
                                                                        where race_date < race.race_date)))
select race.race_date,
       track.name,
       championship.name,
       driver.name,
       RaceResults.finish_position,
       RaceResults.points
from race
         join RaceResults on race.id = RaceResults.race_id
         join track on race.track_id = track.id
         join championship on race.championship_id = championship.id
         join driver on RaceResults.pilot_id = driver.id
order by driver.name, championship.name, race.race_date;
-- 24. Оконные функции. Использование конструкци MIN/MAX/AVG OVER()
-- Определить сколько в среднем очков заработал каждый гонщик в каждом чемпионате, в котором он участвовал
select distinct driver.name,
                championship.name,
                avg(points) over (partition by driver.name, championship.name)
from pilots_results
         join driver on pilots_results.pilot_id = driver.id
         join race on pilots_results.race_id = race.id
         join championship on race.championship_id = championship.id
         join track on race.track_id = track.id;
-- 25. Оконные фнкции для устранения дублей
drop table if exists double_data;
create temp table double_data
(
    race_id         integer,
    pilot_id        integer,
    laps_passed     integer,
    start_position  integer,
    finish_position integer,
    team_id         integer,
    points          integer
);
insert into double_data
select *
from pilots_results
where race_id in (select race_id
                  from race
                           join track on race.track_id = track.id
                  where track.country = 'Spain')
union all
select *
from pilots_results
where race_id in (select race_id
                  from race
                           join track on race.track_id = track.id
                  where track.country = 'Spain');
drop table if exists double_data_nums;
create temp table if not exists double_data_nums as (select *,
                                                            row_number()
                                                            over (partition by double_data.race_id, double_data.pilot_id) as row_num
                                                     from double_data);
select *
from double_data_nums;
delete
from double_data_nums
where row_num > 1;
select *
from double_data_nums
where row_num > 1;
-- Защита: Выбрать пилотов которые за все выступления были только на пьедестале
select driver.name
from driver
         join (select pilot_id from pilots_results group by pilot_id having max(finish_position) <= 3) as prep
              on driver.id = prep.pilot_id;