import psycopg2


class DBConnection:
    def __init__(self):
        self._conn = psycopg2.connect("dbname='racing' user='postgres' host='localhost' password='password'")
        self._conn.autocommit = True

    def query1(self, age: int):
        with self._conn.cursor() as cur:
            cur.execute(f'''select distinct name
                            from driver
                                     join pilots_results on driver.id = pilots_results.pilot_id
                            where now() - interval '{age} year' <= birth_date
                              and finish_position = 1;
                            ''')
            result = cur.fetchall()
            result = [('Name',)] + result
        return result

    def query2(self):
        with self._conn.cursor() as cur:
            cur.execute('''select driver.name       as pilot,
            race.race_date,
            championship.name as championshp,
            pilots_results.laps_passed,
            race.total_laps,
            track.name        as track
     from pilots_results
              join driver on pilots_results.pilot_id = driver.id
              join race on race.id = pilots_results.race_id
              join championship on race.championship_id = championship.id
              join track on race.track_id = track.id
     where laps_passed < race.total_laps''')
            result = cur.fetchall()
            result = [("Name", "Race date", "Championship", "Laps passed", "Total Laps", "Track")] + result
            return result

    def query3(self, champ_name: str):
        with self._conn.cursor() as cur:
            cur.execute(f'''with prep as (select distinct driver.name as pilot,
                                                        championship.name as champ,
                                                        avg(points) over (partition by driver.name, championship.name) as avg_points
                                        from pilots_results
                                                 join driver on pilots_results.pilot_id = driver.id
                                                 join race on pilots_results.race_id = race.id
                                                 join championship on race.championship_id = championship.id
                                                 join track on race.track_id = track.id)
                                                 select * from prep where champ = '{champ_name}' order by avg_points desc;
                                                 
                        ''')
            result = [("Pilot name", "Champ name", "Average points",)] + cur.fetchall()
            return result

    def query4(self):
        with self._conn.cursor() as cur:
            cur.execute('''
            select distinct table_name
        from pg_constraint
                 join information_schema.constraint_column_usage on conname = constraint_name
        where pg_get_constraintdef(pg_constraint.oid) like 'CHECK%'
          and table_schema = 'public';
          ''')
            result = [('table name',)] + cur.fetchall()
        return result

    def query5(self, race_id: int):
        with self._conn.cursor() as cur:
            cur.execute(f'''
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
            where race.id = {race_id};
            ''')
            result = [("race_id", "race_date", "champ_name", "total_laps", "lap_length", "track_name", "track_country",
                       "race_length",)] + cur.fetchall()
        return result

    def query6(self):
        with self._conn.cursor() as cur:
            cur.execute(f'''
            select * from gained_pos_per_champ();
            ''')
            result = [("champ_name", "max_gained_positions",)] + cur.fetchall();
        return result

    def query7(self, year: int):
        with self._conn.cursor() as cur:
            cur.execute(f'''
            call winners_teams({year});
            ''')
        result = [(elem[:-1],) for elem in self._conn.notices]
        return result

    def query8(self):
        with self._conn.cursor() as cur:
            cur.execute('''
            select distinct table_name
                from pg_constraint
                         join information_schema.constraint_column_usage on conname = constraint_name
                where pg_get_constraintdef(pg_constraint.oid) like 'CHECK%'
                  and table_schema = 'public';
            ''')
            result = [("table_name",)] + cur.fetchall()
        return result

    def query9(self):
        with self._conn.cursor() as cur:
            cur.execute('''
            create temp table if not exists dnf (pilot text, race_date date, champ_name text, laps_passed int, total_laps int, track text);
            ''')
        result = [("Temp table dnf created",)]
        return result

    def query10(self):
        with self._conn.cursor() as cur:
            try:
                cur.execute('''
                insert into dnf (select driver.name       as pilot,
                            race.race_date,
                            championship.name as championshp,
                            pilots_results.laps_passed,
                            race.total_laps,
                            track.name        as track
                     from pilots_results
                              join driver on pilots_results.pilot_id = driver.id
                              join race on race.id = pilots_results.race_id
                              join championship on race.championship_id = championship.id
                              join track on race.track_id = track.id
                     where laps_passed < race.total_laps);
                ''')
                cur.execute('''select * from dnf''')
                result = [[desc[0] for desc in cur.description]] + cur.fetchall()
            except Exception as e:
                result = [("Temp table dnf does not exist",)]
        return result
