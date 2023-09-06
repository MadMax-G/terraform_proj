#!/bin/bash
apt install nano
apt install python3
apt install python3-pip -y
pip install flask
pip install psycopg2-binary
source ./terraform_proj/scripts/exports.bash "$1" "$2" "$3" "$4" "$5"
python3 ./terraform_proj/flask_app/init_db.py
python3 ./terraform_proj/flask_app/main.py &