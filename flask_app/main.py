#!/usr/bin/env python3

from flask import Flask, render_template, request, redirect, url_for
import psycopg2
import os

open_port = os.environ["APP_PORT"]
app = Flask(__name__)
db_host = os.environ["DB_IP"]
db_pass = os.environ["DB_PASS"]


# connecting to db
def get_db_connection():
    conn = psycopg2.connect(host=db_host,
                            database='flask_db',
                            user="maxim",
                            password=db_pass)
    return conn


@app.route('/')
def index():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('SELECT * FROM books;')
    books = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('index.html', books=books)


@app.route('/create/', methods=('GET', 'POST'))
def create():
    if request.method == 'POST':
        title = request.form['title']
        author = request.form['author']
        pages_num = int(request.form['pages_num'])
        review = request.form['review']

        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('INSERT INTO books (title, author, pages_num, review)'
                    'VALUES (%s, %s, %s, %s)',
                    (title, author, pages_num, review))
        conn.commit()
        cur.close()
        conn.close()
        return redirect(url_for('index'))
    return render_template('create.html')


app.run(host="0.0.0.0", port=int(open_port))
