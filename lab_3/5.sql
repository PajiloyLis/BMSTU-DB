-- 5 Хранимая процедура

-- Изменить в k раз количество начисленных очков
create or replace procedure update_points_system(k float8)
as
    $$
    begin
        update copy_pilots_results
        set points = (k*points)::integer;
    end;
    $$ language plpgsql;
drop table if exists copy_pilots_results;
create temp table if not exists copy_pilots_results as select * from pilots_results;

select max(points) from copy_pilots_results;
call update_points_system(2);
select max(points) from copy_pilots_results;