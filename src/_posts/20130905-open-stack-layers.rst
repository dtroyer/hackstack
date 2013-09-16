---
title: OpenStack - Seven Layer Dip as a Service
author: dtroyer
date: 2013-09-05 09:05:00
categories: OpenStack, Rant
tags: steam
---

OpenStack is, as it name implies, a stack of services to provide "components for a cloud infrastructure solution". [1]_  There are layers of services, some interdependent on each other, some only dependent on the layers below it.

For some time there has been a PC dance around 'labelling' projects that may or may not be at a layer that it wants to be in.  Back in the day, the term 'core' was thrown around to identify the services necessary to build an OpenStack deployment.  That term has been so misused and coopted and stomped on as to become unusable for technical discussions.  The OpenStack Foundation Board has an effort ongoing to define what 'core' means but they are focused on who and what is required in a deployment in order to use the trademarked OpenStack[tm] name and logo and not any determination as to layering of projects.  Go team, but that is not what we in the coding trenches need.

'Integrated' has become the term-du-jour for the TC to identify those projects that are part of the announced OpenStack release a the end of the development cycle.  That clearly identifies those projects that are administratively included but has no meaning for technical relationship/interface considerations.

For the sake of argument I am going to co-opt another term, stealing it directly from OSI networking terminology: 'layer'.  Layer is used there to describe the boundaries and interfaces between the functional components.  In OpenStack, the layers we have are the base infrastructure required to make something work, the additional services to make things integrate well with its surroundings and the services provided to the system and its users.  Really general terms there.

Layer Definitions
=================

Layer 0: Operating Systems and Libraries
----------------------------------------

[Because Real Programmers start with zero, right?]

OpenStack is built on top of the existing projects and technology that do the grunt work.  For completeness we will include the underlying components in Layer 0 even though these pieces are not part of OpenStack proper.

There are also a number of libraries specific to OpenStack (even though some may be useful elsewhere) that the other projects are dependent on but are not themselves operational services.  Most of these are encapsulated in the Oslo project.

Layer 1: The Basics
-------------------

The OpenStack stack begins with the Infrastructure as a Service.  This is the layer that everything else builds on.  This is also the focus of three of the four early OpenStack projects, once called 'core projects'.  But we've thrown out that c-word so now let's agree that this is simply 'OpenStack Layer 1'.  These are the interdependent services that form a minimal operational system and have no other OpenStack dependencies.

  * Identity (Keystone)
  * Image (Glance)
  * Compute (Nova)

Thats it.  Really.  At least until Nova Networking is removed and Network (Neutron) moves in to this layer as a required service for every deployment.

While this is contrary to what the board is saying regarding the definition of 'core', they are talking about user experience and legal definitions where I am talking about technical and architectural relationships.

Since Essex, most OpenStack services rely on Keystone to provide Identity services; Swift still is able to be deployed in a stand-alone configuration.  Nova requires Glance to supply bootable images.  Glance is able to use Swift if it is available and must be specifically configured to do so..  Similarly, Nova is able to use Cinder and Neutron if they are available and must also be configured to use them.

Layer 2: Extending the Base
---------------------------

Layer 2 services have the characteristic that they only depend on the services in Layer 1 and that Layer 1 services may be configured to use Layer 2 servies if available.  Nearly all deployments will include at least some of these services.

  * Network (Neutron)
  * Volume (Cinder)
  * Object (Swift)
  * Bare-metal (Ironic) - status: in incubation

Neutron will eventually become a Layer 1 service when Nova Networking is removed.

Ironic technically sits below Nova but is optional so it is in Layer 2.

Layer 3: The Options
--------------------

Layer 3 services are optional from a functional point of view but valuable in deployments that integrate with the world around them.  They integrate with Layer 1 and 2 services and are dependent on them for operation.

  * Web UI (Horizon)
  * Notification (Ceilometer)

Layer 4: Turtles All The Way Up
-------------------------------

Layer 4 catches everything else with an OpenStack sticker on the box.  This includes the rest of the XXaaS services and everything that is purely user facing, i.e. the OpenStack deployment itself does not depend on the service, it is only used by customers of cloud services.

  * Orchestration (Heat)
  * DBaaS (Trove) - status: to be integrated in Icehouse
  * DNSaaS (Moniker) - status: applying for incubation
  * MQaaS (Marconi) - status: in incubation

Relationships
=============

What does all this mean?  Probably not much outside of the following projects.  Really it is just a framework for terminology to describe and categorize projects by their purely technical relationships.

DevStack
--------

DevStack has struggled to keep from overgrowing its playpen and contain the effects of everyone with a project to pitch wanting to get it included.  Some basic hooks have been added to ``stack.sh`` to allow projects not explicitly supported in the DevStack repo to be included in ``stack``/``unstack`` operations.  More hooks are coming in the near future as ``stack.sh`` continues to get streamlined and make the projects follow a common template for installation/configuration/startup/etc.

DevStack's goal is to (soon!) clearly define the layers of services so developers can focus on the layers they care about and still have the ability to build the whole she-bang.  The DevStack layer scripts will also be hookable to allow additional (non-Integrated? non-Incubated?) projects the ability to self-integrate into DevStack without being in the repo.

The layered approach will be to install and configure the layers in order, with the exception that Layer 1 startup will be delayed until Layer 2 configuration is complete to allow the configuration changes to take effect.

Grenade
-------

Grenade only performs upgrade runs on Layer 1 and 2 services at the most, even then not including (yet?) all Layer 2 services.  Additional layers can only be added once a project is part of the DevStack stable release used as the Grenade ``base`` release.

OpenStackClient
---------------

OSC is not an official OpenStack project or program despite its existence in the OpenStack namespace on GitHub as it began before those concepts were fully-formed.  So in some regards it is not bound to the rules and conventions that apply to the other projects.  However, to do otherwise would be foolish.

OSC uses the Layers in determining the priorities for implementation of client commands.  It currently has implementations for Identity, Image, Volume and Compute APIs with plans for Object and Network to come.  It does have a simple plug-in capability that allows additional modules to be added independently without being part of the OSC repo.

Epilogue
========

[Quinn Martin Productions TV shows always had these, remember? Anyone?]

Other projects may or may not pick up this terminology, it depends on if it turns out to be useful to them.  There is a technical hierarchy of projects even if not everyone wants to acknowledge it, and the need for avoiding the existing hot-button terms seems to be increasing.


________

.. [1] Stolen directly from `openstack.org`_

.. _`openstack.org`: http://www.openstack.org/