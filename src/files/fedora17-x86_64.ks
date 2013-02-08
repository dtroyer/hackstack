install
text
keyboard us
lang en_US.UTF-8
skipx
network --device eth0 --bootproto dhcp
rootpw rootpa$$
firewall --disabled
authconfig --enableshadow --enablemd5
selinux --enforcing
timezone --utc America/New_York
bootloader --location=mbr
zerombr
clearpart --all --drives=vda

part / --size  8192 --fstype ext4 --ondisk vda --grow
part swap --size 1024 --fstype swap --grow --maxsize 2048
reboot

bootloader --location=mbr --timeout=5 --append="console=tty console=ttyS0"

%packages --nobase
#@base
@core
#@hardware-support

bash
mdadm
device-mapper
less
openssh-clients
screen
wget
yum

-biosdevname
#-*-firmware
-sendmail

%end

%post --erroronfail

# create user
#/usr/sbin/useradd stack
#/bin/echo -e 'stack\tALL=(ALL)\tNOPASSWD: ALL' >>/etc/sudoers.d/99-stack

%end
