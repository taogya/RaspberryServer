# RaspberryServer
Web Server with Django for Raspberry Pi in stand-alone system

# Installation
```sh
$ mkdir -p ~/app && cd ~/app
$ git clone https://github.com/taogya/RaspberryServer.git
$ cd RaspberryServer/deploy
$ cp -r deploy/conf/template deploy/conf/pi-srv 
-> edit files in pi-srv
$ sudo sh auto-setup.sh pi-srv
```

# Manual Installation
You please see [doc](./deploy/doc/README.md).

# Note
This Project was only verified on Raspberry Pi 4.  
I don't verify yet on other Pi. 