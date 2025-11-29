from flask import Flask, render_template, request, redirect, session, url_for, flash
import json
import redis
import os
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
app.secret_key = os.getenv('FLASK_SECRET_KEY', 'fallback-secret-key')

redis_host = os.getenv('REDIS_HOST', 'localhost')
redis_port = int(os.getenv('REDIS_PORT', 6379))

try:
    redis_client = redis.Redis(host=redis_host, port=redis_port, db=0, decode_responses=True)
    redis_client.ping()
except redis.ConnectionError as e:
    print(f"Failed to connect to Redis: {e}")
    exit(1)

BOOKS_KEY = "books"
USERS_KEY = "users"

def save_books(books):
    try:
        redis_client.set(BOOKS_KEY, json.dumps(books))
    except Exception as e:
        print(f"Error saving books: {e}")

def load_books():
    try:
        books_data = redis_client.get(BOOKS_KEY)
        if not books_data:
            return []

        books = json.loads(books_data)
        changed = False
        for b in books:
            if "borrowed_by" not in b:
                b["borrowed_by"] = None
                changed = True
            if "image" not in b:
                b["image"] = "bookgh.jpg"
                changed = True
        if changed:
            save_books(books)
        return books
    except json.JSONDecodeError as e:
        print(f"Error loading books: {e}")
        return []
    except Exception as e:
        print(f"Unexpected error loading books: {e}")
        return []

def load_users():
    try:
        users_data = redis_client.get(USERS_KEY)
        if not users_data:
            return []
        return json.loads(users_data)
    except json.JSONDecodeError as e:
        print(f"Error loading users: {e}")
        return []
    except Exception as e:
        print(f"Unexpected error loading users: {e}")
        return []

def save_users(users):
    try:
        redis_client.set(USERS_KEY, json.dumps(users))
    except Exception as e:
        print(f"Error saving users: {e}")

def init_admin():
    users = load_users()
    admin_exists = any(u["username"].lower() == "superuser1" for u in users)

    if not admin_exists:
        hashed_password = generate_password_hash("123")
        users.append({"username": "superuser1", "password": hashed_password, "role": "admin"})
        save_users(users)
        print("Admin user created: superuser1/123")

@app.route("/")
def landing():
    return render_template("landing.html", hide_nav=True)

@app.route("/home")
def home():
    if "username" not in session:
        return redirect(url_for("login"))

    query = request.args.get("q", "")
    books = load_books()
    if query:
        q = query.lower()
        books = [b for b in books if q in b["title"].lower() or q in b["author"].lower()]
    return render_template(
        "home.html",
        books=books,
        role=session.get("role"),
        query=query,
        current_user=(session.get("username", "") or "").lower()
    )

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form["username"].strip().lower()
        password = request.form["password"]
        users = load_users()
        user = next((u for u in users if u["username"].lower() == username and check_password_hash(u["password"], password)), None)
        if user:
            session["username"] = username
            session["role"] = user["role"]
            print(f"User {username} logged in with role: {user['role']}")
            return redirect(url_for("home"))
        else:
            flash("Invalid credentials", "error")
    return render_template("login.html", hide_nav=True)

@app.route("/signup", methods=["GET", "POST"])
def signup():
    if request.method == "POST":
        username = request.form["username"].strip().lower()
        password = request.form["password"]
        users = load_users()
        if any(u["username"].lower() == username for u in users):
            flash("Username already exists", "error")
            return redirect(url_for("signup"))

        hashed_password = generate_password_hash(password)
        users.append({"username": username, "password": hashed_password, "role": "user"})
        save_users(users)
        flash("Account created! Please log in.", "success")
        return redirect(url_for("login"))
    return render_template("signup.html", hide_nav=True)

@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("landing"))

@app.route("/add", methods=["GET", "POST"])
def add_book():
    if session.get("role") != "admin":
        flash("Unauthorized", "error")
        return redirect(url_for("home"))

    if request.method == "POST":
        title = request.form["title"].strip()
        author = request.form["author"].strip()
        image = request.form.get("image", "").strip() or "bookgh.jpg"
        books = load_books()

        if any(b["title"].lower() == title.lower() and b["author"].lower() == author.lower() for b in books):
            flash("Book already exists!", "error")
            return redirect(url_for("add_book"))

        new_book = {"title": title, "author": author, "image": image, "borrowed_by": None}
        books.append(new_book)
        save_books(books)
        flash("Book added successfully!", "success")
        return redirect(url_for("home"))
    return render_template("add_book.html")

@app.route("/delete/<string:title>/<string:author>")
def delete_book(title, author):
    if session.get("role") != "admin":
        flash("Unauthorized", "error")
        return redirect(url_for("home"))

    books = load_books()
    books = [b for b in books if not (b["title"].lower() == title.lower() and b["author"].lower() == author.lower())]
    save_books(books)
    flash("Book deleted successfully!", "success")
    return redirect(url_for("home"))

@app.route("/borrow/<string:title>/<string:author>", methods=["POST"])
def borrow_book(title, author):
    if "username" not in session:
        return redirect(url_for("login"))

    books = load_books()
    for book in books:
        if book["title"].lower() == title.lower() and book["author"].lower() == author.lower():
            if book.get("borrowed_by"):
                flash("Book is already borrowed!", "error")
            else:
                book["borrowed_by"] = session["username"].lower()
                save_books(books)
                flash("Book borrowed successfully!", "success")
            break
    return redirect(url_for("home"))

@app.route("/return/<string:title>/<string:author>", methods=["POST"])
def return_book(title, author):
    if "username" not in session:
        return redirect(url_for("login"))

    books = load_books()
    for book in books:
        if book["title"].lower() == title.lower() and book["author"].lower() == author.lower():
            if book.get("borrowed_by") == session["username"].lower():
                book["borrowed_by"] = None
                save_books(books)
                flash("Book returned successfully!", "success")
            else:
                flash("You did not borrow this book!", "error")
            break
    return redirect(url_for("home"))

if __name__ == "__main__":
    init_admin()
    debug = os.getenv("FLASK_DEBUG", "false").lower() == "true"
    app.run(host='0.0.0.0', debug=debug, port=5001)
