#!/bin/bash

sudo yum update -y
sudo yum install python3 -y
sudo yum install git -y

git clone https://github.com/akhileshmishrabiz/july-devops


cd july-devops/week3/src

python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

export DB_LINK=postgresql://postgres:Admin1234@app-2tier.cvik8accw2tk.ap-south-1.rds.amazonaws.com:5432/mydb
sudo chmod u+x run.sh
./run.sh &