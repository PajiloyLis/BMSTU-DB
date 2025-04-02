-- 7 Хранимая процедура с курсором

-- Получить команды, пилоты которых одерживали победы в гонках в определенный год

create or replace procedure winners_teams(year integer)
as
$$
declare
    team_name record;
    cur_cursor cursor for
        select distinct team.name as name
        from team
                 join (select pilots_results.team_id, pilots_results.race_id
                       from pilots_results
                       where finish_position = 1) as prep
                      on prep.team_id = team.id
                 join race on prep.race_id = race.id
        where championship_id = (select id from championship where championship.name = 'Formula 1')
          and date_part('year', race_date) = year;
begin
    open cur_cursor;
    loop
        fetch cur_cursor into team_name;
        exit when not found;
        raise notice 'Team: = %', team_name.name;
    end loop;
    close cur_cursor;
    --     for record in cur_cursor
--         loop
--             raise notice 'Team: = %', record.name;
--         end loop;
end;
$$ language plpgsql;

call winners_teams(1970);

-- select distinct team.name as name
-- from team
--          join (select pilots_results.team_id, pilots_results.race_id
--                from pilots_results
--                where finish_position = 1) as prep
--               on prep.team_id = team.id
--          join race on prep.race_id = race.id
-- where championship_id = (select id from championship where championship.name = 'Formula 1');
--
-- select distinct name
-- from championship;
-- select team.name as name
-- from team
--          join pilots_results on team.id = pilots_results.team_id
--          join race on pilots_results.race_id = race.id
--          join public.championship on championship.id = race.championship_id
-- where finish_position = 1
--   and championship.name = 'Formula 1'
--   and date_part('year', race.race_date) = 2020;
-- select *
-- from race
-- where date_part('year', race_date) = 2024
--   and championship_id in (select id from championship where name = 'Formula 1');

create temp table if not exists dnf
(
    pilot       text,
    race_date   date,
    champ_name  text,
    laps_passed int,
    total_laps  int,
    track       text
);
insert into dnf (select driver.name       as pilot,
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
select * from dnf;