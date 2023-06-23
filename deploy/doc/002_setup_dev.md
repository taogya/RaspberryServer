# Setup for development on Raspberry pi
## (Optional) Add user for server
```sh
$ sudo adduser --disabled-password --gecos "" pi-srv
$ sudo chmod 750 /home/pi-srv
```

## (Optional) Firewall Setting
```sh
$ sudo apt-get install ufw
$ sudo ufw allow 22/tcp
$ sudo ufw allow 2222/tcp
$ sudo ufw allow 80/tcp
$ sudo ufw allow 8080/tcp
$ sudo ufw enable
$ sudo ufw status
```

## Setup Database with PostgreSQL
1. Installation Middleware
    ```sh
    $ sudo apt-get install -y postgresql
    ```
1. Server configuration
    ```sh
    $ PG_HBA=$(sudo su - postgres << EOS
    psql -U postgres -t -P format=unaligned -c 'show hba_file'
    EOS
    )
    $ echo "${PG_HBA}"
    /etc/postgresql/13/main/pg_hba.conf
    $ sudo vi "${PG_HBA}"
    -> change auth-method as needed
    $ sudo systemctl stop postgresql.service
    $ sudo systemctl enable postgresql.service
    $ sudo systemctl start postgresql.service
    $ sudo systemctl status postgresql.service
    ```
1. Client configuration
    ```sh
    $ sudo su - postgres << EOS
    psql -U postgres -t -P format=unaligned -c 'create database raspberry_server_db encoding utf8;'
    psql -U postgres -t -P format=unaligned -c "create user \"pi-srv\" with password 'pi-srv#pass';"
    psql -U postgres -t -P format=unaligned -c 'alter database raspberry_server_db owner to "pi-srv";'
    psql -U postgres -t -P format=unaligned -c 'grant all on database raspberry_server_db to "pi-srv";'
    EOS
    ```
    cf. [commands](https://www.postgresql.jp/document/9.2/html/reference-client.html)

## Setup Web Application with Django
1. package installation
    ```sh
    $ sudo apt-get install -y python3-dev python3-venv
    ```

1. make executing python environment
    ```sh
    $ sudo su - pi-srv
    $ mkdir -p app/RaspberryServer
    $ cd app/RaspberryServer
    $ python -m venv .venv
    $ . .venv/bin/activate
    ```

1. make executing Django environment
    ```sh
    $ pip install isort flake8 autopep8 radon
    $ pip install Django psycopg2-binary django-debug-toolbar django-environ
    $ django-admin startproject pi
    $ python -c "from django.core.management.utils import get_random_secret_key;print(get_random_secret_key())"
    -> set output to SECRET_KEY in .env
    # create .env at same directory to settings.py
    $ vi pi/pi/.env
    # ### Project Configration
    # BASE_DIR should be project_dir/app_name.
    BASE_DIR=/home/pi-srv/app/RaspberryServer/pi
    VENV_DIR=/home/pi-srv/app/RaspberryServer/.venv
    STATIC_ROOT=/home/pi-srv/app/RaspberryServer/static
    LOG_DIR=/home/pi-srv/app/RaspberryServer/log
    # ### Database Configration
    DB_ENGINE=django.db.backends.postgresql
    DB_NAME=raspberry_server_db
    # If DB authentication method is peer, it should be same as RS_USR_NAME.
    DB_USER=pi-srv
    DB_PASSWORD="pi-srv#pass"
    DB_HOST=localhost
    DB_PORT=5432
    # ### Application Configration
    # auto set if SECRET_KEY is empty.
    SECRET_KEY=
    ALLOWED_HOSTS=localhost,raspberry-server.local
    DEBUG=True
    ROOT_URLCONF=pi.urls
    WSGI_APPLICATION=pi.wsgi.application

    $ mkdir pi/templates pi/static log static
    $ vi pi/pi/settings.py
    ```
    ```python
    :
    import os
    from pathlib import Path

    import environ
    from django.conf.global_settings import DATETIME_INPUT_FORMATS

    # Take environment variables from .env file
    env = environ.Env(
        # set casting, default value
        DEBUG=(bool, False)
    )
    environ.Env.read_env(os.path.join(Path(__file__).resolve().parent, '.env'))

    # Build paths inside the project like this: BASE_DIR / 'subdir'.
    BASE_DIR = env('BASE_DIR')
    :
    SECRET_KEY = env('SECRET_KEY')
    :
    DEBUG = env('DEBUG')
    :
    ALLOWED_HOSTS = env.list('ALLOWED_HOSTS')
    :
    PROJECT_APPS = [
    ]
    INSTALLED_APPS += PROJECT_APPS
    :
    ROOT_URLCONF = env('ROOT_URLCONF')

    TEMPLATES = [
    :
            'DIRS': [os.path.join(BASE_DIR, 'templates')],
    :
    WSGI_APPLICATION = env('WSGI_APPLICATION')
    :
    DATABASES = {
        'default': {
            'ENGINE': env(_DB_ENGINE'),
            'NAME': env('DB_NAME'),
            'USER': env('DB_USER'),
            'PASSWORD': env('DB_PASSWORD'),
            'HOST': env('DB_HOST'),
            'PORT': int(env('DB_PORT')),
        },
    }
    :
    LANGUAGE_CODE = 'ja'
    TIME_ZONE = 'Asia/Tokyo'
    USE_I18N = True
    USE_TZ = True
    DATETIME_FORMAT = 'Y/m/d H:i:s'
    USE_L10N = False
    DATETIME_INPUT_FORMATS += ('%Y-%m-%d %H:%M:%S.%f%z',)
    :
    STATIC_URL = '/static/'
    STATIC_ROOT = env('STATIC_ROOT')
    STATICFILES_DIRS = (
        os.path.join(BASE_DIR, 'static'),
    )
    :
    # CommonLogger Settings
    LOG_DIR = env('LOG_DIR')
    LOGGING = {
        "version": 1,
        "disable_existing_loggers": False,
        "root": {
            "handlers": ["console"],
            "level": "DEBUG",
            "propagate": False,
        },
        "formatters": {
            "verbose": {
                "format": "[{asctime}][{module}][{process:d}][{thread:d}][{levelname}][{message}]",
                "style": "{",
            },
            "simple": {
                "format": "[{asctime}][{levelname}][{message}]",
                "style": "{",
            },
        },
        "handlers": {
            "console": {
                "level": "INFO",
                "class": "logging.StreamHandler",
                "formatter": "simple",
            },
            "general": {
                "level": "INFO",
                "class": "logging.handlers.WatchedFileHandler",
                "filename": os.path.join(LOG_DIR, "general.log"),
                "formatter": "simple",
            },
        },
        "loggers": {
            "django": {
                "handlers": ["console"],
                "propagate": False,
            },
            "general": {
                "handlers": ["console"],
                "propagate": False,
            },
        },
    }

    # Debug Settings
    if DEBUG:
        INSTALLED_APPS += [
            'debug_toolbar',
        ]

        MIDDLEWARE += [
            'debug_toolbar.middleware.DebugToolbarMiddleware',
        ]
    ```

1. access test
    ```sh
    $ python pi/manage.py makemigrations
    $ python pi/manage.py migrate
    $ python pi/manage.py collectstatic
    $ python pi/manage.py createsuperuser
    -> input info of super user
    $ python pi/manage.py runserver 0.0.0.0:8080
    ```
    try access URL below on local browser after configure ssh port forwarding.
    http://localhost:8080/admin

## Setup Appllication Server with uWSGI
1. package installation
    ```sh
    $ sudo apt-get install libpcre3-dev
    $ sudo su - pi-srv
    $ cd app/RaspberryServer
    $ . .venv/bin/activate
    $ pip install uwsgi
    ```
1. modify configration
    ```sh
    $ mkdir -p conf/uwsgi
    $ vi conf/uwsgi/uwsgi.service
    [Unit]
    Description=uWSGI Service
    After=syslog.target

    [Service]
    User=pi-srv
    Group=pi-srv
    WorkingDirectory=/home/pi-srv/app/RaspberryServer/
    ExecStart=/bin/sh -c '\
        . .venv/bin/activate;\
        uwsgi --ini conf/uwsgi/uwsgi.ini;\
    '
    RuntimeDirectory=uwsgi
    Restart=always
    KillSignal=SIGQUIT
    StandardError=syslog
    Type=notify
    NotifyAccess=all

    [Install]
    WantedBy=multi-user.target

    $ vi conf/uwsgi/uwsgi.ini
    [uwsgi]
    # same to VENV_DIR
    home = /home/pi-srv/app/RaspberryServer/.venv

    socket = /var/run/uwsgi/uwsgi.sock
    pidfile = /var/run/uwsgi/master.pid
    http = 0.0.0.0:8080
    master = true
    vacuum = true
    chmod-socket = 666
    uid = pi-srv
    gid = pi-srv

    processes = 2
    enable-threads = true
    threads = 4

    logto = /var/log/uwsgi/uwsgi.log
    log-reopen = true
    log-x-forwarded-for = true

    # same to BASE_DIR
    chdir = /home/pi-srv/app/RaspberryServer/pi
    wsgi-file = /home/pi-srv/app/RaspberryServer/pi/pi/wsgi.py
    # same to STATIC_ROOT
    static-map = /static=/home/pi-srv/app/RaspberryServer/static
    harakiri = 20
    max-requests = 5000
    buffer-size = 32768
    ```
1. create and connection test
    ```sh
    $ sudo ln -fs /home/pi-srv/app/RaspberryServer/conf/uwsgi/uwsgi.service /etc/systemd/system/uwsgi.service
    $ sudo systemctl daemon-reload
    $ sudo systemctl stop uwsgi
    $ sudo systemctl start uwsgi
    ```
    try access URL below on local browser after configure ssh port forwarding.
    http://localhost:8080/admin
1. reconfig and start service
    ```sh
    $ sudo sed -i 's/http = 0.0.0.0:8080/#http = 0.0.0.0:8080/g' /home/pi-srv/app/RaspberryServer/conf/uwsgi/uwsgi.ini
    $ sudo systemctl stop uwsgi
    $ sudo systemctl enable uwsgi
    $ sudo systemctl start uwsgi
    ```

## Setup Web Server with nginx
1. package installation
    ```sh
    $ sudo apt-get install -y nginx
    ```
1. modify configration
    ```sh
    $ mkdir -p conf/nginx
    $ vi conf/nginx/raspberry-server.conf
    upstream django {
        # set socket name set by set uwsgi.ini.
        server unix:///var/run/uwsgi/uwsgi.sock;
    }

    server {
        listen      80;
        # set your allowed host.
        server_name localhost raspberry-server.local;
        charset     utf-8;
        
        # set your log directory.
        access_log  /var/log/nginx/access.log;
        error_log   /var/log/nginx/error.log; 

        location / {
            uwsgi_pass django;
            include uwsgi_params;
        }
    }
    ```
1. create and start service
    ```sh
    $ sudo ln -fs /home/pi-srv/app/RaspberryServer/conf/nginx/raspberry-server.conf /etc/nginx/sites-available/raspberry-server.conf
    $ sudo ln -fs /etc/nginx/sites-available/raspberry-server.conf /etc/nginx/sites-enabled/raspberry-server.conf
    $ sudo systemctl stop nginx
    $ sudo systemctl enable nginx
    $ sudo systemctl start nginx
    ```
    try access URL below on local browser after configure ssh port forwarding.
    http://localhost:8888/admin

