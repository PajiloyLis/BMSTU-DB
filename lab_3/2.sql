-- 2 Подставляемая табличная функция
-- Выбрать все сходы в формуле 3000 гонщиков определенной страны
drop function if exists f3000_dnf(text);
create or replace function f3000_dnf(pilot_country text)
    returns table
            (
                pilot  text,
                race_date  date,
                track text,
                team  text
            )
as
$$
begin
    return query
    select driver.name as pilot, race.race_date, track.name as track, team.name as team
    from pilots_results
             join driver on driver.id = pilots_results.pilot_id
             join race on pilots_results.race_id = race.id
             join track on track.id = race.track_id
             join championship on race.championship_id = championship.id
             join team on pilots_results.team_id = team.id
    where laps_passed < total_laps
      and championship.id = (select championship.id from championship where championship.name = 'Formula 3000')
      and driver.country = pilot_country;
end
$$ language plpgsql;

select * from f3000_dnf('Bolivia');