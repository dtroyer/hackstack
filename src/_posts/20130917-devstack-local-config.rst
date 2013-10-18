---
title: DevStack Local Config
author: dtroyer
date: 2013-09-07 09:17:00
categories: OpenStack, DevStack
tags: steam
---

*[Updated 10 Oct 2013 to reflect the released state of ``local.conf``]*

DevStack has long had an extremely simple mechanism to add arbitrary configuration entries to ``nova.conf``, ``EXTRA_OPTS``.  It was handy and even duplicated in the Neutron configuration in a number of places.  However, it did not scale well: a new variable and expansion loop is required for each file/section combination.  And now the time has come for a replacement...

Requirements
============

  * ``localrc`` has served well in its capacity of the sole container of local configuration.  Being a single file makes it easy to track and share known working DevStack configurations.  Any new configuration scheme must preserve this property.

  * In order to be able to set attributes in arbitrary configuration files and sections, those bits of information must be encoded in the new format.

  * There must be a mechanism to selectively merge the configuration values into their destination files rather than do them all at once.

  * Reduce the number of configuration variables in general that are simply passed-through to project config files.  They are being set in localrc anyway, moving that to another section of local.conf is not a difficult transition.

  * Backward-compatibility is a must; existing ``localrc`` files must continue to work as expected.  In order to utilize any of the new capability, ``localrc`` must be converted to the ``local.conf`` ``local`` section.

Solution
========

Support has been added for a new master local configuration file ``local.conf`` that, like ``localrc``, resides in the root DevStack directory and is not included in the DevStack repo. ``local.conf`` contains all local configuration for DevStack, including a direct replacement for ``localrc``.  It is an extended-INI format that introduces a new meta-section header containing the additional information required: a phase name and destination configuration filename.  It has the form::

    [[ <phase> | <filename> ]]

where <phase> is one of a set of phase names defined below by ``stack.sh`` and <filename> is the configuration filename.  The filename is eval'ed in the ``stack.sh`` context so all environment variables are available and may be used (see example below).  Using the configuration variables from the project library scripts (e.g. ``lib/nova``) in the header is strongly suggested (see example of ``NOVA_CONF`` below).

Configuration files specifying a path that does not exist are skipped.  This allows services to be disabled and still have configuration files present in ``local.conf``.  For example, if Nova is not enabled and ``/etc/nova`` does not exist, attempts to set a value in ``/etc/nova/nova.conf`` will be skipped.  If ``/etc/nova`` does exist, ``nova.conf`` will be created if it does not exist.  This should be mostly harmless.

The defined phases are:

* **local** - extracts the ``localrc`` section from ``local.conf`` before ``stackrc`` is sourced
* **post-config** - runs after the `layer 2 services </x/blog/2013/09/05/openstack-seven-layer-dip-as-a-service/>`_ are configured and before they are started
* **extra** - runs after services are started and before any files in ``extra.d`` are executed

``local.conf`` is processed strictly in sequence; meta-sections may be specified more than once but if any settings are duplicated the last to appear in the file will survive.

The ``post-config`` phase is where most of the configuration-setting activity takes place.  In the following example, syslog and the Compute v3 API are enabled.  Note the use of ``$NOVA_CONF`` to properly locate ``nova.conf``.

    [[post-config|$NOVA_CONF]]
    [DEFAULT]
    use_syslog = True

    [osapi_v3]
    enabled = False

A special meta-section ``[[local|localrc]]`` is used to replace the function of the old ``localrc`` file.  This section is written to ``.localrc.auto`` if ``locarc`` does not exist; if it does exist ``localrc`` is not overwritten to preserve compatability::

    [[local|localrc]]
    FIXED_RANGE=10.254.1.0/24
    ADMIN_PASSWORD=speciale
    LOGFILE=$DEST/logs/stack.sh.log

Implementation
==============

Four new functions were added to parse and merge ``local.conf`` into existing INI-style config files.  The base ``functions`` file is getting way too large so these functions are in ``lib/config`` which will contain functions related to config file manipulation.  The existing ``iniXXX()`` functions may also eventually move here.  There shall be no side-effects or global dependencies from any of the functions in ``lib/config``.

    * ``get_meta_section()`` - Returns an INI fragment for a specific group/filename combination
    * ``get_meta_section_files()`` - Returns a list of the config filenames present in ``local.conf`` for a specific group
    * ``merge_config_file()`` - Performs the actual merge of the INI fragment from ``local.conf``
    * ``merge_config_group()`` - Loops over the INI fragments present for the specified group and merges them

The merge is performed after the ``install_XXX()`` and ``configure_XXX()`` functions for all layer 1 and 2 projects are complete and before any services are started.

The Deprecated Variables
========================

The list of existing variables that will be deprecated in favor of using ``local.conf`` currently includes ``EXTRA_OPTS`` and a handful of ``Q_XXX_XXX_OPTS`` variables in Neutron.  These are listed at the end of ``stack.sh`` runs as deprecated and will be removed sometime in the Icehouse development cycle after DevStack's stable/havana branch is in place and Grenade's Grizzly->Havana upgrade is operational.

Examples
========

* Convert EXTRA_OPTS from::

    EXTRA_OPTS=api_rate_limit=False

    to

    [[post-config|$NOVA_CONF]]
    [DEFAULT]
    api_rate_limit = False

* Convert multiple EXTRA_OPTS values from::

    EXTRA_OPTS=(api_rate_limit=False default_log_levels=sqlalchemy=WARN)

    to

    [[post-config|$NOVA_CONF]]
    [DEFAULT]
    api_rate_limit = False
    default_log_levels = sqlalchemy=WARN

* Eliminate a Cinder pass-through (``CINDER_PERIODIC_INTERVAL``)::

    [[post-config|$CINDER_CONF]]
    [DEFAULT]
    periodic_interval = 60

* Change a setting that has no variable::

    [[post-config|$CINDER_CONF]]
    [DEFAULT]
    iscsi_helper = new-tgtadm

* Basic complete config::

    [[post-config|$NOVA_CONF]]
    [DEFAULT]
    api_rate_limit = False

    [vmware]
    host_ip = $HOST_IP
    host_username = root
    host_password = deepdarkunknownsecret


    [[post-config|$CINDER_CONF]]
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
    