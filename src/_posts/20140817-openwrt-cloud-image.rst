---
title: OpenWRT Images for OpenStack
author: dtroyer
date: 2014-08-17 08:17:00
categories: OpenStack, OpenWRT
tags: image openwrt
---

I've been playing with `OpenWRT`_ since <mumble>-<mumble> and have enjoyed building some of the smallest Linux images around.  While targeted at low-end home router platforms, it also runs on a wide variety of small SoC boards including the near-ubiqutious Raspberry Pi and my fave BeagleBone Black.

.. _`OpenWRT`: http://openwrt.org

I've also been using an incredibly tiny OpenWRT instance on my laptop for years now to work around the 'interesting' network configuration of VirtualBox.  Building a set of VMs that need to talk to each other and to the outside world shouldn't be hard, so I added a router just like I have at home in a 48Mb VM.

While OpenStack typically doesn't have that need (but you never know how Neutron might be configured!) there are plenty of other purposes for such a small single-purpose VM.  So let's build one!

The magic in this cloud build is having an analogue to smoser's `cloud-init`_.  The original is written in Python and has a lot of very useful features, but requiring the Python stdlib and ``cloud-init`` dependencies to be installed expands the size of the root image considerably.   My version, called `rc.cloud`_, is a set of shell scripts that implement a small subset of ``cloud-init`` capabilities.  [Note: I 'borrowed' the original scripts from somewhere over three years ago and for the life of me can't find out where now.  Pointers welcome.]

.. _`cloud-init`: https://launchpad.net/cloud-init
.. _`rc.cloud`: https://github.com/dtroyer/openwrt-packages/tree/master/rc.cloud

One of the most important features of ``cloud-init`` and ``rc.cloud`` is configuring a network interface and enabling remote access.  OpenWRT defaults to no root password so I have to telnet to 192.168.1.1 to set root's password before Dropbear (a tiny ssh2 implementation) allows logins. Doing it with ``cloud-init`` or ``rc.cloud`` instead allows automation and is a Wonderful Thing(TM).

This isn't a detailed How-To on building OpenWRT, there are a lot of `good docs`_ covering that topic.  It _is_ however, the steps I use plus some additional tweaks useful in a KVM-based OpenStack cloud.

.. _`good docs`: http://wiki.openwrt.org/doc/howto/build

Build Image From Source
=======================

The basic build is straight out of the `OpenWRT wiki`_.  I could have used the Image Builder, but I have some additional packages to include and like having control over the build configuration, such as either making sure IPv6 is present, or making sure it isn't.  And so on.

.. _`OpenWRT wiki`: http://wiki.openwrt.org/doc/howto/build

Configuring the OpenWRT buildroot can be a daunting task so starting with a minimal configuration is very helpful.  For a guest VM image there are a few things to consider:

* the VM target (Xen, KVM, etc)
* root device name (vda2 for KVM, sda2 for others like VirtualBox)

Traditionally OpenWRT has used Subversion for source control.  A move (or mirror?) on GitHub makes things easier for those of us who it it regualrly in other projects.  The `buildroot doc`_ uses GitHub as the source so I've followed that convention.

.. _`buildroot doc`: http://wiki.openwrt.org/doc/howto/buildroot.exigence

* Clone the repo::

    git clone git://git.openwrt.org/openwrt.git
    cd openwrt

* Install custom feed::

    echo "src-git dtroyer https://github.com/dtroyer/openwrt-packages" >>feeds.conf.default

* Install packages::

    ./scripts/feeds update -a
    ./scripts/feeds install -a

* Check for missing packages::

    make defconfig

Configuration
-------------

* Configure::

    make menuconfig

* Enable the following:

  * Target System: x86
  * Subtarget: KVM guest
  * Target Images

    * ``[*] ext4``
    * ``(48)`` Root filesystem partition size (in MB)
    * ``(/dev/vda2)`` Root partition on target device

  * Base System

    * ``{*} block-mount``  (not sure, if yes to support root fs, parted too)
    * ``<*> rc.cloud``

Notes:

* Increase the root filesystem size if you do not intend to move root to another partition or increase the existing one to fit the flavor's disk size.

Build
-----

It's pretty simple::

    make -j 4

Adjust the argument to ``-j`` as appropriate for the number of CPUs on your build system.

When build errors occur, you'll need to run with output turned on::

    make V=99

Configuring the Image for OpenStack
===================================

As I mentioned earlier, there are a handful of changes to make to the resulting image that makes it ready for an OpenStack cloud.

* Set a root password - Without a root password your newly minted VM is vulnerable to a password-less telnet login if your security group rules allow that.  But more importantly, Dropbear will not allow an ssh login without a rot password.  Edit ``/etc/shadow`` to set a root password

* Configure a network interface for DHCP - This allows the first interface to obtain its IP automatically for OpenStack clouds that provide it.  Otherwise...

* Configure ``/etc/opkg.conf`` to my package repo - Packages usually need to be matched for not only their architecture but also other build flags.  Kernel modules are particularly rigid about how they can be loaded.

Image Update
------------

All of the interesting parts below must be done as root.  So be careful.

* Uncompress and copy the original image to a workspace, mount it and chroot into it::

    gzip -dc bin/x86/openwrt-x86-kvm_guest-combined-ext4.img.gz >openwrt-x86-kvm_guest-combined-ext4.img
    sudo kpartx -av openwrt-x86-kvm_guest-combined-ext4.img
    mkdir -p imgroot
    sudo mount -o loop /dev/mapper/loop0p2 imgroot
    sudo chroot imgroot

* Make the desired changes:

  * Set root password::

        sed -e '/^root/ s|^root.*$|root:\!:16270:0:99999:7:::|' -i /etc/shadow

  * Configure DHCP::

        uci set network.lan.proto=dhcp; uci commit

  * Configure opkg::

        sed -e "s|http.*/x86/|http://bogus.hackstack.org/openwrt/x86/|" -i /etc/opkg.conf

* Unwind the mounted image::

    sudo umount imgroot
    sudo kpartx -av openwrt-x86-kvm_guest-combined-ext4.img    

* Upload it into Glance::

    openstack image create --file openwrt-x86-kvm_guest-combined-ext4.img --property os-distro=OpenWRT OpenWRT

    # Glance CLI
    glance image-create --file openwrt-x86-kvm_guest-combined-ext4.img --name OpenWRT

Additional Modifications
========================

Extending Root Filesystem
-------------------------

Even the smallest flavor gets a root disk a good bit larger than the typocal OpenWRT disk image.  One way to use that space is to increase the root filesystem.  OpenWRT has something called ``extroot`` that is currently experimental and semi-undocumented, so I just took the radical move of partitioning the unused space and moving the root filesystem to the new partition.

Of course a real root expansion should be automated and added to ``rc.cloud`` to mirror the ``cloud-init`` functionality.  Someday...

* Install required packages if they're not part of the base build::

    opkg update
    opkg install block-mount parted

* Create a filesystem on the remaining disk and mount it::

    parted /dev/vda -s -- mkpart primary  $(parted /dev/vda -m print | tail -1 | cut -d':' -f3) -0
    mkfs.ext4 -L newroot /dev/vda3
    mkdir -p /tmp/newroot
    mount /dev/vda3 /tmp/newroot

* Copy the root filesystem::

    mkdir -p /tmp/oldroot
    mount --bind / /tmp/oldroot
    tar -C /tmp/oldroot -cvf - . | tar -C /tmp/newroot -xf -
    umount /tmp/oldroot
    umount /tmp/newroot

* Update the GRUB bootloader to use the new partition::

    mkdir -p /tmp/boot
    mount /dev/vda1 /tmp/boot
    sed -e 's/vda2/vda3/' -i /tmp/boot/boot/grub/grub.cfg
    umount /tmp/boot

* Reboot

