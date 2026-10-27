import os 
import pymysql

connection = pymysql.connect (
    host="localhost",
    user="root",
    password=os.environ.get("DB_PASSWORD"),
    database="hospital_db",
)

cursor = connection.cursor()

cursor.execute("SELECT COUNT(*) FROM lab_tests")

print(cursor.fetchone())

connection.close()

