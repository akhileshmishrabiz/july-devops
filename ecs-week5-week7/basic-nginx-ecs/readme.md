 docker build --platform=linux/amd64 -t nginx-linux .  

 docker tag nginx-linux 879381241087.dkr.ecr.ap-south-1.amazonaws.com/july-nginx-demo:1.0


 aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 879381241087.dkr.ecr.ap-south-1.amazonaws.com

 docker push 879381241087.dkr.ecr.ap-south-1.amazonaws.com/july-nginx-demo:1.0
