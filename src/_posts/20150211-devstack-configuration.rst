---
title: Real World DevStack Configuration
author: dtroyer
date: 2015-02-11 15:02:11
categories: DevStack
tags: openstack devstack
---

Configuring DevStack for development use is a trail of Google searches and
devstack.org reading and all sorts of things.  In my experience, the best and hardest
source of what to do is experience.  And we all know how experience is the bridge
between Bad Judgement and Good Judgement.[]

local.conf
==========

This is DevStack's configuration file.  It will never be modified by DevStack.

localrc
-------

Now just a section in local.conf, ``localrc`` used to be the main config file.
References to it should be mentally translated to ``local.conf [[local|localrc]]``
section.

I also tend to carry a number of config bits commented out to make changing quick.
I'll leave those in to illustrate alternatives to my defaults.

Logging
~~~~~~~

::

    LOGDIR=$DEST/logs
    LOGFILE=$LOGDIR/stack.sh.log  # why didn't bare name work???

The logging support has been recently revamped to use a more conventional
configuration.  ``LOGDIR`` will default to ``$DEST/logs`` and all log
files will be found here.  ``LOGFILE`` will be honored as always, putting
the stack.sh trace log in that location; if ``LOGFILE`` does not include
a path, it becomes ``$LOGDIR/$LOGFILE``.

The services logs (aka screen logs) no longer default to a screen-specific
subdirectory, unless ``SCREEN_LOGDIR`` is set.  It is deprecated and will be
removed in the future.

Network Addressing
~~~~~~~~~~~~~~~~~~

::

    FIXED_RANGE=10.254.1.0/24

Set ``FIXED_RANGE`` away from the default ``10.0.0.0/24`` because, well, many
clouds use 10/8 for various things and some of them start at the beginning.
Running DevStack in a cloud VM requires that the DevStack network addresses do
not overlap with the host cloud networks.  Pick a range that isn't at the top
or the bottom to (slightly) reduce the chances of collision.  This is safe for
the neighborhoods I cloud in.

Services
~~~~~~~~

For my normal workflow, I want debugging bits enabled and services I am not using disabled.

::

    enable_service dstat
    disable_service h-eng h-api h-api-cfn h-api-cw
    disable_service horizon
    #enable_service s-proxy s-object s-container s-account

I typically don't use Heat or Horizon, you know, being the CLI guy and all.
Swift is not added by default because it takes a toll on memory use, my laptop
is not well-endowed in that area so 2G VMs are necessary whenever possible.  In
the cloud VMs this is not an issue.

Neutron
~~~~~~~

::

    # Nova Net
    enable_service n-net
    disable_Service q-svc q-agt q-dhcp q-l3 q-meta

    # Neutron
    # NETWORK_GATEWAY must be in the FIXED_RANGE network
    #NETWORK_GATEWAY=10.254.1.1
    #disable_service n-net
    #enable_service q-svc q-agt q-dhcp q-l3 q-meta

Neutron may or may not be the default in DevStack by the time you read this,
I've stopped taking chances, I want to know what I get, which by default is
Nova Net for as long as possible, again mostly for memory and complexity reasons.

Note that Neutron in the default config requires ``NETWORK_GATEWAY`` to be set
inside the network defined by ``FIXED_RANGE``.  Nova Net does not require this,
although it is mostly harmless to define anyway.

Legacy Nova Bits
~~~~~~~~~~~~~~~~

::

    disable_service n-obj n-crt

``n-obj`` is the Nova Object Service, left over from the euca2ools bundle command's
need of an S3 service.  That's it.  Same with ``n-crt``.  They should be removed
as defaults soon if not already.

nova.conf
---------

Set values here via ``local.conf``::

    [[post-config|$NOVA_CONF]]
    [DEFAULT]
    api_rate_limit = False

Rate limiting can be a problem during testing, nuke it.
