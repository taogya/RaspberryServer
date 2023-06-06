#!/bin/sh

trap 'echo "cancel uninstall."; exit 1' 2

# ===== function =================================================="
help() {
    echo "===== Raspberry Server Uninstaller ==========================="
    echo "===== Usage =================================================="
    echo "Argument"
    echo "  shells/uninstall.sh <conf>"
    echo "    <conf>: configuration path."
    echo "ex."
    echo "  $ pwd"
    echo "  /path/to/RaspberryServer"
    echo "  $ cd deploy"
    echo "  $ sudo shells/uninstall.sh conf/pi-srv"
    echo "=============================================================="
}

drop_database() {
    # $1: database name
    # $2: user name
    su - postgres << EOS
psql -U postgres -t -P format=unaligned -c 'drop database $1;'
psql -U postgres -t -P format=unaligned -c "drop user \"$2\";"
EOS
}

delete_for_server() {
    # $1: user name
    pkill -u "$1"
    gpasswd -d www-data "${RS_USR_NAME}"
    deluser "$1"
    rm -rf /home/"${1:?}"
}

remove_uwsgi_service() {
    systemctl daemon-reload
    systemctl stop uwsgi
    systemctl disable uwsgi
    unlink /etc/systemd/system/uwsgi.service
}

remove_nginx_service() {
    systemctl stop nginx
    systemctl disable nginx
    unlink /etc/nginx/sites-available/raspberry-server
    unlink /etc/nginx/sites-enabled/raspberry-server
}

# ===== script =================================================="
if [ "$(whoami)" != "root" ]; then
    echo "===== please execute with root. ===="
    exit 1
fi

if [ "$#" != 1 ]; then
    echo "===== invalid argument. ===="
    help
    exit 1
fi

. "$1"/env.conf

echo "===== disable nginx/uwsgi service ====="
remove_nginx_service
remove_uwsgi_service

echo "===== drop database ====="
printf "Do you drop database? [Y/n]: "
read -r INIT_DONE
case "${INIT_DONE}" in
    [yY]) 
        drop_database "${RS_DB_NAME}" "${RS_USR_NAME}" 
    ;;
esac

echo "===== delete user ====="
printf "Do you remove user? [Y/n]: "
read -r INIT_DONE
case "${INIT_DONE}" in
    [yY])
        delete_for_server "${RS_USR_NAME}"
    ;;
esac

echo "===== remove packages ====="
echo "Dependent packages"
echo "    postgresql nginx libpcre3-dev python3-dev"
printf "Do you remove they? [Y/n]: "
read -r INIT_DONE
case "${INIT_DONE}" in
    [yY])
        apt-get purge --auto-remove -y postgresql nginx libpcre3-dev python3-dev
    ;;
esac
