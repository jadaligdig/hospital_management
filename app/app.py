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

@app.route("/lab-tests-never-ordered")
def lab_tests_never_ordered():
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("""
        SELECT lab_tests.test_name, lab_tests.price
        FROM lab_tests
        LEFT JOIN lab_orders
            ON lab_tests.test_id = lab_orders.test_id
        WHERE lab_orders.lab_order_id IS NULL
    """)
    rows = cursor.fetchall()
    connection.close()
    return render_template("table.html", title="Lab tests never ordered",
                           headings=["Test name", "Price"], rows=rows)

if __name__ == "__main__":
    app.run(debug=True)