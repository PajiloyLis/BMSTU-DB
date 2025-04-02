-- Триггер AFTER

create or replace function after_trigger()
    returns trigger as
$$
begin
    raise notice 'Modification done:';
    raise notice 'Inserted track name: %', new.name;
    return new;
end ;
$$ language plpgsql;


drop trigger if exists insert_track_trigger on copy_track;
create trigger insert_track_trigger
    after insert
    on copy_track
    for each row
execute function after_trigger();

drop table if exists copy_track;
create temp table copy_track as
select *
from track;

insert into copy_track(name, country, lap_length) values('Las Vegas Motor Speedway', 'USA', 2.5);
