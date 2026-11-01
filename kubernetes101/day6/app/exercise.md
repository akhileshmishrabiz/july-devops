# 

By this time, you have created the eks cluster

auth with aws

aws eks update-kubeconfig --name <cluster name>

kubectl config rename-context <>  <>

kubectl get node/pod/ and all that.


# runnung a 3 tier app

1. create one ecr repo -> eks-3tierapp

i will push 2 images with diff tags for backend and frontend in the same ecr repo

go to the day 6 folder -> july-devops/kubernetes101/day6 

create backedn and frontend images, use ecr repo name

cd app/backend

docker build --platform linux/amd64 \
  -t 879381241087.dkr.ecr.ap-south-1.amazonaws.com/eks-3tierapp:backend .

cd ../frontend

docker build --platform linux/amd64 \
  -t 879381241087.dkr.ecr.ap-south-1.amazonaws.com/eks-3tierapp:frontend .


# auth with ecr 

aws configure (if you havent already)

aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 879381241087.dkr.ecr.ap-south-1.amazonaws.com

wait for login success

# push the images

docker push 879381241087.dkr.ecr.ap-south-1.amazonaws.com/eks-3tierapp:backend

docker push 879381241087.dkr.ecr.ap-south-1.amazonaws.com/eks-3tierapp:


go to rds , create a postgres instance, use easy create option and do it on default


user: postgres (default)
pass: Admin1234
dbname: postgres

host
port 5432