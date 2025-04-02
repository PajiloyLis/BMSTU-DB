-- create database racing;

-- \c racing

create table if not exists driver
(
    id         serial,
    name       text,
    country    text,
    birth_date date
);
create table if not exists team
(
    id             serial,
    name           text,
    origin_country text,
    base_country   text
);
create table if not exists track
(
    id         serial,
    name       text,
    country    text,
    lap_length float4
);
create table if not exists championship
(
    id     serial,
    name   text,
    region text
);
create table if not exists race
(
    id              serial,
    track_id        int,
    race_date       date,
    championship_id int,
    total_laps      int
);
create table if not exists pilots_results
(
    race_id         int,
    pilot_id        int,
    laps_passed     int,
    start_position  int,
    finish_position int,
    team_id         int,
    points          int
);

