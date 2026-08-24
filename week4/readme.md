

```bash
sudo dnf install -y postgresql16
psql --version

psql postgresql://postgres:Admin1234@app-2tier.cvik8accw2tk.ap-south-1.rds.amazonaws.com:5432/mydb

download: s3://database-backup-879381241087/flaskapp.dump to ./flaskapp.dump

pg_restore --dbname="postgresql://postgres:Admin1234@app-2tier.cvik8accw2tk.ap-south-1.rds.amazonaws.com:5432/mydb" flaskapp.dump
```