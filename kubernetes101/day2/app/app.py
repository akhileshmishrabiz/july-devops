import logging
import os

import psycopg
from psycopg.conninfo import conninfo_to_dict
from flask import Flask, redirect, render_template_string, url_for


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
logger = logging.getLogger("devops-game")

app = Flask(__name__)

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://devops:devops@postgres:5432/devops_game",
)

PAGE = """
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>DevOps Deployment Game</title>
  <style>
    body {
      align-items: center;
      background: #111827;
      color: #f9fafb;
      display: flex;
      font-family: system-ui, sans-serif;
      justify-content: center;
      margin: 0;
      min-height: 100vh;
    }
    main {
      background: #1f2937;
      border-radius: 16px;
      box-shadow: 0 20px 40px #0006;
      max-width: 520px;
      padding: 40px;
      text-align: center;
      width: calc(100% - 64px);
    }
    h1 { margin-top: 0; }
    .score {
      color: #34d399;
      font-size: 72px;
      font-weight: 800;
      margin: 16px;
    }
    button {
      background: #3b82f6;
      border: 0;
      border-radius: 10px;
      color: white;
      cursor: pointer;
      font-size: 20px;
      font-weight: 700;
      padding: 14px 24px;
    }
    button:hover { background: #2563eb; }
    p { color: #d1d5db; }
    code { color: #fbbf24; }
  </style>
</head>
<body>
  <main>
    <h1>🚀 DevOps Deployment Game</h1>
    <p>Successful deployments stored in PostgreSQL:</p>
    <div class="score">{{ score }}</div>
    <form method="post" action="{{ url_for('deploy') }}">
      <button type="submit">Ship a deployment</button>
    </form>
    <p>Delete the pods, refresh this page, and the score remains.</p>
    <code>kubectl delete pod -l app=postgres</code>
  </main>
</body>
</html>
"""


def connect():
    return psycopg.connect(DATABASE_URL)


def initialize_database():
    database = conninfo_to_dict(DATABASE_URL)
    logger.info(
        "Starting DevOps Game; connecting to PostgreSQL host=%s port=%s dbname=%s user=%s",
        database.get("host", "localhost"),
        database.get("port", "5432"),
        database.get("dbname", "unknown"),
        database.get("user", "unknown"),
    )

    try:
        with connect() as connection:
            logger.info("Database connection established")
            logger.info("Creating the game table if it does not exist")
            connection.execute(
                """
                CREATE TABLE IF NOT EXISTS game (
                    id INTEGER PRIMARY KEY,
                    score INTEGER NOT NULL DEFAULT 0
                )
                """
            )
            connection.execute(
                """
                INSERT INTO game (id, score)
                VALUES (1, 0)
                ON CONFLICT (id) DO NOTHING
                """
            )
        logger.info("Database initialization complete; application is ready")
    except psycopg.Error:
        logger.exception(
            "Database startup check failed; terminating the application"
        )
        raise


@app.get("/")
def index():
    with connect() as connection:
        score = connection.execute(
            "SELECT score FROM game WHERE id = 1"
        ).fetchone()[0]
    return render_template_string(PAGE, score=score)


@app.post("/deploy")
def deploy():
    with connect() as connection:
        connection.execute(
            "UPDATE game SET score = score + 1 WHERE id = 1"
        )
    return redirect(url_for("index"))


@app.get("/healthz")
def health():
    try:
        with connect() as connection:
            connection.execute("SELECT 1")
        return {"status": "ok"}, 200
    except psycopg.Error:
        return {"status": "database unavailable"}, 503


initialize_database()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
