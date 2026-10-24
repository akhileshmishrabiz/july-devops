docker build -t appwithdb:1.0 .

kind load docker-image appwithdb:1.0 --name day2


 postgresql://postgres:Admin1234@10.96.66.160:5432/postgres

 postgresql://{user}:{password}@{host}:5432/{db_name}


 kubectl run busybox --image=busybox:1.36 --restart=Never -it --rm -- sh


 160.66.96.10.in-addr.arpa	name = postgres-service.default.svc.cluster.local


postgres-service   default   

if you cretease aservice A in namespace B -> dns will be  A.B.svc.cluster.local