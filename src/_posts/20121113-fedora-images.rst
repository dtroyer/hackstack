---
title: A Fedora 17 Image for OpenStack
author: dtroyer
date: 2012-11-13 11:13:00
categories: Fedora, OpenStack
tags: fedora images
draft: true
---
*This worked well enough but has been superceeded by ``appliance-creator``*

Ubuntu has these nice UEC images that make a great base for cloud appliances.  Fedora has nothing official although there are a couple of older images floating around (links please!).  Nothing for Fedora 17 though.  Let's build one!

The most flexible image builder seems to be oz, as it runs the standard install process and can build nearly anything that boots in KVM.  There are some specific `requirements for libguestfs`_ and that usually doesn't work properly in a VM.  This all had to be done on bare metal.

.. _`requirements for libguestfs`: http://libguestfs.org/guestfs-faq.1.html

Even then, building a Fedora 17 image required Fedora 17. OK, I found an old laptop that could do it and installed f17.

There are also some kickstart files floating around like `Racker Joe's repo`_  and I've stolen from them and from the default kickstart files in Oz.  So here's the `bastard child </x/files/fedora17-x86_64.ks>`_.

.. _`Racker Joe's repo`: https://github.com/rackerjoe/oz-image-build

Oz
==

I had to build Oz from source as none of the available packages were current enough::

    git clone https://github.com/clalancette/oz.git
    cd oz
    make rpm
    sudo yum update ~/rpmbuild/RPMS/noarch/oz-0.10.0-0.20121022223625git17f9c7f.fc17.noarch.rpm 


Build an image::

    sudo oz-install -d4 -t6000 -u fedora17-x86_64.tdl -a fedora17-x86_64.ks
    qemu-img convert -c -O qcow2 /var/lib/libvirt/images/fedora17-x86_64.dsk fedora17-x86_64.qcow2

Upload and boot the image::

    glance image-create --is-public true --name "Fedora 17 test 2" --disk-format qcow2 --container-format bare --file fedora17-x86_64.qcow2
    nova boot --image 94ceb563-41ee-43f6-a999-a3b738c0d299 --flavor 2 --key-name bunsen f17-2

This image still has some tweaking needed...
