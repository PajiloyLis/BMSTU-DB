copy driver (name, country, birth_date) from '/tmp/drivers.csv' delimiter ',' csv header;
copy championship (name, region) from '/tmp/champs.csv' delimiter ',' csv header;
copy team (name, origin_country, base_country) from '/tmp/teams.csv' delimiter ',' csv header;
copy track (name, country, lap_length) from '/tmp/tracks.csv' delimiter ',' csv header;
copy race (track_id, race_date, championship_id, total_laps) from '/tmp/races.csv' delimiter ',' csv header;
copy pilots_results (race_id, pilot_id, laps_passed, start_position, finish_position, team_id,
                     points) from '/tmp/pilots_results.csv' delimiter ',' csv header;