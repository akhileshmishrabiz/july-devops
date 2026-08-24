#  2 tier app

1. flask app that connect to a db using a environment variable DB_LINK
-> # DB_LINK = postgresql://app_user:Admin1234@localhost:5432/flaskapp


2. i need a postgres database -> local db container 


# steps 

1. run the database locally

```bash
docker network create 2tier
```

```bash
docker run  \
--name postgres \
--network 2tier \
-e POSTGRES_PASSWORD=Myadminpassword \
-e POSTGRES_USER=my_admin \
-e POSTGRES_DB=mydb \
-p 5432:5432 \
-d postgres

````

```bash

DB_LINK="postgresql://my_admin:Myadminpassword@localhost:5432/mydb"

```

# run the container 

```bash
docker run -td  \
--network 2tier  \
-p 8000:8000  \
-e DB_LINK="postgresql://my_admin:Myadminpassword@postgres:5432/mydb" \
 app:2.0 
```


############ part 2 with voulmes

#  2 tier app

# cretae docker volume
```bash
docker volume create 2tier-data
```

```bash
docker run \
  --name postgres \
  --network 2tier \
  -e POSTGRES_PASSWORD=Myadminpassword \
  -e POSTGRES_USER=my_admin \
  -e POSTGRES_DB=mydb \
  -v 2tier-data:/var/lib/postgresql/data \
  -p 5432:5432 \
  -d postgres:17

````

```bash

DB_LINK="postgresql://my_admin:Myadminpassword@localhost:5432/mydb"

```

# run the container 

```bash
docker run -td  \
--network 2tier  \
-p 8000:8000  \
-e DB_LINK="postgresql://my_admin:Myadminpassword@postgres:5432/mydb" \
 app:3.0 
```