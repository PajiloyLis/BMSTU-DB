create or replace function f()
    returns table
            (
                res_race_date date,
                track_name    text,
                champ_name    text,
                driver        text,
                finish_pos    int,
                points        int
            )
as
$$
begin
   return query
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
end
$$
    language plpgsql;

select * from f();
