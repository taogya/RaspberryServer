#!/bin/sh

trap 'echo "cancel install."; exit 1' 2

# ===== function =================================================="
help() {
    echo "===== Raspberry Server Installer ============================="
    echo "===== Usage =================================================="
    echo "Argument"
    echo "  shells/install.sh <conf>"
    echo "    <conf>: configuration path."
    echo "ex."
    echo "  $ pwd"
    echo "  /path/to/RaspberryServer"
    echo "  $ cd deploy"
    echo "  $ cp -r conf/template conf/pi-srv"
    echo "    -> modify files in conf/pi-srv"
    echo "  $ sudo shells/install.sh conf/pi-srv"
    echo "=============================================================="
}

adduser_for_server() {
    # $1: user name
    if ! grep "$1" /etc/passwd > /dev/null 2>&1; then
        echo "===== add user for server ====="
        adduser --disabled-password --gecos "" "$1"
    fi
}

install_postgresql() {
    if ! systemctl is-active postgresql > /dev/null 2>&1; then
        echo "===== install postgresql ====="
        apt-get install -y postgresql
        systemctl start postgresql.service
        systemctl enable postgresql.service
    fi
}

create_database() {
    # $1: database name
    # $2: user name
    # $3: user password
    echo "===== create database ====="
    su - postgres << EOS
psql -U postgres -t -P format=unaligned -c 'create database $1 encoding utf8;'
psql -U postgres -t -P format=unaligned -c "create user \"$2\" with password '$3';"
psql -U postgres -t -P format=unaligned -c 'alter database $1 owner to "$2";'
psql -U postgres -t -P format=unaligned -c 'grant all on database $1 to "$2";'
EOS
}

install_django() {
    echo "===== install django ====="
    apt-get install -y python3-dev python3-venv
    su - "${RS_USR_NAME}" << EOS
mkdir -p "${RS_PRJ_ROOT}/${RS_PRJ_APP}"
if ! ls "${RS_PRJ_VENV}" > /dev/null 2>&1; then
echo "===== make venv"
python -m venv "${RS_PRJ_VENV}"
fi
echo "===== pip install"
. "${RS_PRJ_VENV}"/bin/activate
pip install isort flake8 autopep8 radon
pip install Django psycopg2-binary
if [ "${RS_PRJ_DEBUG}" = 1 ]; then
pip install django-debug-toolbar
fi
if ! ls "${RS_PRJ_ROOT}/${RS_PRJ_APP}/${RS_PRJ_APP}" > /dev/null 2>&1; then
echo "===== create project"
django-admin startproject "${RS_PRJ_APP}" "${RS_PRJ_ROOT}/${RS_PRJ_APP}"
mkdir -p "${RS_PRJ_ROOT}/${RS_PRJ_APP}/templates"
mkdir -p "${RS_PRJ_ROOT}/${RS_PRJ_APP}/static"
mkdir -p "${RS_PRJ_ROOT}/${RS_PRJ_APP}/logs"
fi
EOS
    echo "===== copy base file" 
    cp -f ../pi/manage.py "${RS_PRJ_ROOT}/${RS_PRJ_APP}/manage.py"
    cp -f ../pi/pi/asgi.py "${RS_PRJ_ROOT}/${RS_PRJ_APP}/${RS_PRJ_APP}/asgi.py"
    cp -f ../pi/pi/wsgi.py "${RS_PRJ_ROOT}/${RS_PRJ_APP}/${RS_PRJ_APP}/wsgi.py"
    cp -f ../pi/pi/settings.py "${RS_PRJ_ROOT}/${RS_PRJ_APP}/${RS_PRJ_APP}/settings.py"
    
    if [  -z "${RS_PRJ_SECRET_KEY}" ]; then
        echo "===== set secret-key"
        TMP_SECRET_KEY=$(shells/secret_key_gen.sh "${RS_PRJ_CONF}/env.conf")
        sed -i "s/RS_PRJ_SECRET_KEY=/RS_PRJ_SECRET_KEY=\"${TMP_SECRET_KEY}\"/g" "${RS_PRJ_CONF}"/env.conf
    fi
    rm -rf "${RS_PRJ_STATIC_ROOT}"
    mkdir -p "${RS_PRJ_STATIC_ROOT}"
    chown -R "${RS_USR_NAME}":"${RS_USR_NAME}" "${RS_PRJ_STATIC_ROOT}"
    su - "${RS_USR_NAME}" << EOS
echo "===== migration"
set -o allexport; . "${RS_PRJ_CONF}/env.conf"; set +o allexport
. "${RS_PRJ_VENV}"/bin/activate
python "${RS_PRJ_ROOT}/${RS_PRJ_APP}"/manage.py makemigrations
python "${RS_PRJ_ROOT}/${RS_PRJ_APP}"/manage.py migrate
python "${RS_PRJ_ROOT}/${RS_PRJ_APP}"/manage.py collectstatic
EOS
}

install_uwsgi() {
    echo "===== install uwsgi ====="
    apt-get install -y libpcre3-dev
    mkdir -p /var/log/uwsgi
    chown -R "${RS_USR_NAME}":"${RS_USR_NAME}" /var/log/uwsgi
    su - "${RS_USR_NAME}" << EOS
. "${RS_PRJ_VENV}"/bin/activate
pip install uwsgi
EOS
    echo "===== enable uwsgi service ====="
    ln -fs "${RS_PRJ_CONF}"/uwsgi.service /etc/systemd/system/uwsgi.service
    systemctl daemon-reload
    systemctl enable uwsgi
    systemctl start uwsgi
}

install_nginx() {
    echo "===== install nginx ====="
    apt-get install -y nginx
    echo "===== enable nginx service ====="
    ln -fs "${RS_PRJ_CONF}"/raspberry-server /etc/nginx/sites-available/raspberry-server
    ln -fs /etc/nginx/sites-available/raspberry-server /etc/nginx/sites-enabled/raspberry-server
    gpasswd -a www-data "${RS_USR_NAME}"
    systemctl enable nginx
    systemctl start nginx
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

if ls "${RS_PRJ_ROOT}" > /dev/null 2>&1; then
    echo "Already exists ${RS_PRJ_ROOT}."
    printf "Do you initialize? [Y/n]: "
    read -r INIT_DONE
    case "${INIT_DONE}" in
        [yY]) shells/uninstall.sh "$1" ;;
    esac
fi

if ! ping -c 4 8.8.8.8 > /dev/null 2>&1; then
    echo "===== can not connect to internet. ====";
    exit 1
fi

adduser_for_server "${RS_USR_NAME}"
install_postgresql
create_database "${RS_DB_NAME}" "${RS_USR_NAME}" "${RS_DB_PASSWORD}"

echo "===== copy conf file =====" 
mkdir -p "${RS_PRJ_CONF}"
cp -f "$1"/* "${RS_PRJ_CONF}"
chmod -R 770 "${RS_PRJ_ROOT}"
chown -R "${RS_USR_NAME}":"${RS_USR_NAME}" "${RS_PRJ_ROOT}"

install_django
install_uwsgi
install_nginx

echo "===== please manually execute below"
echo "sudo su - ${RS_USR_NAME}"
echo "set -o allexport; . ${RS_PRJ_CONF}/env.conf; set +o allexport"
echo ". ${RS_PRJ_VENV}/bin/activate"
echo "cd ${RS_PRJ_ROOT}/${RS_PRJ_APP}"
echo "python manage.py createsuperuser"

echo "===== Finish!! ====="

exit 0
