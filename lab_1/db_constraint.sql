-- restrictions for driver table
alter table driver
    add constraint PK_driver primary key (id);
alter table driver
    alter column id set not null;
alter table driver
    alter column name set not null;


-- restrictions for team table
alter table team
    add constraint PK_team primary key (id);
alter table team
    alter column id set not null;
alter table team
    alter column name set not null;
alter table team
    add unique (name);

-- restrictions for track table
alter table track
    add constraint PK_track primary key (id);
alter table track
    alter column id set not null;
alter table track
    alter column name set not null;
alter table track
    add unique (name);
alter table track
    alter column country set not null;
alter table track
    add check (lap_length > 0 and lap_length <= 6);
alter table track
    alter column lap_length set not null;


-- restrictions for championship table
alter table championship
    add constraint PK_championship primary key (id);
alter table championship
    alter column id set not null;
alter table championship
    alter column name set not null;
alter table championship
    add unique (name);
alter table championship
    alter column region set not null;


-- restrictions for race table
alter table race
    add constraint PK_race primary key (id);
alter table race
    alter column id set not null;
alter table race
    add constraint FK_championship_race foreign key (championship_id) references championship on delete cascade;
alter table race
    alter column championship_id set not null;
alter table race
    add constraint FK_track_race foreign key (track_id) references track on delete cascade;
alter table race
    alter column track_id set not null;
alter table race
    alter column race_date set not null;
alter table race
    add check (total_laps > 0);


-- restrictions for pilot_result table
alter table pilots_results
    add constraint FK_pilot_pilots_results foreign key (pilot_id) references driver on delete cascade;
alter table pilots_results
    alter column pilot_id set not null;
alter table pilots_results
    add constraint FK_team_pilots_results foreign key (team_id) references team on delete cascade;
alter table pilots_results
    add constraint FK_race_pilots_results foreign key (race_id) references race on delete cascade;
alter table pilots_results
    alter column team_id set not null;
alter table pilots_results
    alter column laps_passed set not null;
alter table pilots_results
    add check (laps_passed >= 0);
alter table pilots_results
    alter column start_position set not null;
alter table pilots_results
    add check (start_position > 0);
alter table pilots_results
    alter column finish_position set not null;
alter table pilots_results
    add check (finish_position > 0);
alter table pilots_results
    alter column pilot_id set not null;
alter table pilots_results
    alter column race_id set not null;
alter table pilots_results
    alter column points set not null;
alter table pilots_results
    add check (points >= 0);
