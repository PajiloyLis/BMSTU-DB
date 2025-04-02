create database rk;
\rk

drop table if exists  consumers cascade;
drop table if exists seller cascade ;
drop table if exists  flowers cascade ;
drop table if exists seller_consumer cascade ;
create table if not exists consumers
(
    id    serial primary key,
    name  text not null,
    dob   date not null,
    city  text,
    phone text
);

create table if not exists seller
(
    id       serial primary key,
    name     text not null,
    passport text not null,
    phone    text
);

create table if not exists flowers
(
    id     serial primary key,
    author int,
    name   text not null
);

create table if not exists seller_consumer
(
    seller_id   serial not null,
    consumer_id serial not null
);

alter table seller_consumer
    add constraint FK_seller foreign key (seller_id) references seller on delete cascade;
alter table seller_consumer
    add constraint FK_consumer foreign key (consumer_id) references consumers on delete cascade;

alter table flowers
    add constraint FK_seller foreign key (author) references seller on delete set null;

alter table consumers
    add constraint phone_number check ( phone like '+7-___-___-__-__');
alter table seller
    add constraint phone_number check ( phone like '+7-___-___-__-__');
alter table seller
    add constraint passport check (passport like '__ __ ______');

copy consumers (name, dob, city, phone) from '/tmp/consumers' delimiter ',' csv header;
select *
from consumers;

copy seller (name, passport, phone) from '/tmp/sellers' delimiter ',' csv header;
select *
from seller;

copy flowers (author, name) from '/tmp/flowers' delimiter ',' csv header;
select *
from flowers;


copy seller_consumer (seller_id, consumer_id) from '/tmp/sellers_consumers' delimiter ',' csv header;
select *
from seller_consumer;

-- Вывести авторов букетов
select distinct name
from seller
where exists (select * from flowers where author = seller.id);
-- для проверки
select distinct seller.name
from flowers
         join seller on author = seller.id;

-- Вывести покупателей от 30 до 50 лет на данный момент (кривое из-за слишком умного вычитания дат в postgresql)
select name, dob
from consumers
where date_part('year', now()) - date_part('year', dob) between 30 and 50;

-- Вывести покупателей, покупавших букеты у их создателей
select name
from consumers
where id in (select seller_consumer.consumer_id from seller_consumer where seller_id in (select author from flowers));

-- Оно немного кривое, но запрос верный
create or replace function check_check(table_name_to_find text) returns table (con_name text, const text) as
$$
begin
    return query
    select conname, pg_get_constraintdef(pg_constraint.oid)
    from pg_constraint
             join information_schema.constraint_column_usage on conname = constraint_name
    where table_name = table_name_to_find
      and pg_get_constraintdef(pg_constraint.oid) like '%~~%';
end;
$$ language plpgsql;
