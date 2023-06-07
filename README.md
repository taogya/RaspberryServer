# RaspberryServer
Web Server with Django for Raspberry Pi in stand-alone system.  
You can be easy to develop environment by using this installer.

# Installation
You execute command below after writing SD card.
```sh
$ sudo apt-get update
$ sudo apt-get upgrade
$ sudo apt-get dist-upgrade
$ 
$ mkdir -p ~/work && cd ~/work
$ git clone https://github.com/taogya/RaspberryServer.git
$ cd RaspberryServer/deploy
$ cp -r conf/template conf/pi-srv 
-> edit files in conf/pi-srv
$ chmod -R +x shells
$ sudo sh shells/install.sh conf/pi-srv
```
access to http://your_server_name/admin

# Unnstallation
```sh
$ sudo sh shells/uninstall.sh conf/pi-srv
```

# Manual Installation
You please see [doc](./deploy/doc/README.md).

# Note
Verified:
  OS - bullseye
  Pi - 4B
