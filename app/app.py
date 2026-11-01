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

@app.route("/appointment-schedule")
def appointment_schedule():
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("""
        SELECT a.appointment_id, p.first_name, p.last_name, d.last_name,
               a.appt_datetime, a.status, a.reason
        FROM appointments a
        INNER JOIN patients p ON a.patient_id = p.patient_id
        INNER JOIN doctors d ON a.doctor_id = d.doctor_id
        ORDER BY a.appt_datetime
    """)
    rows = cursor.fetchall()
    connection.close()
    return render_template("table.html", title="Appointment schedule",
        headings=["ID", "Patient first", "Patient last", "Doctor", "Date and time", "Status", "Reason"],
        rows=rows)

@app.route("/patients")
def patients():
    message = request.args.get("message")
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("SELECT patient_id, first_name, last_name, birth_date, gender, phone, address FROM patients")
    rows = cursor.fetchall()
    connection.close()
    return render_template("patients.html", patients=rows, message=message)

@app.route("/patients/add", methods=["POST"])
def add_patient():
    connection = get_connection()
    cursor = connection.cursor()
    try:
        cursor.execute(
            "INSERT INTO patients (first_name, last_name, birth_date, gender, phone, address) VALUES (%s, %s, %s, %s, %s, %s)",
            (request.form["first_name"], request.form["last_name"], request.form["birth_date"],
             request.form["gender"], request.form["phone"] or None, request.form["address"] or None))
        connection.commit()
        message = "Patient added."
    except pymysql.MySQLError as error:
        message = "Could not add: " + str(error.args[1])
    connection.close()
    return redirect(url_for("patients", message=message))

@app.route("/patients/edit/<int:patient_id>", methods=["GET", "POST"])
def edit_patient(patient_id):
    connection = get_connection()
    cursor = connection.cursor()
    if request.method == "POST":
        try:
            cursor.execute(
                "UPDATE patients SET first_name=%s, last_name=%s, birth_date=%s, gender=%s, phone=%s, address=%s WHERE patient_id=%s",
                (request.form["first_name"], request.form["last_name"], request.form["birth_date"],
                 request.form["gender"], request.form["phone"] or None, request.form["address"] or None, patient_id))
            connection.commit()
            message = "Patient updated."
        except pymysql.MySQLError as error:
            message = "Could not update: " + str(error.args[1])
        connection.close()
        return redirect(url_for("patients", message=message))
    cursor.execute("SELECT patient_id, first_name, last_name, birth_date, gender, phone, address FROM patients WHERE patient_id = %s", (patient_id,))
    patient = cursor.fetchone()
    connection.close()
    if patient is None:
        abort(404)
    return render_template("edit_patient.html", patient=patient)

@app.route("/patients/delete/<int:patient_id>", methods=["POST"])
def delete_patient(patient_id):
    connection = get_connection()
    cursor = connection.cursor()
    try:
        cursor.execute("DELETE FROM patients WHERE patient_id = %s", (patient_id,))
        connection.commit()
        message = "Patient deleted."
    except pymysql.MySQLError as error:
        message = "Could not delete: " + str(error.args[1])
    connection.close()
    return redirect(url_for("patients", message=message))

def set_app_user(cursor, user_id):
    # same variable the sample SQL sets; the triggers read it for the audit trail
    cursor.execute("SET @app_user_id = %s", (user_id,))

@app.route("/admissions")
def admissions():
    message = request.args.get("message")
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("""
        SELECT a.admission_id, a.patient_id,
               CONCAT(d.first_name, ' ', d.last_name),
               a.bed_id, a.admit_date, a.discharge_date, a.status, a.reason
        FROM admissions a
        INNER JOIN doctors d ON a.doctor_id = d.doctor_id
        ORDER BY a.admission_id
    """)
    rows = cursor.fetchall()
    cursor.execute("SELECT doctor_id, first_name, last_name FROM doctors ORDER BY last_name")
    docs = cursor.fetchall()
    connection.close()
    return render_template("admissions.html", admissions=rows, doctors=docs, message=message)


@app.route("/admissions/add", methods=["POST"])
def add_admission():
    connection = get_connection()
    cursor = connection.cursor()
    try:
        set_app_user(cursor, 2)
        cursor.execute(
            "INSERT INTO admissions (patient_id, doctor_id, bed_id, admit_date, reason) "
            "VALUES (%s, %s, %s, %s, %s)",
            (request.form["patient_id"], request.form["doctor_id"],
             request.form["bed_id"], request.form["admit_date"].replace("T", " "),
             request.form["reason"]))
        connection.commit()
        message = "Patient admitted."
    except pymysql.MySQLError as error:
        message = "Could not add: " + str(error.args[1])
    connection.close()
    return redirect(url_for("admissions", message=message))


@app.route("/admissions/discharge/<int:admission_id>", methods=["POST"])
def discharge_admission(admission_id):
    connection = get_connection()
    cursor = connection.cursor()
    try:
        set_app_user(cursor, 2)
        cursor.execute(
            "UPDATE admissions SET discharge_date = %s, status = 'Discharged' "
            "WHERE admission_id = %s",
            (request.form["discharge_date"].replace("T", " "), admission_id))
        connection.commit()
        message = "Patient discharged."
    except pymysql.MySQLError as error:
        message = "Could not discharge: " + str(error.args[1])
    connection.close()
    return redirect(url_for("admissions", message=message))


@app.route("/admissions/delete/<int:admission_id>", methods=["POST"])
def delete_admission(admission_id):
    connection = get_connection()
    cursor = connection.cursor()
    try:
        cursor.execute("DELETE FROM admissions WHERE admission_id = %s", (admission_id,))
        connection.commit()
        message = "Admission deleted."
    except pymysql.MySQLError as error:
        message = "Could not delete: " + str(error.args[1])
    connection.close()
    return redirect(url_for("admissions", message=message))

@app.route("/invoices")
def invoices():
    message = request.args.get("message")
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("""
        SELECT invoice_id, admission_id, invoice_date, room_charge, lab_charge,
               medicine_charge, total_amount, amount_paid, status
        FROM invoices
        ORDER BY invoice_id
    """)
    rows = cursor.fetchall()
    connection.close()
    return render_template("invoices.html", invoices=rows, message=message)


@app.route("/invoices/add", methods=["POST"])
def add_invoice():
    connection = get_connection()
    cursor = connection.cursor()
    try:
        set_app_user(cursor, 2)
        cursor.execute(
            "INSERT INTO invoices (admission_id, room_charge, lab_charge, medicine_charge) "
            "VALUES (%s, %s, %s, %s)",
            (request.form["admission_id"], request.form["room_charge"],
             request.form["lab_charge"], request.form["medicine_charge"]))
        connection.commit()
        message = "Invoice created."
    except pymysql.MySQLError as error:
        message = "Could not add: " + str(error.args[1])
    connection.close()
    return redirect(url_for("invoices", message=message))


@app.route("/invoices/delete/<int:invoice_id>", methods=["POST"])
def delete_invoice(invoice_id):
    connection = get_connection()
    cursor = connection.cursor()
    try:
        cursor.execute("DELETE FROM invoices WHERE invoice_id = %s", (invoice_id,))
        connection.commit()
        message = "Invoice deleted."
    except pymysql.MySQLError as error:
        message = "Could not delete: " + str(error.args[1])
    connection.close()
    return redirect(url_for("invoices", message=message))

@app.route("/payments")
def payments():
    message = request.args.get("message")
    connection = get_connection()
    cursor = connection.cursor()
    cursor.execute("""
        SELECT p.payment_id, p.invoice_id, p.amount, p.method, p.paid_at, i.status
        FROM payments p
        INNER JOIN invoices i ON p.invoice_id = i.invoice_id
        ORDER BY p.payment_id
    """)
    rows = cursor.fetchall()
    connection.close()
    return render_template("payments.html", payments=rows, message=message)


@app.route("/payments/add", methods=["POST"])
def add_payment():
    connection = get_connection()
    cursor = connection.cursor()
    try:
        set_app_user(cursor, 4)
        cursor.execute(
            "INSERT INTO payments (invoice_id, amount, method) VALUES (%s, %s, %s)",
            (request.form["invoice_id"], request.form["amount"], request.form["method"]))
        connection.commit()
        message = "Payment recorded."
    except pymysql.MySQLError as error:
        message = "Could not add: " + str(error.args[1])
    connection.close()
    return redirect(url_for("payments", message=message))

if __name__ == "__main__":
    app.run(debug=True)