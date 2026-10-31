# DevOps Incident Arena

This Flask application stores its deployment score in PostgreSQL and includes
a Linux troubleshooting lab.

At runtime it reads:

- `DB_URL` from `$SECRET_DIR/DB_URL`
- UI and lab settings from files under `$CONFIG_DIR`

Database connection setup rereads `DB_URL` for every connection so projected
Secret updates are consumed without restarting the app.

Build the image from the parent directory:

```bash
docker build -t day3-part2:1.0 app
```

See the parent `readme.md` for the complete Vault, ESO, StatefulSet, and Kind
deployment procedure.
