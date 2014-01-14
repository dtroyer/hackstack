---
title: OpenStackClient Plugins
author: dtroyer
date: 2014-01-14 01:14:00
categories: OpenStackClient
tags: projects
---

OpenStackClient (OSC) has been in my project queue for almost two years now.  It was Feb 2012 that I stayed up all night mucking about with something called DrStack with the goal of combining the then four OpenStack CLI binaries into a single command set.

OSC is the second major realization of that goal having a greatly improved internal command architecture courtesy of dhellmann's Cliff framework.  It also somehow got an informal blessing without becoming an official project, a status that it still carries.  We have a roadmap of where to go with that but that is a topic for another day.

Today we talk plugins!

Yes, I know, that is an overused term in OpenStack, where everything seems to be a plugin or an extension or optional in some way.  But I don't have anything better at the moment so plugin it is.

OpenStackClient Plugins
=======================

OSC development has been a series of quiet periods interspersed with bouts of furious activity.  Fast-forward to last month (Dec 2013) and the introduction of a viable command plugin system for OSC first released in version 0.3.0.  The OSC side is documented in the `OpenStackClient Developer Documentation`__.

__ http://docs.openstack.org/developer/python-openstackclient/plugins.html

Goals
-----

The previous OSC plugin mechanism was too naive and did not allow for adding client objects to the ClientManager. We needed to:

* define an initialization to add global options for API versions and whatnot (parser phase)
* define an initialization function(s) to select an API version add an appropriate client to the ClientManager (client phase)

Implementation
--------------

As an exercise to validate the completeness of the plugin mechanism, the Compute, Image and Volume API commands were converted to initialize via the plugin mechanism.  The only difference from an external plugin is that they are included in the OSC repo.

The new plugin mechanism builds on the use of `Cliff`_ to dynamically load the command classes and modifies the existing OSC ``ClientManager`` to define the client objects to be instantiated at run-time.  This allows additional clients to insert themselves into the ``ClientManager``.

.. _`Cliff`: https://pypi.python.org/pypi/cliff‎

OSC looks for plugins that register their client class under ``openstack.cli.extension``.  The key is the API name and must be unique for all plugins, the value is the module name that contains the public initialization functions.

The initialization module is typically names ``<project-name>.client``, although there is no technical requirement to follow this convention.  It was adopted as that was already the name of the modules used by the built-in API classes.

The initialization module must implement a set of constants that are used to identify the plugin and two functions that instantiate the actual API client class and define any global options required.

python-oscplugin
================

Since most actual OSC plugins are not going to be part of the repo, we created a sample plugin in a stand-alone project to demonstrate the bits required.  `python-oscplugin`_ began life as a `cookiecutter`_ project (worth using to bootstrap a project in the OpenStack-way) and expanded to become a simple demonstration of an OSC command plugin.

.. _`python-oscplugin`: https://github.com/dtroyer/python-oscplugin
.. _`cookiecutter`: https://github.com/openstack-dev/cookiecutter

So let's walk through the sample plugin to see how this works...

Plugin Initialization
---------------------

It all starts with the initialization module, here named ``oscplugin.plugin``, defining the rest of the identifiers used to locate plugin bits.  Naming this module is flexible, it just needs to be specified in the ``openstack.cli.extension`` entry point group.

* ``API_NAME`` - A short string describing the API or command set name.  It is used in the entry point group name and is the key name in the ``openstack.cli.extension`` group to identify the plugin.  Must be a valid Python identifier string.
* ``API_VERSION_OPTION`` - An optional name of the API version attribute used in the global command-line options to specify an API version.  It will be used in ``build_option_parser()`` if setting an API version is required.  Must be a valid Python identifier string.
* ``API_VERSIONS`` - A dict mapping version strings to client class names.

Two functions are required that perform the initialization work for the plugin.

* ``build_option_parser()`` - The top-level parser object is passed in and available to add plugin-specific options, usually an API version selector.
* ``make_client()`` - Instantiate the actual client object taking in to consideration any version that may be specified.  The mapping of version to client class is handled here.  Also, any authentication or service selection the specific client requires is passed in here.

Client API
----------

``python-oscplugin`` contains its own equivalent to a client API object.  In this case it is just a placeholder as the ``plugin`` commands do not have an external client library.  For most API clients this is the actual client class, such as ``glanceclient.v2.client.Client`` for the Image v2 API.

There are cases where the API client class is insufficient for some reason and adaptations are required.  The Image v1 client is a good example.  The ImageManager class in ``glanceclient`` does not have a ``find()`` method so we implemented one in ``openstackclient.image.client.Client_v1`` that uses ``openstackclient.image.client.ImageManager_v1`` with added ``find()`` and ``findall()`` methods.

Commands
--------

The commands implemented in ``python-oscplugin`` are in ``oscplugin.v1.plugin`` and follow the basic pattern used by the other OSC command classes.  Again they are mostly placeholders here.

Tests
-----

The structure of the tests also follows that of the existing OSC API commands.  They use ``mock`` and fakes to perform unit tests on the command classes.

Project Stuff
-------------

Ad ``python-oscplugin`` was created using `cookiecutter`_ it includes the usual OpenStack features such as ``pbr`` and friends.  The specific bits pertaining to an OSC plugin:

* ``setup.cfg`` - All of the plugin-specific content is in the ``[entry_points]`` section::

    [entry_points]
    openstack.cli.extension =
        oscplugin = oscplugin.plugin

    openstack.oscplugin.v1 =
        plugin_list = oscplugin.v1.plugin:ListPlugin
        plugin_show = oscplugin.v1.plugin:ShowPlugin

Note that OSC defines the group name as ``openstack.<api-name>.v<version>``
so the version should not contain the leading 'v' character.

* ``requirements.txt`` - We've added  ``openstackclient`` as ``python-oscplugin`` is useless without it.  ``keystoneclient`` is here too, while ``python-oscplugin`` does not require it, most OpenStack API clients will.  ``cliff`` is also needed here.

* ``test-requirements.txt`` - ``mock`` is required for testing.

A Note About Versions
---------------------

Internally OSC uses the convention ``vXXX`` for version identifiers, where ``XXX`` is a valid Python identifier in its own right (i.e., uses '_' rather than '.' internally).  OSC adds the leading 'v' so versions expressed in constant declarations should not include it.

EOT
===

The plugin structure should allow any base install of OSC to be extended simply by installing the desired client package.  Af of right now there are no other clients that implement the plugin, but that will be changing soon.  Film at eleven...
