-- 1. Скопировать все в json

copy (select array_to_json(array_agg(row_to_json(d)))
      from driver d) to '/tmp/driver.json';
copy (select array_to_json(array_agg(row_to_json(pr)))
      from pilots_results pr) to '/tmp/pilots_results.json';
copy (select array_to_json(array_agg(row_to_json(t)))
      from team t) to '/tmp/team.json';
copy (select array_to_json(array_agg(row_to_json(tr)))
      from track tr) to '/tmp/track.json';
copy (select array_to_json(array_agg(row_to_json(c)))
      from championship c) to '/tmp/champ.json';
copy (select array_to_json(array_agg(row_to_json(r)))
      from race r) to '/tmp/race.json';

-- 2. Преобразовать JSON обратно в таблицу

create temp table if not exists json_buf
(
    data jsonb
);
truncate json_buf;
copy json_buf (data) from '/tmp/driver.json';
-- z4v2vb9h

drop table if exists copy_driver;
create temp table if not exists copy_driver
(
    id         integer,
    name       text,
    country    text,
    birth_date date
);

insert into copy_driver
select (d ->> 'id')::int, (d ->> 'name')::text, (d ->> 'country')::text, (d ->> 'birth_date')::date
from jsonb_array_elements((select data from json_buf)) d;
select *
from copy_driver;



truncate json_buf;
copy json_buf (data) from '/tmp/champ.json';

drop table if exists copy_champs;
create temp table if not exists copy_champs
(
    id     integer,
    name   text,
    region text
);

insert into copy_champs
select (d ->> 'id')::int, (d ->> 'name')::text, (d ->> 'region')::text
from jsonb_array_elements((select data from json_buf)) d;
select *
from copy_champs;


truncate json_buf;
copy json_buf (data) from '/tmp/team.json';

create temp table if not exists copy_team
(
    id             serial,
    name           text,
    origin_country text,
    base_country   text
);

insert into copy_team
select (d ->> 'id')::int, (d ->> 'name')::text, (d ->> 'origin_country')::text, (d ->> 'base_country')::text
from jsonb_array_elements((select data from json_buf)) d;
select *
from copy_team;



truncate json_buf;
copy json_buf (data) from '/tmp/track.json';
drop table if exists copy_track;
create temp table if not exists copy_track
(
    id         serial,
    name       text,
    country    text,
    lap_length float4
);

insert into copy_track
select (d ->> 'id')::int, (d ->> 'name')::text, (d ->> 'country')::text, (d ->> 'lap_length')::float4
from jsonb_array_elements((select data from json_buf)) d;

select *
from copy_track;

truncate json_buf;
copy json_buf (data) from '/tmp/race.json';

create temp table if not exists copy_race
(
    id              serial,
    track_id        int,
    race_date       date,
    championship_id int,
    total_laps      int
);

insert into copy_race
select (d ->> 'id')::int,
       (d ->> 'track_id')::int,
       (d ->> 'race_date')::date,
       (d ->> 'championship_id')::int,
       (d ->> 'total_laps')::int
from jsonb_array_elements((select data from json_buf)) d;

select *
from copy_race;

truncate json_buf;
copy json_buf (data) from '/tmp/pilots_results.json';

create temp table if not exists copy_pilots_results
(
    race_id         int,
    pilot_id        int,
    laps_passed     int,
    start_position  int,
    finish_position int,
    team_id         int,
    points          int
);
truncate copy_pilots_results;
insert into copy_pilots_results
select (d ->> 'race_id')::int,
       (d ->> 'pilot_id')::int,
       (d ->> 'laps_passed')::int,
       (d ->> 'start_position')::int,
       (d ->> 'finish_position')::int,
       (d ->> 'team_id')::int,
       (d ->> 'points')::int
from jsonb_array_elements((select data from json_buf)) d;
select *
from copy_pilots_results;
select count(*)
from copy_pilots_results;
select count(*)
from pilots_results;

-- 3. Таблицу с json
-- Laps stats:  {'lap_number': {'lap_start_position':1, 'lap_end_position':1, 'lap_time':123.00}} время в сек
drop table if exists pilot_times;
create temp table if not exists pilot_times
(
    race_id     int,
    pilot_id    int,
    laps_passed int,
    laps_stats  jsonb,
    team_id     int,
    points      int
);
truncate pilot_times;
-- select *
-- from pilots_results
-- where pilots_results.laps_passed < 5
--   and pilots_results.laps_passed > 0
-- order by random()
-- limit 5;

insert into pilot_times
values (24902, 3789, 2, '{
  "1": {
    "lap_start_position": 9,
    "lap_end_position": 12,
    "lap_time": 95.32
  },
  "2": {
    "lap_start_position": 12,
    "lap_end_position": 20,
    "lap_time": 125.64
  }
}'::jsonb, 7, 0),
       (6308, 2010, 2, '{
         "1": {
           "lap_start_position": 13,
           "lap_end_position": 9,
           "lap_time": 85.48
         },
         "2": {
           "lap_start_position": 9,
           "lap_end_position": 19,
           "lap_time": 107.95
         }
       }'::jsonb, 513, 0),
       (15180, 4931, 2, '{
         "1": {
           "lap_start_position": 44,
           "lap_end_position": 30,
           "lap_time": 110.12
         },
         "2": {
           "lap_start_position": 30,
           "lap_end_position": 56,
           "lap_time": 150.24
         }
       }'::jsonb, 279, 0),
       (2488, 1323, 3, '{
         "1": {
           "lap_start_position": 53,
           "lap_end_position": 54,
           "lap_time": 107.98
         },
         "2": {
           "lap_start_position": 54,
           "lap_end_position": 53,
           "lap_time": 105.24
         },
         "3": {
           "lap_start_position": 53,
           "lap_end_position": 60,
           "lap_time": 125.78
         }
       }'::jsonb, 122, 0),
       (13518, 36, 1, '{
         "1": {
           "lap_start_position": 4,
           "lap_end_position": 23,
           "lap_time": 99.29
         }
       }'::jsonb, 133, 0)
;

select *
from pilot_times;
-- select *
-- from race
--          join championship on race.championship_id = championship.id
--          join track on race.track_id = track.id
-- where race.id = 13518;

-- 4. Извлечь фрагмент
select (laps_stats ->> '1')::text
from pilot_times;
-- 4. Извлечь конкретный узел или атрибут
select (laps_stats -> '2' ->> 'lap_time')::float4 as second_lap_times
from pilot_times
where laps_passed > 1;
-- 4. Проверить существование узла
select pilot_times.laps_stats ? 'some_key'
from pilot_times;
select pilot_times.laps_stats -> '1' ? 'lap_time'
from pilot_times;

-- 4. обновить узел
select *
from pilot_times;
update pilot_times
set laps_stats=jsonb_set(laps_stats, '{"2","lap_time"}', ((laps_stats -> '2' ->> 'lap_time')::float4 + 5)::text::jsonb)
where laps_passed > 1;
select *
from pilot_times;
-- 5. Распарсить узел
select
    race_id,
    pilot_id,
    laps_passed,
    lap_data.key,
    lap_data.value
from
    pilot_times
cross join lateral jsonb_each(laps_stats) AS lap_data(key, value)
order by pilot_id, race_id, lap_data.key;
