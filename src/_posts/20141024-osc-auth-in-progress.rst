---
title: How Dost Thy Cloud Know Me, Let Me Count The Ways
author: dtroyer
date: 2014-10-24 10:24:00
categories: OpenStackClient
tags: projects openstackclient
---

One of the coolest (IMHO) new features [#]_ recently added to OpenStackClient is its leveraging of a new-ish feature of Keystone's client library, authentication plugins.  As that name implies, this allows for Keystone client to be able to use an extendable set of authentication backends for validating users.  At press time (keypress time for the pedantic) the freshly released python-keystoneclient_ 0.11.2 includes the traditional password method, a new variant on the token method and a recent addition supporting SAML2.

.. _python-keystoneclient: https://pypi.python.org/pypi/python-keystoneclient

Happily, the `master branch`_ of OpenStackClient has learned how to take advantage of these plugins, plus any additional ones written for Keystone client.  This creates a new problem because the authentication type can not always be inferred and needs to be supplied by the user.  And thus we arrive at the *Topic of the Day*.

.. _`master branch`: http://git.openstack.org/cgit/openstack/python-openstackclient

But First, Preview Time
-----------------------

There is one additional yet-to-come feature that I can't resist mentioning now that it has been `proposed for review`_. It leverages mordred's os-client-config_ module to read configuration information from a file by name.  In plain language, rather than set up a handful of environment variables or command-line options, all of the authentication and other configuration for OSC can be stashed in a YAML file and called by name::

    openstack --os-cloud devstack-1 image list --long

.. _`proposed for review`: https://review.openstack.org/129795
.. _os-client-config: http://git.openstack.org/cgit/stackforge/os-client-config

This is also step one in simplifying dealing with multiple clouds::

    for cloud in devstack-1 hpcloud-az2 rax-ord; do
        openstack --os-cloud image list --long

It is a small thing, but small things often make us happy.  It figures in to the following authentication discussion that I don't want to update again in a month.  So until ``os-cloud`` support merges, ignore references to YAML, ``CloudConfig``, etc. below.

.. mordred
.. os-cloud https://review.openstack.org/129795

Sources of Truth
----------------

OpenStackClient has three sources of configuration information (in decreasing priority order):

* command line options
* environment
* ``CloudConfig`` (``~/.config/openstack/clouds.yaml`` file)

Once all of the sources have been processed and a single configuration object assembled, the fun can begin.  If an authentication type is not provided, the authentication options are examined to determine if one of the default types can be used. If no match is found an error is reported and a period of stillness is declared.  Rather, the program exits.

Note that the authentication call to the Identity service has not yet
occurred.  It is deferred until the last possible moment in order to
reduce the number of unnecessary queries to the server, such as when further
processing detects an invalid command.

Keystone Authentication Plugins
-------------------------------

The Keystone client library implements the base set of plugins.  Additional
plugins may be available from the Keystone project or other sources.
See the `Keystone client documentation`_ for more information.

.. _`Keystone client documentation`: http://docs.openstack.org/developer/python-keystoneclient/authentication-plugins.html

There are at least three authentication types that are always available:

* **Password**: A username and password, plus optional project and/or domain,
  are used to identify the user.  This is the most common type and the
  default any time a username is supplied.  An authentication URL for the
  Identity service is also required.  [Required: ``--os-auth-url``, ``--os-project-name``, ``--os-username``; Optional: ``--os-password``]
* **Token**: This is slightly different from the usual token authentication
  (described below as token/endpoint) in that a token and an authentication
  URL are supplied and the plugin retrieves a new (scoped?) token.
  [Required: ``--os-auth-url``, ``--os-token``]
* **Token/Endpoint**: This is the original token authentication (known as 'token
  flow' in the early CLI documentation in the OpenStack wiki).  It requires
  a token and a direct endpoint that is used in the API call.  The difference
  from the new Token type is this token is used as-is, no call is made
  to the Identity service from the client.  This type is most often used to
  bootstrap a Keystone server where the token is the ``admin_token`` configured
  in ``keystone.conf``.  It will also work with other services and a regular
  scoped token such as one obtained from a ``token issue`` command.  [Required: ``--os-url``, ``--os-token``]

  *[Note that the Token/Endpoint plugin is currently supplied by OSC itself and is not available for other clients using the Keystone client lib.  It shall move to its Proper Home in Good Time.]*
* **Others**: There are SAML and other (Kerberos?) plugins under development
  that are also supported.  To use them they must be selected by supplying
  the ``--os-auth-type`` options.

How It's Made
-------------

*[Who doesn't love* `that show <http://www.sciencechannel.com/tv-shows/how-its-made>`_? *]*

The authentication process flows from OSC's ``OpenStackShell`` to the New-and-Improved ``ClientManager``.

* But first, on import ``api.auth``:

  * obtains the list of installed Keystone authentication
    plugins from the ``keystoneclient.auth.plugin`` entry point.
  * builds a list of authentication options from the plugins.

* ``OpenStackShell`` parses the command line:

  * If ``--os-cloud`` is present read the named configuration from ``~/.config/openstack/clouds.yaml`` and create a ``CloudConfig`` object

    * ``CloudConfig`` also handles picking up the matching environment variables for the options
  * The remaining global command line options are merged into the new ``CloudConfig``

* A new ``ClientManager`` is created and provided with the ``CloudConfig``:

  * If ``--os-auth-type`` is provided and is a valid and available plugin it is used.
  * If ``--os-auth-type`` is not provided select an authentication plugin based on the existing options.  This is a short-circuit evaluation, first match wins.

    * If ``--os-endpoint`` and ``--os-token`` are both present ``token_endpoint`` is selected
    * If ``--os-username`` is present ``password`` is selected
    * If ``--os-token`` is present ``token`` is selected
    * If no selection has been made by now exit with error

  * Load the selected plugin class.

* ``ClientManager`` waits until an operation that requires authentication is attempted to make the initial request to the Identity service.

  * if ``--os-auth-url`` is not present for any of the types except
    Token/Endpoint, exit with an error.

Destinations of Consequences
----------------------------

The changes that began with utilizing Keystone client's ``Session`` are nearly complete and have added the ``openstackclient.api.auth`` module and drastically restructured the ``openstackclient.shell`` and ``openstackclient.clientmanger`` modules.  One result is that the ``ClientManager`` is now nearly self-contained with regard to its usability apart from the OSC shell.  At this time I can neither confirm nor deny that ``ClientManager`` could be used as a single-point client API.  While it works (`one example <https://review.openstack.org/127873>`_) it is not yet a stable API because it only unifies the session and auth components, passing the real work down to either the project libraries or OSC's internal API objects.  So don't go and do that.  Yet...

----

.. [#] Currently only in master branch, to be included in the next release.
