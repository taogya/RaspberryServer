# Initial Setup on Raspberry Pi
## SD card Setting
You need to get ready work below before writing SD card.
1. write to SD card with Raspberry Pi Imager.  
writing information of it is :  
    - &#9989; Hostname  
    **raspberry-server.local**
    - &#9989; SSH  
    Select **Password Authentication**
    - &#9989; Username and Password  
    Username : **pi-srv**
    Password : **pi012srv**
    - &#9745; Wi-Fi
    - &#9989; Locale  
    Timezone : **Asia/Tokyo**  
    Keboard layout : **jp**
1. modify files below in /boot.
    - config.txt  
    ```sh
    :  
    [all]  
    dtoverlay=dwc2  
    :
    ```
    - cmdline.txt  
    ```sh
    .. rootwait modules-load=dwc2,g_ether quiet ..
    ```
1. set SD card to Raspberry Pi, and launch.


## Package update
You update it with commnad below.
```sh
$ sudo apt-get update
$ sudo apt-get upgrade
$ sudo apt-get dist-upgrade
$ sudo reboot now
```

## (Optional) Change console style for root
You set console color to red.
```sh
$ sudo vi /root/.bashrc
:
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w \$\[\033[00m\] '
:
```

## (Optional) Resolve Bluetooth service error
You will resolve error below.
```sh
$ sudo systemctl status bluetooth.service
:
Apr 30 22:19:44 raspberrypi bluetoothd[886]: profiles/sap/server.c:sap_server_register() Sap driver initialization failed.
Apr 30 22:19:44 raspberrypi bluetoothd[886]: sap-server: Operation not permitted (1)
Apr 30 22:19:44 raspberrypi bluetoothd[886]: Failed to set privacy: Rejected (0x0b)
```
1. modify service file
    ```sh
    $ sudo vi /lib/systemd/system/bluetooth.service
    ：
    ExecStart=/usr/libexec/bluetooth/bluetoothd --noplugin=sap
    ：
    ```
1. add helper service file
    ```sh
    $ sudo chmod 600 /etc/systemd/system/bthelper@.service.d/
    $ sudo vi /etc/systemd/system/bthelper@.service.d/override.conf
    [Unit]
    After=hciuart.service bluetooth.service
    Before=
    
    [Service]
    ExecStartPre=/bin/sleep 5
    ```
1. restart service
    ```sh
    $ sudo systemctl daemon-reload
    $ sudo systemctl restart bluetooth
    ```

## (Optional) SSH Connection Setting
You configure Public-key Authentication for SSH.
```sh
$ mkdir ~/.ssh
$ sudo vi .ssh/authorized_keys
-> copied public key.
$ sudo vi /etc/ssh/sshd_config.d/pi-srv.conf
Port 2222
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication no
$ sudo chmod 600 /etc/ssh/sshd_config.d/pi-srv.conf
$ sudo systemctl restart sshd
$ sudo reboot now
```

try to connect to Raspberry Pi with Public-key Authentication.

## (Optional) Hostname change
```sh
$ sudo vi /etc/hostname
raspberrypi -> raspberry-server
$ sudo vi /etc/hosts
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

127.0.1.1       raspberrypi -> raspberry-server
```
