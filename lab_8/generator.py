from faker import Faker
from time import sleep
from datetime import datetime
from json import dumps

fake = Faker()
ind = 0
while True:
    values = []
    for i in range(5):
        values.append({'name': fake.name(), 'country': fake.country(),
                       'birth_date': fake.date(end_datetime=datetime.strptime("2004-12-31", "%Y-%m-%d"))})
    with open(f"sheet/{ind}-driver-{datetime.now()}.json", "w") as f:
        f.write(dumps(values))
    sleep(300)
