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

@app.route("/lab-tests/delete/<int:test_id>", methods=["POST"])
def delete_lab_test(test_id):
    connection = get_connection()
    cursor = connection.cursor()
    try:
        cursor.execute("DELETE FROM lab_tests WHERE test_id = %s", (test_id,))
        connection.commit()
        message = "Lab test deleted."
    except pymysql.MySQLError as error:
        message = "Could not delete: " + str(error.args[1])
    connection.close()
    return redirect(url_for("lab_tests", message=message))

@app.route("/bed-board")
def bed_board():
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("""
        SELECT r.room_no, r.room_type, b.bed_no, b.status
        FROM beds b
        RIGHT JOIN rooms r ON b.room_id = r.room_id
        ORDER BY r.room_no, b.bed_no
    """)
    rows = cursor.fetchall()
    connection.close()
    return render_template("table.html", title="Bed board",
        headings=["Room", "Type", "Bed", "Status"], rows=rows)

@app.route("/departments-rooms")
def departments_rooms():
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("""
        SELECT d.dept_name, r.room_no
        FROM departments d
        LEFT JOIN rooms r ON r.department_id = d.department_id
        UNION
        SELECT d.dept_name, r.room_no
        FROM departments d
        RIGHT JOIN rooms r ON r.department_id = d.department_id
    """)
    rows = cursor.fetchall()
    connection.close()
    return render_template("table.html", title="Departments vs rooms",
        headings=["Department", "Room"], rows=rows)

@app.route("/")
def home():
    return render_template("index.html")

@app.route("/beds")
def beds():
    message = request.args.get("message")
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("SELECT bed_id, room_id, bed_no, status FROM beds ORDER BY room_id, bed_no")
    rows = cursor.fetchall()
    connection.close()
    return render_template("beds.html", beds=rows, message=message)

@app.route("/beds/add", methods=["POST"])
def add_bed():
    connection = get_connection()
    cursor = connection.cursor()
    try:
        cursor.execute("INSERT INTO beds (room_id, bed_no) VALUES (%s, %s)",
                       (request.form["room_id"], request.form["bed_no"]))
        connection.commit()
        message = "Bed added."
    except pymysql.MySQLError as error:
        message = "Could not add: " + str(error.args[1])
    connection.close()
    return redirect(url_for("beds", message=message))

@app.route("/beds/edit/<int:bed_id>", methods=["GET", "POST"])
def edit_bed(bed_id):
    connection = get_connection()
    cursor = connection.cursor()
    if request.method == "POST":
        try:
            cursor.execute("UPDATE beds SET status = %s WHERE bed_id = %s",
                           (request.form["status"], bed_id))
            connection.commit()
            message = "Bed updated."
        except pymysql.MySQLError as error:
            message = "Could not update: " + str(error.args[1])
        connection.close()
        return redirect(url_for("beds", message=message))
    cursor.execute("SELECT bed_id, room_id, bed_no, status FROM beds WHERE bed_id = %s", (bed_id,))
    bed = cursor.fetchone()
    connection.close()
    if bed is None:
        abort(404)
    return render_template("edit_bed.html", bed=bed)

@app.route("/beds/delete/<int:bed_id>", methods=["POST"])
def delete_bed(bed_id):
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("SELECT status FROM beds WHERE bed_id = %s", (bed_id,))
    bed = cursor.fetchone()
    if bed and bed[0] == "Occupied":
        message = "Cannot delete an occupied bed."
    else:
        try:
            cursor.execute("DELETE FROM beds WHERE bed_id = %s", (bed_id,))
            connection.commit()
            message = "Bed deleted."
        except pymysql.MySQLError as error:
            message = "Could not delete: " + str(error.args[1])
    connection.close()
    return redirect(url_for("beds", message=message))

if __name__ == "__main__":
    app.run(debug=True)