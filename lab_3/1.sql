-- 1. Скалярная функция
create or replace function race_length(lap_length float4, laps_count int) returns float4 as
$$
begin
    return lap_length * laps_count;
end
$$ language plpgsql;

select distinct race_length(track.lap_length, total_laps)
from race
         join track on race.track_id = track.id;

select race.id           as race_id,
       race_date,
       championship.name as champ_name,
       total_laps,
       lap_length,
       track.name,
       track.country,
       race_length(track.lap_length, total_laps)
from race
         join track on race.track_id = track.id
         join championship on race.championship_id = championship.id
where race.id = 12500;

select min(race.race_date) from race;
select max(race.race_date) from race;
