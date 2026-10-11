docker build -t appwithdb:1.0 .

kind load docker-image appwithdb:1.0 --name day2


 postgresql://postgres:Admin1234@10.96.66.160:5432/postgres

 postgresql://{user}:{password}@{host}:5432/{db_name}