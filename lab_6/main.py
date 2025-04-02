from db import DBConnection
from getpass import getpass
import warnings

warnings.filterwarnings("ignore")


def printer(result):
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


if __name__ == '__main__':
    db = DBConnection()
    while True:
        while True:
            print("Выберите запрос:",
                  "1 - Вывести пилотов побеждавших в гонках, моложе определенного возраста",
                  "2 - Выести информацию о сходах с дистанции",
                  "3 - Вывести информацию о среднем количестве очков заработанных пилотами в чемпионате",
                  "4 - Получить таблицы для которых существует ограничение check",
                  "5 - Вычислить дистанцию гонки по id",
                  "6 - Получить максимум отыгранных позиций в каждом чемпионате",
                  "7 - Вывести команды, пилоты которых выигрывали в определенный год в любом чемпионате",
                  "8 - Получить таблицы для которых существуют ограничения CHECK",
                  "9 - Создать временную таблицу сходов с дистанции",
                  "10 - Вывести содержимое таблицы dnf",
                  "0 - Выход",
                  sep='\n')
            try:
                action_number = int(input())
                if not 0 <= action_number <= 10:
                    raise ValueError
                break
            except ValueError:
                print("Неверный ввод")
        match action_number:
            case 1:
                while True:
                    try:
                        print("Введите возраст:")
                        age = int(input())
                        if age < 0:
                            raise ValueError
                        break
                    except ValueError:
                        print("Неверный возраст")
                result = db.query1(age)
                printer(result)
            case 2:
                result = db.query2()
                printer(result)
            case 3:
                nums_to_names = {1: "Formula 1", 2: "World Endurance Championship", 3: "NASCAR", 4: "INDYCAR",
                                 5: "Formula E", 6: "Formula 3000", 7: "Super Formula", 8: "Formula 2", 9: "Formula 3",
                                 10: "DTM"}
                while True:
                    try:
                        print("Выберите номер чемпионата:")
                        for key, value in nums_to_names.items():
                            print(f"{key} - {value}")
                        num = int(input())
                        if not 0 < num < 11:
                            raise ValueError
                        break
                    except ValueError:
                        print("Неверный номер чемпионата")
                result = db.query3(nums_to_names[num])
                printer(result)
            case 4:
                result = db.query4()
                printer(result)
            case 5:
                while True:
                    try:
                        print("Введите id гонки (от 1 до 25000):")
                        num = int(input())
                        if not 0 < num <= 25000:
                            raise ValueError
                        break
                    except ValueError:
                        print("Неверный id гонки")
                result = db.query5(num)
                printer(result)
            case 6:
                result = db.query6()
                printer(result)
            case 7:
                while True:
                    try:
                        print("Введите год от 1950 до 2024:")
                        num = int(input())
                        if not 1950 <= num <= 2024:
                            raise ValueError
                        break
                    except ValueError:
                        print("Неверный год")
                result = db.query7(num)
                printer(result)
            case 8:
                result = db.query8()
                printer(result)
            case 9:
                result = db.query9()
                printer(result)
            case 10:
                result = db.query10()
                printer(result)
            case 0:
                break
