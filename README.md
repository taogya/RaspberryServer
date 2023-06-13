# RaspberryServer
Web Server with Django for Raspberry Pi in stand-alone system.  
You can be easy to develop environment by using this installer.  
This installer makes environment below.
```
Web               Application       Web
Application       Server            Server
+------------+    +------------+    +------------+ http
| Django     | -> | uWSGI      | -> | nginx      | ->  
|            | <- |            | <- |            | <-
+------------+    +------------+    +------------+ 
  ^ |                       able to access 
  | v                         http://your_server_name/admin
Database
+------------+
| PostgreSQL |
|            |
+------------+
```


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
-> **caution**
->   do not use environment variables in env.conf
$ chmod -R +x shells
$ sudo sh shells/install.sh conf/pi-srv
```
access to http://your_server_name/admin

# Unistallation
```sh
$ sudo sh shells/uninstall.sh conf/pi-srv
```

# Manual Installation
You please see [doc](./deploy/doc/README.md).

# Note
| verify | OS |
| ------ | -- |
| &#9989; | bullseye |
| &#9745; | buster |

| verify | Pi |
| ------ | -- |
| &#9989; | 4 B |
| &#9745; | 3 B+ |
| &#9989; | Zero W |
