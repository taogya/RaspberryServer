#!/bin/sh

# ex. 
# $ pwd
# /home/pi-srv/RaspberryServer/deploy
# $ sh shells/set_env.sh conf/pi-srv/env.conf

# import environment variables
. "$1"

# set environment configuration
set -o allexport; . "${RS_PRJ_CONF}/env.conf"; set +o allexport