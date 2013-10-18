---
title: A CentOS 6 Image for OpenStack
author: dtroyer
date: 2013-04-25 04:25:00
categories: CentOS, RHEL, OpenStack
tags: centos rhel images
---
*[Updated 01Oct2013 to correct spelling and command formatting]*

This is the next installment in the never-ending series of OpenStack image builds.  Today's
target: CentOS

Image Characteristics
=====================

The usual suspects are present:

* minimal package install
* serial console support
* timezone is ``Etc/UTC``
* hostname set to instance name
* a single partition with root filesystem, no swap
* grow root filesystem to device size
* enable EPEL (install epel-release)
* enable could-init repo to get 0.7.1

A few things are still lacking:

* selinux is in permissive mode, make enforcing
* strengthen default firewall

Build
=====

Tools like ``Oz`` are a good idea in theory but in practice seem to be quite picky about the environment
they will correctly run on.  I'm looking at you ``libguestfs``.  Other tools like the venerable ``appliance-creator`` get hung up
on needing the same version of things in the host as in the chroot.

Good ole ``virt-install`` happily runs on damn near everything.  This build has been tested
on CentOS 6.4 and Ubuntu 12.10.  `TODO(dtroyer): don't run this all as root`

Let's get started.

* Install `virt-install` and all its prerequisites

  * on Ubuntu::

      sudo apt-get install virtinst

  * on CentOS::

      sudo yum install libvirt python-virtinst qemu-kvm
      sudo /etc/init.d/libvirtd start

* Get a `CentOS 6 kickstart`_ file with minimal stuff and the extras that we need.  Included in ``%post`` is a bit to resize the root filesystem to the size of the actual device provided to the VM.

.. _`CentOS 6 kickstart`: https://raw.github.com/dtroyer/image-recipes/master/centos-6-x86_64.ks

* Create base image with ``virt-install``::

    sudo virt-install \
        --name centos-6-x86_64 \
        --ram 1024 \
        --cpu host \
        --vcpus 1 \
        --nographics \
        --os-type=linux \
        --os-variant=rhel6 \
        --location=http://mirrors.kernel.org/centos/6/os/x86_64 \
        --initrd-inject=centos-6-x86_64.ks \
        --extra-args="ks=file:/centos-6-x86_64.ks text console=tty0 utf8 console=ttyS0,115200" \
        --disk path=/var/lib/libvirt/images/centos-6-x86_64.img,size=2,bus=virtio \
        --force \
        --noreboot

* Point to the bridge with external connectivity if it is not `eth0`::

        --network=bridge=br0

* If ``libguestfs`` is functional on your build platform::

    sudo yum install -y libguestfs-tools
    sudo virt-sysprep --no-selinux-relabel -a /var/lib/libvirt/images/centos-6-x86_64.img
    sudo virt-sparsify --convert qcow2 --compress /var/lib/libvirt/images/centos-6-x86_64.img centos-6-x86_64.qcow2

* Kick it into the cloud image repository::

    glance image-create --name "CentOS 6 x86_64" \
        --disk-format qcow2 --container-format bare \
        --is-public false --file centos-6-x86_64.qcow2


.. save for selinux enforcing
    # SELinux: relabelling all filesystem
    echo "guestfis selinux relabel"
    guestfish --selinux -i $IMGNAME.$EXT <<EOF
    sh load_policy
    sh 'restorecon -Rv /'
    EOF
