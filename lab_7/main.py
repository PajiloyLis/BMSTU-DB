import datetime
import random

from sqlalchemy import create_engine, select, insert, update, delete, func, Interval, text, exists, Text, Insert
from sqlalchemy.orm import sessionmaker, Session
from getpass import getpass
import warnings
from dao import *
from json import *
from tqdm import tqdm

warnings.filterwarnings("ignore")

engine = create_engine('postgresql://postgres:password@localhost:5432/racing', implicit_returning=False)
Base.metadata.create_all(engine)
conn = engine.connect()
session = Session(engine)


def printer(result):
    print("Total", len(result) - 1, "rows")
    spacing_size = 200 // len(result[0])
    for j in range(len(result[0])):
        print(f'{result[0][j]: <{spacing_size}}', end="")
    print()
    for i in range(1, len(result)):
        for j in range(len(result[i])):
            print(f"{str(result[i][j]): <{spacing_size}}", end="")
        char = getpass(prompt="")
        if char == 'q':
            return


# 1. LINQ to OBJECT
#  Выбрать пилотов побеждавших в гонках моложе 25 лет
def request_1():
    result = session.query(Driver.name).join(PilotsResults, Driver.id == PilotsResults.pilot_id).where((
                                                                                                               func.now() - text(
                                                                                                           "interval '25 year'") <= Driver.birth_date) & (
                                                                                                               PilotsResults.finish_position == 1))
    return [result.statement.columns.keys()] + result.all()


# Выбрать все городские трассы (содержат city в названии)
def request_2():
    result = session.query(Track.name).where(Track.name.like('%City%'))
    return [result.statement.columns.keys()] + result.all()


# Вывести команды в которых были гонщики из России
def request_3():
    result = session.query(Team.name).where(
        session.query(PilotsResults.team_id).join(Driver, PilotsResults.pilot_id == Driver.id).join(Team,
                                                                                                    PilotsResults.team_id == Team.id).where(
            (Team.id == PilotsResults.team_id) & (Driver.country == 'Russian Federation')).exists())
    return [result.statement.columns.keys()] + result.all()


# Вывести суммарное количество кругов для всех гонок в каждом чемпионате за все время
def request_4():
    result = session.query(Championship.name,
                           (session.query(func.sum(Race.total_laps)).where(
                               Race.championship_id == Championship.id)).label(
                               'sum_laps'),
                           session.query(func.count(Race.id)).where(Race.championship_id == Championship.id).label(
                               'total_races')).order_by('sum_laps', 'total_races')
    return [result.statement.columns.keys()] + result.all()


# Вывести пилотов прошедших менее 20 000 кругов за всю карьеру
def request_5():
    laps_per_pilot = select(
        PilotsResults.pilot_id, func.sum(PilotsResults.laps_passed).label('total_laps')).group_by(
        PilotsResults.pilot_id).having(func.sum(PilotsResults.laps_passed) < 20000)
    result = session.query(Driver.name,
                           laps_per_pilot.c.total_laps,
                           ).select_from(Driver).join(
        laps_per_pilot, Driver.id == laps_per_pilot.c.pilot_id,
    ).order_by(laps_per_pilot.c.total_laps.desc())
    return [result.statement.columns.keys()] + result.all()


def to_json_format(keys, array):
    res = []
    for elem in array:
        res.append(
            {keys[i]: (str(elem[i]) if isinstance(elem[i], datetime.date) else elem[i]) for i in range(len(elem))})
    return res


def json_write(filename, json):
    with open(filename, 'w') as f:
        f.write(json)


# Вытащить в JSON файлы все таблицы
def request_6():
    driver = session.query(Driver.id, Driver.name, Driver.country, Driver.birth_date)
    res = to_json_format(driver.statement.columns.keys(), driver.all())
    json_write("./driver.json", dumps(res))
    print("Driver done")

    team = session.query(Team.id, Team.name, Team.origin_country, Team.base_country)
    res = to_json_format(team.statement.columns.keys(), team.all())
    json_write("./team.json", dumps(res))
    print("Team done")

    championship = session.query(Championship.id, Championship.name, Championship.region)
    res = to_json_format(championship.statement.columns.keys(), championship.all())
    json_write("./championship.json", dumps(res))
    print("Championship done")

    pilots_results = session.query(PilotsResults.race_id, PilotsResults.pilot_id,
                                   PilotsResults.laps_passed, PilotsResults.start_position,
                                   PilotsResults.finish_position, PilotsResults.team_id, PilotsResults.points)
    res = to_json_format(pilots_results.statement.columns.keys(), pilots_results.all())
    json_write("./pilots_results.json", dumps(res))
    print("Pilots results done")

    race = session.query(Race.id, Race.track_id, Race.race_date, Race.championship_id, Race.total_laps)
    res = to_json_format(race.statement.columns.keys(), race.all())
    json_write("./race.json", dumps(res))
    print("Race done")

    track = session.query(Track.id, Track.name, Track.country, Track.lap_length)
    res = to_json_format(track.statement.columns.keys(), track.all())
    json_write("./track.json", dumps(res))
    print("Track done")


def read_json(filename):
    with open(filename, "r") as f:
        res = load(f)
    return res


def load_table_from_json(array):
    for i in tqdm(range(len(array) // 100)):
        elem = array[i]
        conn.execute(text(
            f"insert into pilots_results(race_id, pilot_id, laps_passed, start_position, finish_position, team_id, points) values ({elem['race_id']}, {elem['pilot_id']}, {elem['laps_passed']}, {elem['start_position']}, {elem['finish_position']}, {elem['team_id']}, {elem['points']})"))
        conn.commit()
    result = session.query(PilotsResults.pilot_id, PilotsResults.race_id, PilotsResults.team_id, func.count()).group_by(
        PilotsResults.pilot_id, PilotsResults.team_id, PilotsResults.race_id).order_by(func.count().desc())
    printer([result.statement.columns.keys()] + result.all())
    return


# Прочитать json с результатами
def request7():
    # conn.execute(text("truncate table pilots_results"))
    array = read_json("./pilots_results.json")
    load_table_from_json(array)
    print("filling_done")


def request8():
    array = read_json("./driver.json")
    array[random.randint(0, len(array) - 1)]['name'] = 'Michael Jackson'
    json_write("./driver.json", dumps(array))
    new_array = read_json('./driver.json')
    for elem in new_array:
        if elem['name'] == 'Michael Jackson':
            update_request = update(Driver).where(Driver.id == elem['id']).values(name=elem['name'])
            conn.execute(update_request)
            conn.commit()
            result = session.query(Driver.name, Driver.country, Driver.birth_date).where(Driver.name == elem['name'])
            return [result.statement.columns.keys()] + result.all()


def request9():
    array = read_json("./driver.json")
    insert_statement = insert(Driver).values(name='Michael Schumacher', country='Germany',
                                             birth_date=datetime.date(year=1969, month=1, day=3))
    conn.execute(insert_statement)
    conn.commit()
    result = session.query(Driver.id, Driver.name, Driver.country, Driver.birth_date).where(Driver.name == 'Michael Schumacher')
    array = read_json('./driver.json')
    print(result.statement.columns.keys())
    print(result.all())
    for elem in result.all():
        array.append({result.statement.columns.keys()[i]: (str(elem[i]) if isinstance(elem[i], datetime.date) else elem[i]) for i in range(len(result[0]))})
    json_write('./driver.json', dumps(array))

def request10():
    insert_statement = insert(Driver).values(name='Lando Norris', country='United Kingdom',
                                             birth_date=datetime.date(year=1999, month=11, day=13))
    conn.execute(insert_statement)
    conn.commit()
    result = session.query(Driver.name, Driver.country, Driver.birth_date).where(Driver.name == 'Lando Norris')
    return [result.statement.columns.keys()] + result.all()


def request11():
    update_request = update(Driver).where(Driver.name == 'Lando Norris').values(country='USA')
    conn.execute(update_request)
    conn.commit()
    result = session.query(Driver.name, Driver.country, Driver.birth_date).where(Driver.name == 'Lando Norris')
    return [result.statement.columns.keys()] + result.all()


def request12():
    delete_request = delete(Driver).where(Driver.name == 'Lando Norris')
    conn.execute(delete_request)
    conn.commit()
    result = session.query(Driver.name, Driver.country, Driver.birth_date).where(Driver.name == 'Lando Norris')
    return [result.statement.columns.keys()] + result.all()


if __name__ == '__main__':
    print("1")
    printer(request_1())
    print("2")
    printer(request_2())
    print("3")
    printer(request_3())
    print('4')
    printer(request_4())
    print('5')
    printer(request_5())
    print('6')
    request_6()
    print('7')
    request7()
    print('8')
    printer(request8())
    print(9)
    request9()
    print(10)
    printer(request10())
    print(11)
    printer(request11())
    print(12)
    printer(request12())
