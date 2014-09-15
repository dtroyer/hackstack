---
title: OpenStack Low Level API
author: dtroyer
date: 2014-09-15 09:15:00
categories: OpenStack, API, client
tags: rest api client
---

The current Python library situation for OpenStack is, sorry to say, a mess.  Cleaning it up requires essentially starting over and abstracting the individual REST APIs to usable levels.  With OpenStackClient I started from the top and worked down to make the CLI a better experience.  I think we have proved that to be a worthwhile task.  Now it is time to start from the bottom and work up.

The existing libraries utilize a Manager/Resource model that may be suitable for application work, but every project's client repo was forked and changed so they are all similar but maddeningly different.  However, a good idea or two can be easily extracted and re-used in making things as simple as possible.

I originally started with no objects at all and went straight to top-level functions, as seen in the current ``object.v1.lib`` APIs in OSC.  That required passing around the session and URLs required to complete the REST calls, which OSC already has available, but it is not a good general-purpose API.

I've been through a number of iterations of this and have settles on what is described here, a low-level API for OSC and other applications that do not require an object model.

api.BaseAPI
-----------

We start with a `BaseAPI`_ object that contains the common operations.  It is pretty obvious there are only a couple of ways to get a list of resources from OpenStack APIs so the bulk of that and similar actions are here.

.. _`BaseAPI`: https://github.com/dtroyer/python-openstackclient/blob/low-level-api/openstackclient/api/api.py#L22

It is also very convenient to carry around a couple of other objects so they do not have to be passed in every call.  `BaseAPI`_ contains a ``session``, ``service type`` and ``endpoint`` for each instance.  The ``session`` is a ``requests.session.Session``-compatible object.  In this implementation we are using the ``keystoneclient.session.Session`` which is close enough.  We use the ksc Session to take advantage of keystoneclient's authentication plugins.

The ``service type`` and ``endpoint`` attributes are specific to each API.  ``service type`` is as it is used in the Service Catalog, i.e. ``Compute``, ``Identity``, etc.  ``endpoint`` is the base URL extracted from the service catalog and is prepended to the passed URL strings in the ``API`` method calls.

Most of the methods in `BaseAPI`_ also are meant as foundational building blocks for the service APIs.  As such they have a pretty flexible list of arguments, many of them accepting a ``session`` to override the base ``session``.  This layer is also where the JSON decoding takes place, these all return a Python ``list`` or ``dict``.

The derived classes from `BaseAPI`_ will contain all of the methods used to access their respective REST API.  Some of these will grow quite large...

api.object_store.APIv1
----------------------

While this is a port of the existing code from OpenStackClient, `object_store.APIv1`_ is still essentially a greenfield implementation of the ``Object-Store`` API.  All of the path manipulation, save for prepending the base URL, is done at this layer.

.. _`object_store.APIv1`: https://github.com/dtroyer/python-openstackclient/blob/low-level-api/openstackclient/api/object_store.py#L26

api.compute.APIv2
-----------------

This is one of the big ones.  At this point, only ``flavor_list()``, ``flavor_show()`` and ``key_list()`` have been implemented in `compute.APIv2`_.

.. _`compute.APIv2`: https://github.com/dtroyer/python-openstackclient/blob/low-level-api/openstackclient/api/compute.py#L19

Unlike the ``object-store`` API, the rest of the OpenStack services return resources wrapped up in a top-level dict keyed with the base name of the resource.  This layer shall remove that wrapper so the returned values are all directly lists or dicts.  This removed the variations in server implementations where some wrap the list object individually and some wrap the entire list once.  Also, Keystone's tendency to insert an additional ``values`` key into the return.

api.identity_vX.APIvX
---------------------

The naming of `identity_v2.APIv2`_ and `identity_v3.APIv3`_ is a bit repetitive but putting the version into the module name lets us break down the already-long files.

.. _`identity_v2.APIv2`: https://github.com/dtroyer/python-openstackclient/blob/low-level-api/openstackclient/api/identity_v2.py#L19
.. _`identity_v3.APIv3`: https://github.com/dtroyer/python-openstackclient/blob/low-level-api/openstackclient/api/identity_v3.py#L19

At this point, only ``project_list()`` is implemented in an effort to work out the mechanics of supporting multiple API versions.  In OSC, this is already handled in the ClientManager and individual client classes so there is not much to see here.  It may be different otherwise.

Now What?
---------

Many object models could be built on top of this API design.  The ``API`` object hierarchy harkens back to the original client lib ``Manager`` classes, except that they encompass an entire REST API and not one for each resource type.

But You Said 'Sanity' Earlier!
------------------------------

Sanity in terms of coalescing the distinct APIs into something a bit more common?  Yes.  However, this isn't going to fix everything, just some of the little things that application developers really shouldn't have to worry about.  I want the project REST API docs to be usable, with maybe a couple of notes for the differences.

For example, OSC and this implementation both use the word ``project`` in place of ``tenant``.  Everywhere.  Even where the underlying API uses ``tenant``.  This is an easy change for a developer to remember.  I think.

Also, smoothing out the returned data structures to not include the resource wrappers is an easy one.

Duplicating Work?
-----------------

"Doesn't this duplicate what is already being done in the OpenStack Python SDK?"

Really, no.  This is meant to be the low-level SDK API that the Resource model can utilize to provide the back-end to its object model.  Honestly, most applications are going to want to use the Resource model, or an even higher API that makes easy things really easy, and hard things not-so-hard, as long as you buy in to the assumptions baked in to the implementation.

Sort of like OS/X or iOS.  Simple to use, as long as you don't want to anything different.  Maybe we should call that top-most API ``iOSAPI``?
