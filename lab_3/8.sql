-- 8 Хранимая процедура доступа к метаданным
-- Получить таблицы для которых существуют ограничения CHECK
drop function if exists find_checks();
create or replace function find_checks()
    returns table
            (
                table_name_      information_schema.sql_identifier
            )
as
$$
begin
    return query
        select distinct table_name
        from pg_constraint
                 join information_schema.constraint_column_usage on conname = constraint_name
        where pg_get_constraintdef(pg_constraint.oid) like 'CHECK%'
          and table_schema = 'public';
end
$$ language plpgsql;

select * from find_checks();


-- select *
-- from information_schema.table_constraints
-- where constraint_type = 'CHECK'
--   and table_schema = 'public';
--
-- select conname, pg_get_constraintdef(pg_constraint.oid)
-- from pg_constraint
--          join information_schema.constraint_column_usage on conname = constraint_name
-- where pg_get_constraintdef(pg_constraint.oid) like 'CHECK%';