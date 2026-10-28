import os
import pymysql

def get_connection():
    return pymysql.connect(host="localhost", user="root",
                           password=os.environ.get("DB_PASSWORD"),
                           database="hospital_db")