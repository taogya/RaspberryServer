#!/bin/sh

# ex. 
# $ pwd
# /home/pi-srv/RaspberryServer/deploy
# $ sudo sh shells/regenerate_database.sh conf/pi-srv/env.conf

# import environment variables
. "$1"

# regenerate database
sudo su - postgres << EOS
psql -U postgres -t -P format=unaligned -c 'drop database ${RS_DB_NAME};'
psql -U postgres -t -P format=unaligned -c 'create database ${RS_DB_NAME} encoding utf8;'
psql -U postgres -t -P format=unaligned -c 'alter database ${RS_DB_NAME} owner to "${RS_DB_USER}";'
psql -U postgres -t -P format=unaligned -c 'grant all on database ${RS_DB_NAME} to "${RS_DB_USER}";'
EOS
