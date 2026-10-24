import logging
import os
from pathlib import Path

import psycopg
from psycopg.conninfo import conninfo_to_dict
from flask import Flask, redirect, render_template_string, request, url_for


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
logger = logging.getLogger("devops-game")

app = Flask(__name__)

SECRET_DIR = Path(os.getenv("SECRET_DIR", "/etc/postgres-secret"))
CONFIG_DIR = Path(os.getenv("CONFIG_DIR", "/etc/app-config"))

DATABASE_URL_FILE = SECRET_DIR / "DB_URL"
APP_TITLE_FILE = CONFIG_DIR / "APP_TITLE"
ENVIRONMENT_FILE = CONFIG_DIR / "ENVIRONMENT"
LAB_TITLE_FILE = CONFIG_DIR / "LAB_TITLE"
LAB_PROMPT_FILE = CONFIG_DIR / "LAB_PROMPT"
LAB_HINT_FILE = CONFIG_DIR / "LAB_HINT"
LAB_ANSWER_FILE = CONFIG_DIR / "LAB_ANSWER"


def read_secret_file(path):
    """Read a required secret from a mounted file."""
    value = path.read_text(encoding="utf-8").strip()
    if not value:
        raise RuntimeError(f"Secret file is empty: {path}")
    return value


def read_config_file(path):
    """Read a required application setting from a mounted config file."""
    value = path.read_text(encoding="utf-8").strip()
    if not value:
        raise RuntimeError(f"Config file is empty: {path}")
    return value


def load_app_config():
    """Reload settings from the mounted ConfigMap/config volume."""
    return {
        "title": read_config_file(APP_TITLE_FILE),
        "environment": read_config_file(ENVIRONMENT_FILE),
        "lab_title": read_config_file(LAB_TITLE_FILE),
        "lab_prompt": read_config_file(LAB_PROMPT_FILE),
        "lab_hint": read_config_file(LAB_HINT_FILE),
        "lab_answer": read_config_file(LAB_ANSWER_FILE),
    }

PAGE = """
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{ config.title }}</title>
  <style>
    body {
      background: radial-gradient(circle at top, #1e3a5f, #111827 45%);
      color: #f9fafb;
      font-family: system-ui, sans-serif;
      margin: 0;
      min-height: 100vh;
      padding: 36px 18px;
    }
    main {
      margin: auto;
      max-width: 820px;
    }
    .card {
      background: #1f2937ee;
      border: 1px solid #374151;
      border-radius: 16px;
      box-shadow: 0 20px 40px #0006;
      margin-bottom: 22px;
      padding: 30px;
    }
    .hero { text-align: center; }
    h1 { margin: 0 0 8px; }
    h2 { margin-top: 0; }
    .badge {
      background: #065f46;
      border-radius: 999px;
      color: #a7f3d0;
      display: inline-block;
      font-size: 13px;
      padding: 5px 10px;
    }
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
    input {
      background: #030712;
      border: 1px solid #4b5563;
      border-radius: 8px;
      box-sizing: border-box;
      color: #86efac;
      font-family: ui-monospace, monospace;
      font-size: 16px;
      margin: 10px 0;
      padding: 14px;
      width: 100%;
    }
    .terminal {
      background: #030712;
      border-left: 4px solid #ef4444;
      border-radius: 8px;
      color: #fca5a5;
      font-family: ui-monospace, monospace;
      padding: 16px;
    }
    .result { border-radius: 8px; margin-top: 16px; padding: 14px; }
    .success { background: #064e3b; color: #a7f3d0; }
    .retry { background: #78350f; color: #fde68a; }
    details { color: #fbbf24; margin: 12px 0; }
    p { color: #d1d5db; }
    code { color: #fbbf24; }
  </style>
</head>
<body>
  <main>
    <section class="card hero">
      <span class="badge">Environment: {{ config.environment }}</span>
      <h1>🚀 {{ config.title }}</h1>
      <p>Successful deployments stored in PostgreSQL:</p>
      <div class="score">{{ score }}</div>
      <form method="post" action="{{ url_for('deploy') }}">
        <button type="submit">Ship a deployment</button>
      </form>
      <p>Delete the pods, refresh this page, and the score remains.</p>
      <code>kubectl delete pod -l app=postgres</code>
    </section>

    <section class="card">
      <h2>🛠️ Linux Troubleshooting Lab: {{ config.lab_title }}</h2>
      <div class="terminal">
        ALERT: /var is 96% full. Production writes may stop soon.
      </div>
      <p>{{ config.lab_prompt }}</p>
      <details>
        <summary>Need a hint?</summary>
        <p>{{ config.lab_hint }}</p>
      </details>
      <form method="post" action="{{ url_for('troubleshoot') }}">
        <label for="command">Enter the diagnostic command:</label>
        <input id="command" name="command" placeholder="$ your command" required>
        <button type="submit">Run diagnosis</button>
      </form>
      {% if lab_result %}
        <div class="result {{ 'success' if lab_result.correct else 'retry' }}">
          {{ lab_result.message }}
        </div>
      {% endif %}
    </section>
  </main>
</body>
</html>
"""


def connect():
    # Read on every connection so Kubernetes Secret volume updates are used
    # without restarting the application pods.
    return psycopg.connect(read_secret_file(DATABASE_URL_FILE))


def initialize_database():
    database = conninfo_to_dict(read_secret_file(DATABASE_URL_FILE))
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


def render_home(lab_result=None, config=None):
    with connect() as connection:
        score = connection.execute(
            "SELECT score FROM game WHERE id = 1"
        ).fetchone()[0]
    return render_template_string(
        PAGE,
        score=score,
        config=config or load_app_config(),
        lab_result=lab_result,
    )


@app.get("/")
def index():
    return render_home()


@app.post("/deploy")
def deploy():
    with connect() as connection:
        connection.execute(
            "UPDATE game SET score = score + 1 WHERE id = 1"
        )
    return redirect(url_for("index"))


@app.post("/troubleshoot")
def troubleshoot():
    submitted = " ".join(request.form.get("command", "").split())
    config = load_app_config()
    expected = " ".join(config["lab_answer"].split())
    if submitted == expected:
        result = {
            "correct": True,
            "message": "Incident resolved! You found the largest directories without crossing filesystems. 🎉",
        }
    else:
        result = {
            "correct": False,
            "message": "Not quite. Check the hint and make sure the command sorts human-readable disk usage.",
        }
    return render_home(result, config)


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
