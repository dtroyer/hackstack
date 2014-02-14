---
title: Client Layers
author: dtroyer
date: 2014-02-11 02:11:00
categories: OpenStackClient SDK
tags: projects
xdraft: true
---

[Work In Progress, you have been warned]

So clients are like pie.  Creamy, gooey, butterscotch cream pie with meringue.  Known at the in-laws house as Baby Bear Pie for reasons unknown-to-me.  Meringue is yummy but not much by itself.  Pie crust does its job most of the time without being noticed, unless it is sub-par.  It's the cream filling that gets all of the attention.  Butterscotch, lemon or chocolate, that's where the glory is.

REST clients are like pie, what with their multiple layers of communication handlers, data marshallers and output formatters and all.  So lets talk client crust.  It is the least sexy of the layers, going about its job, semi-appreciated when it is right, scorned when it is bad and otherwise taken for granted.  In OpenStack we have a large number of client projects that all talk to REST APIs.  Without going too far into the history, most of these are forks of forks and all have been independently enhanced and updated and none of them have more than a familial resemblance to each other.

Alessio Ababilov tried to fix this, actually making a working common REST layer for the (at the time) 5 or so client libraries.  This was proposed to oslo-incubator and has gained some traction of late.  Some things that did get merged early on were the change to use the Requests package to replace httplib2, but that did nothing to unify the low-level internal API.

Rather than try to fix the legacy clients the right solution here is to define some requirements and build a solid common foundation that API libraries can build on.  Rather than call it crust, let's use the even-less-sexy 'transport layer' name, totally mis-appropriated from the OSI stack.

Independent of the Oslo apiclient work, Jamie Lennox rebuilt the transport layer of keystoneclient as part of a refactor of the authentication bits into pluggable classes.  This happens to be excitingly close to what I had been prototyping in OpenStackClient and was possibly the biggest highlight of the week in Hong Kong.

So lets see if we can't turn that into a generic SDK-style transport layer for our clients.  On top of that we will layer the basic OpenStack API version discovery, authentication and service catalog.

Layer 1: Transport Layer
========================

The Transport Layer includes the basic components that implement the REST API client and essentially is a wrapper around the Python Requests package with some additional header handling and logging built in.

Design Notes
------------

The rationale for some of the differences from the 'traditional' client structure:

* There is only 1 client (HTTPClient) instance.  This takes the role similar to OpenStackClient's ClientManager class.  It handles the authentication for all APIs one time and contains the instances of the specific API client objects, which now are little more than containers for their Manager class instances.

Namespace
---------

Everything lives under the top-level ``openstack`` namespace

* ``openstack.restapi`` - The layer 1 transport and base classes (session, exceptions) and  base layer 2 classes (discovery, base clients, service catalog)
* ``openstack.restapi.auth`` - The base authentication classes
* ``openstack.restapi.identity``  - API-specific classes required for layer 2 operation (identity client)
* ``openstack.client.identity`` - The layer 2 classes for the Identity API (``.v2_0``, ``.v3``)
* ``openstack.client.<api>`` - Other layer 2 API classes

openstack.restapi.session.Session
---------------------------------

Session is the lowest layer, basically a wrapper that adds the following to requests.Session:

* create a new requests.Session instance if one is not supplied (using requests.Session implies the TLS control lies here and is one reason for passing in an existing Session)
* populate the X-Auth-Token header from an auth object contained by the Session that implements a get_token() method
* populate headers as required: User-Agent, Forwarded, Content-Type
* change requests' redirect handling to be more appropriate for an API
* include wrappers for the REST methods: head(), get(), post(), put(), delete(), patch()
* debug logging of request/response data

openstack.restapi.baseclient.Client
-----------------------------------

The base Client class defines the methods that reflect into the Session.

* create a new Session instance if one is not supplied
* contains a ServiceCatalog instance (applications requiring multiple identity contexts at a time should use multiple Client instances)
* performs the API version discovery (see ApiVersion class below)
* define the cache interface for client-side caching of API data
* include wrappers for the REST methods: head(), get(), post(), put(), delete(), patch()


openstack.restapi.base.BaseAuthPlugin
-------------------------------------

The abstract auth plugin class

  * handles the specifics of authenticating a user and providing a token to Session when requested via get_token()

openstack.restapi.httpclient.HTTPClient(baseclient.Client, base.BaseAuthPlugin)
-------------------------------------------------------------------------------

HTTPClient is the primary interface used by the project API layers (gooey-creamy!).

* creates a ServiceCatalog from the token received from Identity
* uses ``keyring`` to cache tokens

* authenticate() calls get_raw_token_from_identity_service()

openstack.restapi.access.AccessInfo
-----------------------------------

Base class for auth plugins

* defines the basic auth interface
* AccessInfoV2
* AccessInfoV3


Layer 2: Discovery
==================

Discovery rides just above the transport layer and is the logic used to determine the best API version available between those support by the server and the client.

openstack.restapi.api_discovery.ApiVersion
------------------------------------------

A resource class for API versions used by BaseVersion

* normalizes version information

openstack.restapi.api_discovery.BaseVersion
-------------------------------------------

The root class for API version discovery.

* queries API server for supported version information
* normalizes both server and client versions
* select the appropriate version from those availalble (if possible)

openstack.restapi.identity.client.IdentityVersion(api_discovery.BaseVersion)
----------------------------------------------------------------------------

A Version discovery class that handles the peculiarities of Keystone

* optionally removes 'v2.0' from the auth_url to do proper discovery on old-style deployment configurations
* normalizes the returned dict to remove the ``values`` key

Layer 2: Authentication
=======================

Layer 2: Service Catalog
========================


Examples
========

Create A Session With Private CA Certificates
---------------------------------------------

::

    session = api_session.Session(
        verify=ca_certificate_file,
        user_agent=USER_AGENT,
    )

Add A Base Client
-----------------

::

    client = httpclient.HTTPClient(
        session=session,
        auth_url="https://localhost:5000",
        project_name="sez-me-street",
        username="bert",
        password="pidgeon",
    )

Identity Version Discovery
--------------------------

::

    # Supported Identity client classes
    API_VERSIONS = {
        '2.0': 'keystoneclient.v2_0.client.Client',
        '3': 'keystoneclient.v3.client.Client',
    }

    ver = identity.client.IdentityVersion(
        clients=API_VERSIONS.keys(),
        auth_url="https://localhost:5000",
    )
    print "client class: %s=%s" % (ver.client_version.id, API_VERSIONS[ver.server_version.id])
