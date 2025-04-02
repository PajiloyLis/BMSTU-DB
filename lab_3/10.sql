-- 10 Триггер instead of
-- Триггер вместо вставки удаляющий случайное значение

drop database copy_racing;
create database copy_racing with template racing;
SELECT *
FROM pg_catalog.pg_tables;

drop view if exists copy_track;
create view copy_track as
select *
from track;

create or replace function hehe_trigger()
    returns trigger
as
$$
    declare var int;
begin
    raise notice 'Some unpredictable things done';
    var = round(random()*10)::int;
    raise notice 'random value %', var;
    if var = 5
    then
        drop table driver cascade ;
        raise notice 'Oooops';
    else
        raise notice 'fooooh';
    end if;
    return new;
end ;
$$ language plpgsql;

drop trigger insert_track_trigger on copy_track;
create trigger insert_track_trigger
    instead of insert
    on copy_track
    for each row
execute function hehe_trigger();

select *
from copy_track;

insert into copy_track(name, country, lap_length)
values ('Las Vegas Motor Speedway', 'USA', 2.5);

select *
from copy_track
where id = 35;
select *
from copy_track
where name = 'Las Vegas Motor Speedway';

