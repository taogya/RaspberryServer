#!/bin/sh

trap 'echo "cancel install."; exit 1' 2

# ===== function =================================================="
help() {
    echo "===== Raspberry Server Installer ============================="
    echo "===== Usage =================================================="
    echo "Argument"
    echo "  shells/install.sh <user> <conf>"
    echo "    <user>: project administrator."
    echo "            added if user does not exists."
    echo "    <conf>: configuration path."
    echo "ex."
    echo "  $ cd deploy"
    echo "  $ cp -r conf/template conf/pi-srv"
    echo "    -> modify files in conf/pi-srv"
    echo "  $ sudo shells/install.sh pi-srv conf/pi-srv"
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
    db_exists=$(sudo su - postgres << EOS
psql -U postgres -t -P format=unaligned -c "select datname from pg_database where datname = '$1';"
EOS
)
    su - postgres << EOS
if [ -z "${db_exists}" ]; then 
echo "===== create database ====="
psql -U postgres -t -P format=unaligned -c 'create database $1 encoding utf8;'
psql -U postgres -t -P format=unaligned -c "create user \"$2\" with password '$3';"
psql -U postgres -t -P format=unaligned -c 'alter database $1 owner to "$2";'
psql -U postgres -t -P format=unaligned -c 'grant all on database $1 to "$2";'
fi
EOS
}

install_django() {
    # $1: user name
    # $2: conf path
    . "$2/.env"
    app_name=$(basename "${BASE_DIR}")
    echo "===== install django ====="
    apt-get install -y python3-dev python3-venv
    su - "$1" << EOS
mkdir -p "${BASE_DIR}"
if ! ls ${VENV_DIR} > /dev/null 2>&1; then
echo "===== make venv"
python -m venv ${VENV_DIR}
fi
echo "===== pip install"
. ${VENV_DIR}/bin/activate
pip install isort flake8 autopep8 radon
pip install Django psycopg2-binary django-environ
if [ ${DEBUG} = True ]; then
pip install django-debug-toolbar
fi
if ! ls ${BASE_DIR}/${app_name} > /dev/null 2>&1; then
echo "===== create project"
django-admin startproject ${app_name} ${BASE_DIR}
mkdir -p ${BASE_DIR}/templates
mkdir -p ${BASE_DIR}/static
fi
EOS
    cp -f "$2"/settings.py "${BASE_DIR}/${app_name}/settings.py"
    cp -f "$2"/.env "${BASE_DIR}/${app_name}/.env"
    
    if [  -z "${SECRET_KEY}" ]; then
        echo "===== set secret-key"
        temp_secret_key=$(sudo su - "$1" << EOS
. ${VENV_DIR}/bin/activate
python -c "from django.core.management.utils import get_random_secret_key;print(get_random_secret_key())"
EOS
)
        sed -i "s/SECRET_KEY=/SECRET_KEY=\"${temp_secret_key}\"/g" "${BASE_DIR}"/"${app_name}"/.env
    fi
    rm -rf "${STATIC_ROOT}"
    mkdir -p "${STATIC_ROOT}"
    mkdir -p "${LOG_DIR}"
    chown -R "$1":"$1" "$(dirname "${BASE_DIR}")"
    su - "$1" << EOS
echo "===== migration"
. ${VENV_DIR}/bin/activate
python ${BASE_DIR}/manage.py makemigrations
python ${BASE_DIR}/manage.py migrate
python ${BASE_DIR}/manage.py collectstatic
EOS
}

install_uwsgi() {
    # $1: user name
    # $2: conf path
    echo "===== install uwsgi ====="
    . "$2/.env"
    apt-get install -y libpcre3-dev
    mkdir -p /var/log/uwsgi
    chown -R "$1":"$1" /var/log/uwsgi
    su - "$1" << EOS
. "${VENV_DIR}"/bin/activate
pip install uwsgi
EOS
    echo "===== enable uwsgi service ====="
    ln -fs "$2"/uwsgi/uwsgi.service /etc/systemd/system/uwsgi.service
    systemctl daemon-reload
    systemctl stop uwsgi
    systemctl enable uwsgi
    systemctl start uwsgi
}

install_nginx() {
    # $1: conf path
    echo "===== install nginx ====="
    apt-get install -y nginx
    echo "===== enable nginx service ====="
    for d in "$1"/nginx/*
    do
        file_name=$(basename "${d}")
        ln -fs "${d}" /etc/nginx/sites-available/"${file_name}"
        ln -fs /etc/nginx/sites-available/"${file_name}" /etc/nginx/sites-enabled/"${file_name}"
    done
    #gpasswd -a www-data "${RS_USR_NAME}"
    systemctl stop nginx
    systemctl enable nginx
    systemctl start nginx
}

# ===== script =================================================="
if [ "$(whoami)" != "root" ]; then
    echo "===== please execute with root. ===="
    exit 1
fi

if [ "$#" != 2 ]; then
    echo "===== invalid argument. ===="
    help
    exit 1
fi

. "$2"/.env
proj_dir="$(dirname "${BASE_DIR}")"
conf_dir="${proj_dir}/conf"

if ls "${proj_dir}" > /dev/null 2>&1; then
    echo "Already exists ${proj_dir}."
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

adduser_for_server "$1"

install_postgresql
create_database "${DB_NAME}" "$1" "${DB_PASSWORD}"

echo "===== copy conf file =====" 
mkdir -p "${conf_dir}"
\cp -rf "$2"/. "${conf_dir}"
chown -R "$1":"$1" "${proj_dir}"

install_django "$1" "${conf_dir}"
install_uwsgi "$1" "${conf_dir}"
install_nginx "${conf_dir}"

echo "===== please manually execute below"
echo "sudo su - $1"
echo ". ${VENV_DIR}/bin/activate"
echo "cd ${BASE_DIR}"
echo "python manage.py createsuperuser"

echo "===== Finish!! ====="

exit 0
