from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import OperationalError
import os, time

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+psycopg2://postgres:1234@db:5432/cafe")

# Retry loop for DB connection
engine = None
for i in range(10):
    try:
        engine = create_engine(DATABASE_URL)
        with engine.connect() as conn:
            print("✅ Database connected")
        break
    except OperationalError:
        print(f"⏳ Database not ready, retrying in 5s... ({i+1}/10)")
        time.sleep(5)

if engine is None:
    raise Exception("❌ Could not connect to the database after 10 retries")

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
