import psycopg2
from sqlalchemy import (Column,
                        Integer,
                        Text,
                        Date,
                        Time,
                        CheckConstraint,
                        ForeignKeyConstraint,
                        create_engine, ForeignKey, func)
from sqlalchemy.orm import declarative_base, Session

Base = declarative_base()


class Satellite(Base):
    __tablename__ = 'satellite'

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(Text)
    prod_date = Column(Date)
    country = Column(Text)


class Flight(Base):
    __tablename__ = 'flight'
    __table_args__ = (CheckConstraint(
        "day_of_week in ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')"),
                      CheckConstraint("type between 0 and 1"))

    id = Column(Integer, primary_key=True, autoincrement=True)
    satellite_id = Column(Integer, ForeignKey('satellite.id', ondelete='cascade'), nullable=False)
    launch_date = Column(Date)
    launch_time = Column(Time)
    day_of_week = Column(Text)
    type = Column(Integer)



if __name__ == '__main__':
    engine = create_engine('postgresql://postgres:password@localhost:5432/')
    Base.metadata.create_all(engine)
    engine.connect()
    session = Session(engine)

    print("Answers for first:")
    for res in session.query(Satellite).filter(Satellite.name.like('%2086%')).all():
        print(res.country)
    print()
    print("Answers for second:")
    res = session.query(Satellite).join(Flight, Satellite.id == Flight.satellite_id).filter(
        func.extract('year', Flight.launch_date) == 2024).order_by(Flight.launch_date).first()
    print(res.name, res.prod_date, res.country)
    print()
    print("Answers for third:")
    for res in session.query(Satellite).join(Flight, Satellite.id == Flight.satellite_id).filter(
        Flight.launch_date.between('2024-01-01', '2024-01-11') & (Flight.type == 0)).all():
        print(res.name, res.prod_date, res.country)
