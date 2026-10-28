from flask import Flask, render_template
from db import get_connection

app = Flask(__name__)

@app.route("/lab-tests")
def lab_tests():
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("SELECT test_name, price FROM lab_tests")
    rows = cursor.fetchall()
    connection.close()
    return render_template("table.html", title="Lab tests",
                           headings=["Test name", "Price"], rows=rows)

if __name__ == "__main__":
    app.run(debug=True)