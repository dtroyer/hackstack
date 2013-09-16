---
title: DevStack Local Config
author: dtroyer
date: 2013-09-07 09:17:00
categories: OpenStack, DevStack
tags: steam
---

DevStack has long had an extremely simple mechanism to add arbitrary configuration entries to nova.con, ``EXTRA_OPTS``.  It was handy and even emulated in the Neutron configuration in a number of places.  However, it did not scale well: a new variable and expansion loop is required for each file/section combination.  And now the time has come for a replacement...

Requirements
============

  * ``localrc`` has served well in its capacity of the sole container of local configuration.  Being a single file makes it easy to track and share known working DevStack configurations.  Any new configuration scheme must at least attempt to preserve this property.

  * In order to be able to set configuration attributes in arbitrary files and sections, those bits of information must be encoded in the new format.

  * There must be a mechanism to selectively merge the configuration values into their destination files rather than do them all at once.

  * Reduce the number of configuration variables in general that are simply passed-through to project config files.  They are being set in localrc anyway, moving that to another section of local.conf is not a difficult transition.

Solution
========

A new master local configuration file is supported (but like ``localrc`` is not included in the DevStack repo) that all local configuration for DevStack, including the master copy of ``localrc``.  ``local.conf`` is an extended-INI format that introduces a new meta-section header that contains the additional required information: a group name and destination configuration filename.  It has the form::

    [[ <group> | <filename> ]]

where <group> is the usual DevStack project name (``nova``, ``cinder``, etc) and <filename> is the config filename.  The filename is eval'ed in the ``stack.sh`` context so all environment variables are available and may be used (see example below).

The file is processed strictly in sequence.  Meta-sections may be specified more than once, if any settings are duplicated the last to appear in the file will be used::

    [[nova|$NOVA_CONF]]
    [DEFAULT]
    use_syslog = True

    [osapi_v3]
    enabled = False

A special meta-section ``[[local:localrc]]`` is used to provide a default localrc file.  This allows all custom settings for DevStack to be contained in a single file::

    [[local|localrc]]
    FIXED_RANGE=10.254.1.0/24
    ADMIN_PASSWORD=speciale
    LOGFILE=$DEST/logs/stack.sh.log

Implementation
==============

Four new functions were added to parse and merge ``local.conf`` into the existing INI-style config files.  The base ``functions`` file is getting way too large so these functions are in ``lib/config`` which will only contain functions related to config file manipulation.  There shall also be no side-effects from any of these functions.  The existing ``iniXXX()`` functions may also eventually move here.

    * ``get_meta_section()`` - Returns an INI fragment for a specific group/filename combination
    * ``get_meta_section_files()`` - Returns a list of the config filenames present in ``local.conf`` for a specific group
    * ``merge_config_file()`` - Performs the actual merge of the INI fragment from ``local.conf``
    * ``merge_config_group()`` - Loops over the INI fragments present for the specified group and merges them

The merge is performed after the ``install_XXX()`` and ``configure_XXX()`` functions for all layer 1 and 2 projects are complete and before any services are started.

Use It Or Lose It
=================

The list of existing variables that will be deprecated in favor of using ``local.conf`` has not been completed yet but includes ``EXTRA_OPTS`` and a handful of ``Q_XXX_XXX_OPTS`` variables in Neutron.  These are listed at the end of ``stack.sh`` runs as deprecated and will be removed sometime in the Icehouse development cycle after DevStack's stable/havana branch is in place and Grenade's Grizzly->Havana upgrade is operational.

Examples
--------

* Convert EXTRA_OPTS from::

    EXTRA_OPTS=api_rate_limit=False

    to

    [[nova|$NOVA_CONF]]
    [DEFAULT]
    api_rate_limit = False

* Eliminate a Cinder pass-through (``CINDER_PERIODIC_INTERVAL``)::

    [[cinder|$CINDER_CONF]]
    [DEFAULT]
    periodic_interval = 60

* Change a setting that has no variable::

    [[cinder|$CINDER_CONF]]
    [DEFAULT]
    iscsi_helper = new-tgtadm

* Basic complete config::

    [[nova|$NOVA_CONF]]
    [DEFAULT]
    api_rate_limit = False

    [vmware]
    host_ip = $HOST_IP
    host_username = root
    host_password = deepdarkunknownsecret


    [[cinder|$CINDER_CONF]]
    [DEFAULT]
    periodic_interval = 60

    vmware_host_ip = $HOST_IP
    vmware_host_username = root
    vmware_host_password = deepdarkunknownsecret


    [[local|localrc]]
    FIXED_RANGE=10.254.1.0/24
    NETWORK_GATEWAY=10.254.1.1
    LOGDAYS=1
    LOGFILE=$DEST/logs/stack.sh.log
    SCREEN_LOGDIR=$DEST/logs/screen
    ADMIN_PASSWORD=quiet
    DATABASE_PASSWORD=$ADMIN_PASSWORD
    RABBIT_PASSWORD=$ADMIN_PASSWORD
    