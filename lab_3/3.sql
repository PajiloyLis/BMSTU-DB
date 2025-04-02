-- 3 Многооператорная табличная функция
-- Вычисляет таблицу макисмальных отыгранных позиций в каждом чемпионате
create or replace function gained_pos_per_champ()
    returns table
            (
                champ_name text,
                max_gained int
            )
as
$$
begin
    drop table if exists result;
    create temp table if not exists result(champ_name text, max_gained int);
    insert into result (select championship.name, max(pilots_results.finish_position-pilots_results.start_position)
    from pilots_results
             join race on pilots_results.race_id = race.id
             join championship on race.championship_id = championship.id
    group by championship.name);
    return query
    select * from result;
end
$$ language plpgsql;

select * from gained_pos_per_champ();