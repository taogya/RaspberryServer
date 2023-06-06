# Setup for development on Raspberry pi
## (Optional) Add user for server
```sh
$ sudo adduser --disabled-password pi-srv
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
    $ sudo systemctl start postgresql.service
    $ sudo systemctl enable postgresql.service
    $ sudo systemctl status postgresql.service
    ```
1. Client configuration
    ```sh
    $ sudo su - postgres
    $ createuser -P pi-srv
    -> password
    $ createdb -E UTF8 -O pi-srv raspberry_server_db
    $ psql
    postgres=# grant all on database raspberry_server_db to pi-srv;
    ```
    cf. [commands](https://www.postgresql.jp/document/9.2/html/reference-client.html)

## Setup Web Application with Django
1. package installation
    ```sh
    $ sudo apt-get install -y python3-dev
    ```

1. make executing python environment
    ```sh
    $ cd /path/to/RaspberryServer
    $ python -m venv .venv
    $ . .venv/bin/activate
    ```

1. make executing Django environment
    ```sh
    $ pip install isort flake8 autopep8 radon
    $ pip install Django psycopg2-binary django-debug-toolbar
    $ django-admin startproject pi
    $ sudo sh deploy/shells/secret_key_gen.sh deploy/conf/pi-srv/env.conf
    -> set output to RS_PRJ_SECRET_KEY in deploy/conf/pi-srv/env.conf
    $ mkdir pi/templates pi/static pi/logs
    $ vi pi/pi/settings.py
    ```
    ```python
    :
    import os
    from django.conf.global_settings import DATETIME_INPUT_FORMATS
    :
    SECRET_KEY = os.environ['RS_PRJ_SECRET_KEY']
    :
    DEBUG = os.environ['RS_PRJ_DEBUG'] == 1
    :
    ALLOWED_HOSTS = os.environ['RS_PRJ_ALLOWED_HOSTS'].split(',')
    :
    PROJECT_APPS = [
    ]
    INSTALLED_APPS += PROJECT_APPS
    :
    TEMPLATES = [
    :
            'DIRS': [os.path.join(BASE_DIR, 'templates')],
    :
    DATABASES = {
        'default': {
            'ENGINE': os.environ['RS_DB_ENGINE'],
            'NAME': os.environ['RS_DB_NAME'],
            'USER': os.environ['RS_DB_USER'],
            'PASSWORD': os.environ['RS_DB_PASSWORD'],
            'HOST': os.environ['RS_DB_HOST'],
            'PORT': os.environ['RS_DB_PORT'],
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
    STATIC_ROOT = os.path.join(BASE_DIR, 'collectstatic')
    STATICFILES_DIRS = (
        os.path.join(BASE_DIR, 'static'),
    )
    :
    # CommonLogger Settings
    LOG_BASE_DIR = os.path.join(BASE_DIR, 'logs')
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
                "filename": os.path.join(LOG_BASE_DIR, "general.log"),
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
    $ set -o allexport; . deploy/conf/pi-srv/env.conf; set +o allexport
    $ python pi/manage.py makemigrations
    $ python pi/manage.py migrate
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
    $ pip install uwsgi
    ```
1. modify configration
    ```sh
    $ vi deploy/conf/pi-srv/uwsgi.service
    -> modify as needed.
    $ vi deploy/conf/pi-srv/uwsgi.ini
    -> modify as needed. (if do connection test, uncomment "http")
    ```
1. create and start service
    ```sh
    $ sudo ln -s /home/pi-srv/app/RaspberryServer/deploy/conf/pi-srv/uwsgi.service /etc/systemd/system/uwsgi.service
    $ sudo systemctl daemon-reload
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
    $ cp /etc/nginx/uwsgi_params deploy/conf/pi-srv/uwsgi_params
    $ vi deploy/conf/pi-srv/raspberry-server
    -> modify as needed
    ```
1. create and start service
    ```sh
    $ sudo ln -s /home/pi-srv/app/RaspberryServer/deploy/conf/pi-srv/raspberry-server /etc/nginx/sites-available/raspberry-server
    $ sudo ln -s /etc/nginx/sites-available/raspberry-server /etc/nginx/sites-enabled/raspberry-server
    $ set -o allexport; . deploy/conf/pi-srv/env.conf; set +o allexport
    $ python pi/manage.py collectstatic
    $ sudo systemctl enable nginx
    $ sudo systemctl start nginx
    ```

