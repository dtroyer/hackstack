---
title: Windows Images for OpenStack
author: dtroyer
date: 2014-07-07 07:07:00
categories: OpenStack, Windows, VirtualBox
tags: image windows
---

There is no shortage of articles online about building Windows images for use in various clouds.  What there is a shortage of are working articles on building these images unattended.  The Windows unattended install process has been basically solved, even if still a bit arcane.  But finding more than a trivial example of doing it in a cloud is sparse.

Cloudbase has `shared the tooling`_ they created for building their Windows images.  That makes a good base for an automated build process that can be tailored to your particular needs.  in addition to being the authors of cloudbase-init, their GitHub account is a trove of resources for Windows admins.

.. _`shared the tooling`: https://github.com/cloudbase/windows-openstack-imaging-tools

Since I had a Windows 7 Professional ISO handy I used that for the example...

Requirements
============

The resulting image must:

* have RedHat's VirtIO drivers installed
* use ``cloudbase-init`` for metadata handling


Build In VirtualBox
===================

The Cloudbase process is designed to perform the build using KVM.  Ideally, it would be possible to boot a VM in an OpenStack cloud from the install ISO and let it go, but it turns out this is hard.  The unattended install process  requires two ISO images and a floppy image attached to the VM in addition to the target disk device. OpenStack currently has no way to do all of these attachments.  The alternative is to stash autounattend.xml and the virtio drivers in the Windows install ISO, but this requires a rebuild/upload for _every_ change to the install scripts.

So normally this means a Linux on bare-metal install is required.  How hard is it to dig up a laptop with Trusty on it?  Hard, if you're me.  

I've heard that using VirtualBox doesn't work for some reason, but these reasons haven't been made clear to me so I didn't know I couldn't do what I'm describing here.


Auto Answer Changes
-------------------

One of the main change to Cloudbase's setup is to put the PowerShell scripts on the floppy with Autounattend.xml.  This ensures that the files are matched together and changes in the repo doesn't break our working setup.

The Autounattend.xml file has a couple of changes other than those required to run the script from the floppy:

* Add the MetaData value for Win7
* Since this is Win7, we need to enable the account stanza
* Install a public product key
* Fix a spacing error in the Microsoft-Windows-International-Core-WinPE component element


PowerShell Script Changes
-------------------------

The primary change to the PowerShell scripts is to remove the file downloads and retrieve them from the floppy instead.


Make the Floppy Image
---------------------

I used `this script`_ to create the floppy image, it builds a new image, mounts it, copies the appropriate Autounattend.xml and PowerShell scripts and other files, then umnounts the image.

.. _`this script`: /x/files/make-floppy.sh


Build VM Configuration
----------------------

Automating a VBox build includes creating the VM to be used.  The ``VBoxManage`` tool is the simple way to do this from a script and that's exactly what I've done here.

It turns out that 16Gb is not enough for Windows 7 installation once all of the updates are installed.  There are a LOT of them, 157 at this writing.  Even though this only needs to be done once, it takes a long time to apply them and it might be worthwhile to obtain media with the updates pre-applied.

The commands here are taken from the ``build-vb.sh`` script.

Create a new empty VM and disk::

    BASE_NAME='win-build'
    # Create a new empty VM
    VBoxManage createvm --name "$BASE_NAME" --ostype "$OS_TYPE" --register
    VBoxManage createhd --filename "$VM_DIR/$BASE_NAME.vdi" --size $DISK_SIZE

The disk configuration is an important part of this process so everything is found as required.  In addition to the install disk and install ISO a second ISO must be mounted containing the VirtIO drivers and a floppy image with the Autounattend.xml and Powershell scripts::

    # SATA Controller
    VBoxManage storagectl "$BASE_NAME" --name "SATA" --add sata
    VBoxManage storageattach "$BASE_NAME" --storagectl "SATA" --type hdd \
        --port 0 --device 0 --medium "$VM_DIR/$BASE_NAME.vdi"

    # Make IDE disks
    VBoxManage storagectl "$BASE_NAME" --name "IDE" --add ide
    VBoxManage storageattach "$BASE_NAME" --storagectl "IDE"  --type dvddrive \
        --port 0  --device 0 --medium "$WIN_ISO"
    VBoxManage storageattach "$BASE_NAME" --storagectl "IDE"  --type dvddrive \
        --port 1  --device 0 --medium "$VIRTIO_ISO"

    # Floppy disk image
    VBoxManage storagectl "$BASE_NAME" --name "Floppy" --add floppy
    VBoxManage storageattach "$BASE_NAME" --storagectl "Floppy" --type fdd \
        --port 0 --device 0 --medium "$FLOPPY"

Do the remaining basic configuration, including a virtio NIC to tickle Windows to install the drivers::

    # General Config
    VBoxManage modifyvm "$BASE_NAME" --cpus 2
    VBoxManage modifyvm "$BASE_NAME" --memory $RAM_SIZE --vram 24
    VBoxManage modifyvm "$BASE_NAME" --ioapic on

    VBoxManage modifyvm "$BASE_NAME" --nic1 nat --bridgeadapter1 e1000g0
    VBoxManage modifyvm "$BASE_NAME" --nic2 nat
    VBoxManage modifyvm "$BASE_NAME" --nictype2 virtio

    VBoxManage modifyvm "$BASE_NAME" --boot1 dvd --boot2 disk --boot3 none --boot4 none

Kick off the build process::

    VBoxManage startvm "$BASE_NAME" --type gui

Convert the disk from VDI to QCOW2 format for uploading into the image store::

    qemu-img convert -p -O qcow "$VM_DIR/$BASE_NAME.vdi" "$VM_DIR/$BASE_NAME.qcow"
