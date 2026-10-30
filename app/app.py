import pymysql
from flask import Flask, render_template, request, redirect, url_for, abort
from db import get_connection

app = Flask(__name__)

@app.route("/lab-tests")
def lab_tests():
    message = request.args.get("message")
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("SELECT test_id, test_name, price FROM lab_tests")
    rows = cursor.fetchall()
    connection.close()
    return render_template("lab_tests.html", lab_tests=rows, message=message)

@app.route("/lab-tests/add", methods=["POST"])
def add_lab_test():
    test_name = request.form["test_name"]
    price = request.form["price"]

    connection = get_connection()
    cursor = connection.cursor()

    try:
        cursor.execute(
            "INSERT INTO lab_tests (test_name, price) VALUES (%s, %s)",
            (test_name, price)
        )
        connection.commit()
        message = "Lab test added."
    except pymysql.MySQLError as error:
        message = "Could not add: " + str(error.args[1])

    connection.close()

    return redirect(url_for("lab_tests", message=message))

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

@app.route("/lab-tests/edit/<int:test_id>", methods=["GET", "POST"])
def edit_lab_test(test_id):
    connection = get_connection()
    cursor = connection.cursor()

    if request.method == "POST":
        price = request.form["price"]

        try:
            cursor.execute(
                "UPDATE lab_tests SET price = %s WHERE test_id = %s",
                (price, test_id)
            )
            connection.commit()
            message = "Lab test updated."

        except pymysql.MySQLError as error:
            message = "Could not update: " + str(error.args[1])

        connection.close()
        return redirect(url_for("lab_tests", message=message))

    # GET request: runs only when not POST
    cursor.execute(
        "SELECT test_id, test_name, price FROM lab_tests WHERE test_id = %s",
        (test_id,)
    )
    lab_test = cursor.fetchone()
    connection.close()

    if lab_test is None:
        abort(404)

    return render_template("edit_lab_test.html", lab_test=lab_test)

if __name__ == "__main__":
    app.run(debug=True)