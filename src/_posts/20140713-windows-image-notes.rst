---
title: More Notes on Windows Images
author: dtroyer
date: 2014-07-13 07:13:00
categories: OpenStack, Windows
tags: image windows
---

This is a follow-up to `Windows Images for OpenStack </x/blog/2014/07/07/windows-images-for-openstack/>`_ that includes some of the notes accumulated along the way.

Other Docs
==========

Building Windows VM images is a topic that has been done to death, but the working consensus of those I've talked to is that `Florent Flament's post`_ is one of the best guides through this minefield.

.. _`Florent Flament's post`: http://www.florentflament.com/blog/windows-images-for-openstack.html


Metadata Server Curl Commands
=============================

Instance UUID:

    curl http://169.254.169.254/openstack/latest/meta_data.json | python -c 'import sys, json; print json.load(sys.stdin)["uuid"]'

Instance Name:

    curl http://169.254.169.254/openstack/latest/meta_data.json | python -c 'import sys, json; print json.load(sys.stdin)["name"]'

Fixed IP:

    curl http://169.254.169.254/latest/meta-data/local-ipv4

Floating IP:

    curl http://169.254.169.254/latest/meta-data/public-ipv4


Building on an OpenStack Cloud
==============================

One of the changes to the base instructions is to perform the build in an OpenStack cloud.  The compute node must have nested virtualization enabled so KVM will run, otherwise Qemu would be used and we just don't have time for that.

I'm going to use `Cloudenvy`_ to manage the build VM.  It is similar to Vagrant in automating the grunt work of provisioning the VM.  The VM needs to have at least 4Gb RAM and 40Gb disk available in order to boot the seed Windows image.  This is an ``n1.medium`` flavor on the private cloud I am using.

I am also using Ubuntu 14.04 because much of my tooling already assumes an Ubuntu build environment.  There is no technical reason that Fedora 20 could not be used, appropriate adjustments would need to be made, of course.

.. _`Cloudenvy`: https://github.com/cloudenvy/cloudenvy


Build VM
--------

I am not going to spend much time here explaining Cloudenvy's configuration, but there are two things required to not have a bad time with it.

Configure your cloud credentials in ``~/.cloudenvy``::

    cloudenvy:
        keypair_name: dev-key
        keypair_location: ~/.ssh/id_rsa-dev-key.pub
        clouds:
            cloud9:
                os_auth_url: https://cloud9.slackersatwork.com:2884/v2.0/
                os_tenant_name: demo
                os_username: demo
                os_password: secrete

::

    project_config:
        name: imagebuilder
        image: Ubuntu 14.04
        remote_user: ubuntu
        flavor_name: n1.medium

    sec_groups: [
        'tcp, 22, 22, 0.0.0.0/0',
        'tcp, 5900, 5919, 0.0.0.0/0',
        'icmp, -1, -1, 0.0.0.0/0'
    ]

    files:
        Makefile: '~'
        ~/.cloud9.conf: '~'

    provision_scripts:
        - install-prereqs.sh

The ``~/.cloud9.conf`` file is a simple script fragment that sets the ``OS_*`` environment variable credentials required to authenticate using the OpenStack CLI tools.  It looks something like::

    export OS_AUTH_URL=https://cloud9.slackersatwork.com:2884/v2.0/
    export OS_TENANT_NAME=demo
    export OS_USERNAME=demo
    export OS_PASSWORD=secrete

Why do we need two sets of credentials?  Because we haven't taught Cloudenvy to read the usual environment variables yet.  I smell a pull request in my future...


Fire it up and log in::

    envy up
    envy ssh

At this point we can switch over to Flament's process.



Or we can use the cloudbase auto-answer template


Get the ISO::

    >en_windows_7_professional_with_sp1_x64_dvd_u_676939.iso
    for i in aa ab ac ad ae af ag ah; do \
        swift download windows7 en_windows_7_professional_with_sp1_x64_dvd_u_676939.iso-$i; \
        cat en_windows_7_professional_with_sp1_x64_dvd_u_676939.iso-$i >>en_windows_7_professional_with_sp1_x64_dvd_u_676939.iso
    done



sudo ./make-floppy.sh




=====

::

    # add keypair if not already there
    os keypair create --public-key ~/.ssh/id_rsa.pub $(hostname -s)

    # Create VM
    os server create \
      --image "Ubuntu 14.04" \
      --flavor n1.tiny \
      --key-name bunsen \
      --user-data cconfig.txt \
      --wait \
      dt-1

    export IP=$(os server show dt-1 -f value -c addresses | cut -d '=' -f2)

    # Go to there
    ssh ubuntu@$IP

====

Now on to Florent's steps

* Create a virtual disk

    qemu-img create -f qcow2 Windows-Server-2008-R2.qcow2 9G

* Boot the install VM

::

    kvm \
        -m 2048 \
        -cdrom <WINDOWS_INSTALLER_ISO> \
        -drive file=Windows-Server-2008-R2.qcow2,if=virtio \
        -drive file=<VIRTIO_DRIVERS_ISO>,index=3,media=cdrom \
        -net nic,model=virtio \
        -net user \
        -nographic \
        -vnc :9 \
        -k fr \
        -usbdevice tablet

Connect via VNC to :9
