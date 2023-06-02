#!/bin/sh

# ex. 
# $ pwd
# /home/pi-srv/RaspberryServer/deploy
# $ sudo sh shells/secret_key_gen.sh conf/template/env.conf

# import environment variables
. "$1"

# generate secret key
SECRET_KEY=$(sudo su - "${RS_USR_NAME}" << EOS
. "${RS_PRJ_VENV}"/bin/activate
python -c "from django.core.management.utils import get_random_secret_key;print(get_random_secret_key())"
EOS
)

# print secret key
echo "django-insecure-${SECRET_KEY}"