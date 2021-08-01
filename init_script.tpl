#!/bin/bash
sudo apt update -y
sudo apt upgrade -y
sudo apt install tree -y
sudo apt install mysql-client-core-8.0 -y
sudo apt install python3-pip -y
sudo apt-get install nfs-common -y


sudo mkdir /code
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${fs_name}.efs.eu-central-1.amazonaws.com:/ /code

sudo apt-get install git -y
git clone https://github.com/andrei-shtanakov/code.git
cd /code
pip3 install -r requirements.txt

sudo cat <<EOF > /code/cloud_app/cloud_app/.env
DB_HOST='${db_address}'
DEBUG=True
DB_PASSWORD='12345678'
SECRET_KEY='django-insecure-9c7qcp&9y3n0ucke0b63%mg#w=ws4j6@!pg=o6hmrran#&76d_'
ALLOWED_HOSTS='[${public_ip}]'
EOF

cd /code/cloud_app/
python3 manage.py migrate
python3 manage.py runserver 0.0.0.0:8000 
