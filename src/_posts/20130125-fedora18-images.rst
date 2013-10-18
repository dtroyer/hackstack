---
title: A Fedora 18 Image for OpenStack
author: dtroyer
date: 2013-01-25 01:25:00
categories: Fedora, OpenStack
tags: fedora images
xdraft: true
---
*[Updated 01Oct2013 to correct spelling and command formatting]*

Building images to boot in a cloud can be a lot of fun, especially since no two clouds are built alike.  Now fortunately the differences are mostly minor, but some of the minor differences can be fatal. Ugh.

Good News
=========

The recent release of Fedora 18 brought with it a pleasant surprise, the build of some images suitable for loading into your favorite cloud, ala Ubuntu's UEC images.
The `mailing list notice`_ gives the background and a reply in that thread mentions some desirable changes.  So in order to make those changes I decided to roll my own using the FCI kickstart_ as a base.

.. _`mailing list notice`: http://lists.fedoraproject.org/pipermail/cloud/2013-January/002192.html
.. _kickstartx: http://git.fedorahosted.org/cgit/cloud-kickstarts.git/plain/generic/fedora-18-x86_64-cloud.ks
.. _kickstart: /x/files/fedora-18-x86_64-cloud.ks

The `new kickstart`_ file is pretty straightforward and mostly self-explanatory.  Here is what I changed::

* Set the timezone to ``Etc/UTC``
* Configure for serial console
* Create a default ``fedora`` user (instead of ``ec2-user``)
* Leave behind a build timestamp in /etc/.build
* Remove sendmail
* Add ??

.. _`new kickstart`: /x/files/fedora-18-x86_64-cloud-dt1.ks

And here is what it took to get ``appliance-creator`` running on a fresh Fedora 17 VM::

    sudo yum install -y appliance-tools.noarch
    wget -N http://git.fedorahosted.org/cgit/cloud-kickstarts.git/plain/generic/fedora-18-x86_64-cloud.ks
    # make kickstart changes
    sudo appliance-creator --config fedora-18-x86_64-cloud-dt1.ks \
      --name fedora18-x86_64-cloud-dt1 --format raw

The conversion to qcow2 is done separately as ``appliance-creator`` doesn't compress qcow2 images::

    qemu-img convert -c -f raw -O qcow2 \
      fedora-18-x86_64-cloud-dt1.raw \
      fedora-18-x86_64-cloud-dt1.qcow2

Kick it into the cloud image repository::

    glance image-create --name "Fedora 18 x86_64 cloudimg" \
      --disk-format qcow2 --container-format bare \
      --is-public false --file fedora-18-x86_64-cloud-dt1-sda.qcow2

Kickstart Details
-----------------

All of the excerpts below are shown in diff(1) format to illustrate the changes made to the original kickstart file.

Timezone
~~~~~~~~

Set the timezone to ``Etc/UTC``::

    -timezone --utc America/New_York
    +timezone --utc Etc/UTC

Serial Console
~~~~~~~~~~~~~~

There are a couple of things that need to be updated to properly get a serial console in Linux.
Append to the bootloader::

    -bootloader --timeout=0 --location=mbr --driveorder=sda
    +bootloader --timeout=0 --location=mbr --driveorder=sda --append="console=tty console=ttyS0"

Configuring Grub takes a little more effort. The original kickstart only worked in the chroot-ed ``%post`` but ``grub2-mkconfig`` failed because /dev was not complete.
By adding a ``%post --nochroot`` section /dev can be bind-mounted into the chroot so ``grub2-mkconfig`` is happy.
I probably went a little overboard in setting up the proper serial console arguments to the kernel command line but the following worked::

    +%post --nochroot
    +echo "Configure GRUB2 for serial console"
    +echo GRUB_TIMEOUT=0 > $INSTALL_ROOT/etc/default/grub
    +echo GRUB_TERMINAL=console >>$INSTALL_ROOT/etc/default/grub
    +echo GRUB_CMDLINE_LINUX=\"console=ttyS0 console=tty\" >>$INSTALL_ROOT/etc/default/grub
    +echo GRUB_CMDLINE_LINUX_DEFAULT=\"console=ttyS0\" >>$INSTALL_ROOT/etc/default/grub
    +mount -o bind /dev $INSTALL_ROOT/dev
    +/usr/sbin/chroot $INSTALL_ROOT /sbin/grub2-mkconfig -o /boot/grub2/grub.cfg
    +umount $INSTALL_ROOT/dev
    +%end

The following lines were also removed from the original ``%post`` Grub section::

    -echo GRUB_TIMEOUT=0 > /etc/default/grub
    -sed -i 's/^set timeout=5/set timeout=0/' /boot/grub2/grub.cfg

Default Account
~~~~~~~~~~~~~~~

``cloud-init`` creates an ``ec2-user`` account by default.  The account is useful but this isn't EC2 so the account is renamed to ``fedora``::

    -# Uncomment this if you want to use cloud init but suppress the creation
    -# of an "ec2-user" account. This will, in the absence of further config,
    -# cause the ssh key from a metadata source to be put in the root account.
    -#cat <<EOF > /etc/cloud/cloud.cfg.d/50_suppress_ec2-user_use_root.cfg
    -#users: []
    -#disable_root: 0
    -#EOF
    +# Rename the 'ec2-user' account to 'fedora'
    +sed -i '
    +  s/name: ec2-user/name: fedora/g
    +  s/gecos: EC2/gecos: Fedora/g
    +' /etc/cloud/cloud.cfg

Build Stamp
~~~~~~~~~~~

Leave a file containing the build version and timestamp just in case it might be useful from inside the VM::

    +# Leave behind a build stamp
    +echo "build=nebula1 $(date +%F.%T)" >/etc/.build
