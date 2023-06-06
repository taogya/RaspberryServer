# RaspberryServer
Web Server with Django for Raspberry Pi in stand-alone system.  
You can be easy to develop environment by using this installer.

# Installation
```sh
$ mkdir -p ~/work && cd ~/work
$ git clone https://github.com/taogya/RaspberryServer.git
$ cd RaspberryServer/deploy
$ cp -r conf/template conf/pi-srv 
-> edit files in conf/pi-srv
$ chmod +x shells/install.sh
$ sudo sh shells/install.sh conf/pi-srv
$ 
$ sudo su - your_name
$ cd /path/to/deploy_dir/app_name
$ set -o allexport; . ../deploy/conf/pi-srv/env.conf; set +o allexport
$ . ../.venv/bin/activate
$ python manage.py createsuperuser
$ python manage.py collectstatic
```
access to http://your_server_name/admin

# Unnstallation
```sh
$ sudo sh shells/uninstall.sh conf/pi-srv
```

# Manual Installation
You please see [doc](./deploy/doc/README.md).

# Note
This Project was only verified on Raspberry Pi 4.  
I don't verify yet on other Pi. 
