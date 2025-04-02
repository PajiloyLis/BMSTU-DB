import redis
import psycopg2
import time
import datetime
import matplotlib.pyplot as plt
from tqdm import tqdm
from random import randint

query = """
    with races_by_pilots_in_1970 as (select array_agg(points) points_all_races, pilot_id
                                 from race
                                          join pilots_results on race.id = pilots_results.race_id
                                 where date_part('year', race_date) = 1970
                                 group by pilot_id)
select driver.name
from driver
         join races_by_pilots_in_1970 as prep on driver.id = prep.pilot_id
where 0 < all (points_all_races);
"""


def postgres_connection():
    return psycopg2.connect(host='localhost',
                            port=5432,
                            database='racing',
                            user='postgres',
                            password='password')


def redis_connection():
    return redis.Redis(host='localhost', port=6379, db=0)


def pg_query(conn):
    with conn.cursor() as cur:
        cur.execute(query)
        return cur.fetchall()


def redis_query(conn, pg_conn, pg_func):
    result = conn.get("races_by_pilots_in_1970")
    if result:
        return eval(result)
    else:
        result = pg_func(pg_conn)
        redis_conn.set("races_by_pilots_in_1970", str(result), ex=100)
        return result


def insert_query(conn):
    with conn.cursor() as cur:
        cur.execute("insert into driver(name, country, birth_date) values (%s, %s, %s)", ('Lando Norris',
                                                                                          'United Kingdom',
                                                                                          str(datetime.date(year=1999,
                                                                                                            month=11,
                                                                                                            day=13))))
    conn.commit()


def update_query(conn):
    with conn.cursor() as cur:
        cur.execute(f"update driver set country='USA' where id = {randint(1, 5000)};")
    conn.commit()


def delete_query(conn):
    with conn.cursor() as cur:
        cur.execute(f"delete from driver where id={randint(1, 5000)} ")
    conn.commit()


def measure_performance(pg_conn, redis_conn, pg_func, modify_function=False):
    pg_times = []
    redis_times = []
    for i in tqdm(range(5)):
        if modify_function and i:
            time.sleep(5)
        start = time.time()
        pg_func(pg_conn)
        end = time.time()
        pg_times.append(end - start)
        start = time.time()
        redis_query(redis_conn, pg_conn, pg_func)
        end = time.time()
        redis_times.append(end - start)
        time.sleep(5)
    return [pg_times, redis_times]


def draw_plots(data, title: str):
    x = [i for i in range(1, 6)]
    plt.plot(x, data[0], 'o-r')
    plt.plot(x, data[1], 'o-g')
    plt.legend(['Запрос напрямую через Postgres', 'Запрос через Redis'], loc='best')
    plt.grid = True
    plt.xlabel("Measure number")
    plt.ylabel("Time")
    plt.title(title)
    plt.show()


if __name__ == "__main__":
    pg_conn = postgres_connection()
    redis_conn = redis_connection()
    data = measure_performance(pg_conn, redis_conn, pg_query)
    draw_plots(data, 'Select')
    data = measure_performance(pg_conn, redis_conn, insert_query, True)
    draw_plots(data, 'Insert')
    data = measure_performance(pg_conn, redis_conn, update_query, True)
    draw_plots(data, 'Update')
    data = measure_performance(pg_conn, redis_conn, delete_query, True)
    draw_plots(data, 'Delete')
