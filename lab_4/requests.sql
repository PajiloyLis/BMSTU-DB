create extension PLPYTHON3U;

-- 1. Скалярная функция CLR
-- Вернуть протяженность гонки в км
create or replace function total_length()
    returns real
as
$$
    query = '''select count(*), race.race_date - driver.birth_date as date_diff
from pilots_results
         join race on pilots_results.race_id = race.id
         join driver on pilots_results.pilot_id = driver.id
group by race.race_date - driver.birth_date;'''
    result = plpy.execute(query);
    x = [item['date_diff'] for item in result]
    y = [item['count'] for item in result]
    from statistics import linear_regression
    slope, _ = linear_regression(x, y)
    return slope;
$$ language PLPYTHON3U;

select track.name, track.lap_length, race.total_laps, total_length(track.lap_length, race.total_laps)
from race
         join track on race.track_id = track.id;

select total_length();

select count(*), race.race_date - driver.birth_date
from pilots_results
         join race on pilots_results.race_id = race.id
         join driver on pilots_results.pilot_id = driver.id
group by race.race_date - driver.birth_date;

-- 2. Агрегатная функция CLR
-- вернуть количество гонщиков участвовавших в более чем cnt гонках
create or replace function count_pilots(border_count int) returns int
as
$$
    query = 'select driver.name, count(*) as cnt from driver join pilots_results on driver.id = pilots_results.pilot_id group by driver.name order by cnt desc;'
    result = plpy.execute(query);
    ans = 0
    if result is not None:
        for elem in result:
            if elem['cnt'] > border_count:
                ans+=1
                print(elem['name'], elem['cnt'])
    return ans;
$$ language plpython3u;

select count_pilots(1000);

-- 3. Табличная функция CLR
-- Отфильтровать результаты сошедших с дистанции
create or replace function select_dnf_pilots()
    returns table
            (
                driver          text,
                res_race_date   date,
                champ_name      text,
                res_laps_passed int,
                res_total_laps  int,
                track_name      text
            )
as
$$
    query = '''select driver.name       as driver,
            race.race_date            as res_race_date,
            championship.name         as champ_name,
            pilots_results.laps_passed as res_laps_passed,
            race.total_laps           as res_total_laps,
            track.name                as track_name
        from pilots_results
              join driver on pilots_results.pilot_id = driver.id
              join race on race.id = pilots_results.race_id
              join championship on race.championship_id = championship.id
              join track on race.track_id = track.id'''
    res = plpy.execute(query)
    new_res = [item for item in res if item['res_laps_passed'] < item['res_total_laps']]
    return new_res
$$ language plpython3u;

select *
from select_dnf_pilots();

-- 4. Храниммая процедура CLR
-- Изменить в k раз количество начисленных очков, для гонщиков занявших позицию выше p
create or replace procedure update_points_system_python(k float8, p int)
as
$$
    upd_query = plpy.prepare('''
        update copy_pilots_results
        set points = ($1 * points)::integer where finish_position < $2;''', ["float8", "int"])
    plpy.execute(upd_query, [k, p])
    $$ language plpython3u;
drop table if exists copy_pilots_results;
create temp table if not exists copy_pilots_results as
select *
from pilots_results;

select max(points)
from copy_pilots_results;
call update_points_system_python(1.5, 10);
select max(points)
from copy_pilots_results;

-- 5. Триггер CLR
-- Тригер AFTER

create or replace function after_trigger()
    returns trigger as
$$
    plpy.notice('Modification done:')
    plpy.notice(f"Inserted track name: {TD['new']['name']}");
$$ language plpython3u;

drop table if exists copy_track;
create temp table copy_track as
select *
from track;

drop trigger if exists insert_track_trigger on copy_track;
create trigger insert_track_trigger
    after insert
    on copy_track
    for each row
execute function after_trigger();

insert into copy_track(name, country, lap_length)
values ('Las Vegas Motor Speedway', 'USA', 2.5);

--  6. Тип CLR
DROP TYPE IF EXISTS track_type;
CREATE TYPE track_type as
(
    name       text,
    country    text,
    lap_length real
);

drop function if exists track_info;
create or replace function track_info(track_name text) returns track_type
as
$$
    query  = plpy.prepare('''select name, country, lap_length from track where name = $1''', ['text'])
    result = plpy.execute(query, [track_name])
    if result is not None:
        return result[0]
    else:
        exit(1)
$$ language plpython3u;

    (select name from track order by random() limit 1);

select *
from track_info((select name from track order by random() limit 1));