from sqlalchemy import Column, Integer, Text, ForeignKey, Float, Date, UniqueConstraint, CheckConstraint
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()


class Championship(Base):
    __tablename__ = 'championship'
    __table_args__ = (UniqueConstraint("name"),)

    id = Column('id', Integer, primary_key=True)
    name = Column('name', Text, nullable=False)
    region = Column('region', Text, nullable=False)


class Driver(Base):
    __tablename__ = 'driver'
    __table_args__ = ()

    id = Column('id', Integer, primary_key=True)
    name = Column('name', Text, nullable=False)
    country = Column('country', Text)
    birth_date = Column('birth_date', Date)


class PilotsResults(Base):
    __tablename__ = 'pilots_results'
    __table_args__ = (
        CheckConstraint("laps_passed >= 0"),
        CheckConstraint("start_position > 0"),
        CheckConstraint("finish_position > 0"),
        CheckConstraint("points >= 0")
    )

    id = Column('id', Integer, primary_key=True)
    race_id = Column('race_id', Integer, ForeignKey('race.id'), nullable=False)
    pilot_id = Column('pilot_id', Integer, ForeignKey('driver.id'), nullable=False)
    laps_passed = Column('laps_passed', Integer, nullable=False)
    start_position = Column('start_position', Integer, nullable=False)
    finish_position = Column('finish_position', Integer, nullable=False)
    team_id = Column('team_id', Integer, ForeignKey('team.id'), nullable=False)
    points = Column('points', Integer, nullable=False)


class Race(Base):
    __tablename__ = 'race'
    __table_args__ = (CheckConstraint("total_laps > 0"),)

    id = Column('id', Integer, primary_key=True)
    track_id = Column('track_id', Integer, ForeignKey('track.id'), nullable=False)
    race_date = Column('race_date', Date, nullable=False)
    championship_id = Column('championship_id', Integer, ForeignKey('championship.id'), nullable=False)
    total_laps = Column('total_laps', Integer)


class Team(Base):
    __tablename__ = 'team'
    __table_args__ = (UniqueConstraint("name"),)

    id = Column('id', Integer, primary_key=True)
    name = Column('name', Text, nullable=False)
    origin_country = Column('origin_country', Text)
    base_country = Column('base_country', Text)


class Track(Base):
    __tablename__ = 'track'
    __table_args__ = (UniqueConstraint("name"), CheckConstraint("lap_length > 0 and lap_length <= 6"))

    id = Column('id', Integer, primary_key=True)
    name = Column('name', Text, nullable=False)
    country = Column('country', Text, nullable=False)
    lap_length = Column('lap_length', Float, nullable=False)
