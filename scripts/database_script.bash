#!/bin/bash
apt install nano
apt install postgresql postgresql-contrib -y
source /var/lib/waagent/custom-script/download/0/terraform_proj/scripts/exports.bash "$1" "$2" "$3" "$4" "$5"
systemctl start postgresql.service
#sudo -u postgres psql -c "data_directory = '/data1'"
sudo -u postgres psql -c "CREATE DATABASE flask_db;"
sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE flask_db TO ${DB_USER};"
echo "listen_addresses = '*'" | sudo tee -a /etc/postgresql/*/main/postgresql.conf
echo "host   all    all 10.0.1.0/24     md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf
sudo service postgresql restart