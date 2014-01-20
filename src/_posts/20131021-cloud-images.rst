---
title: Cloud Image Updates
author: dtroyer
date: 2013-10-21 10:21:00
categories: OpenStack, Ubuntu, Fedora
tags: image ubuntu uec fedora f19
---

Update!  Update!  Update!

A while back I started documenting the image build process I've been using for building OpenStack cloud images:

* `A Fedora 18 Image for OpenStack </x/blog/2013/01/25/a-fedora-18-image-for-openstack/>`_
* `A CentOS 6 Image for OpenStack </x/blog/2013/04/25/a-centos-6-image-for-openstack/>`_

Note that Ubuntu is missing from that list, due mostly to their published UEC images being generally good enough as a starting point.  Fedora 19 finally has a similar image published, let's see how different it is and if it is useful for my purposed...

Also, all of these images have rng-tools added as it is useful on clouds that provide a usable virtualized /dev/random in their hypervisor.

Fedora 19
=========

Grab the new F19 cloud image; the QCOW2 version is ready to go!  http://download.fedoraproject.org/pub/fedora/linux/releases/19/Images/x86_64/Fedora-x86_64-19-20130627-sda.qcow2.

It's surprisingly close!  There aren't any standout differences save for the inclusion of sendmail and procmail, which I've specifically removed in my kickstart.

* install rng-tools
* remove sendmail and/or procmail if present
* clean up OpenSSH host keys

CentOS 6
========

This is still a basic installation with a bunch of cruft removes such as all of the firmware packages that are useless in a virtual environment.

* stop getty on all vconsoles except /dev/tty1
* install rng-tools
* install cloud-init 
* teach device mapper to not auto-generate virtual network devices
* add support for growing the root filesystem at first boot

Ubuntu 12.04
============

Just for completeness I'll list what I do:

* install rng-tools
* clean up Device Mapper and OpenSSH host keys
