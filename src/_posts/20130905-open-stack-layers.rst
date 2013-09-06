---
title: OpenStack - Stack or Not?
author: dtroyer
date: 2013-09-05 09:05:00
categories: OpenStack, Rant
tags: steam
---

**Draft Rant**

OpenStack is, as it name implies, a stack of services to provide <insert-mission-statement-here>.  There are layers of services, some interdependent on each other, some only dependent on the layers below it.

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
  * Bare-metal (Ironic) - should it be here?

Neutron will eventually become a Layer 1 service when Nova Networking is removed.

Layer 3: The Options
--------------------

Layer 3 services are optional from a functional point of view but valuable in deployments that integrate with the world around them.  They depend on Layer 1 and 2 services.

  * Notification (Ceilometer)

Layer 4: Turtles All The Way Up
-------------------------------

Layer 4 catches everything else with an OpenStack sticker on the box.  These are the rest of the XXaaS services. and everything that is purely user facing, i.e. No part of the OpenStack deployment itself depends on the service, it is only used by customers of cloud services.

  * Orchestration (Heat)
  * Database (Trove)
  * Naming(?) (Moniker) - status?

Relationships
=============

Expressing how other projects/programs/ad-hoc stuff relaes to the Layers.

DevStack
--------

We have struggled to keep DevStack from overgrowing its playpen and contain the effects of everyone with a project to pitch wanting to be included.  We have been slowly re-factoring ``stack.sh`` to allow simple additional scripts to run at the end with the complete environment available to simplify adding the higher-layered projects.  

My goal is to (soon!) have a layered DevStack that can independently build the layers of services so developers can focus on the layers they care about and still have the ability to build the whole she-bang.  The DevStack layer scripts will also be hookable to allow additional (non-Integrated? non-Incubated?) projects the ability to self-integrate into DevStack without being in the repo.

Grenade
-------

Grenade only performs upgrade runs on Layer 1 and 2 services at the most, even then not including (yet?) all Layer 2 services.  Additional layers can only be added once a project is part of the stable release used as the Grenade ``base`` release.

OpenStackClient
---------------

OSC is not an official OpenStack project or program despite its existence in the OpenStack namespace on GitHub as it began before those concepts were fully-formed.  So in some regards it is not bound to the rules and conventions that apply to the other projects.  However, to do otherwise would be foolish.

OSC uses the Layers in determining the priorities for implementation of client commands.  It currently has implementations for Identity, Image, Volume and Compute APIs with plans for Object and Network to come.  It does have a simple plug-in capability that allows additional modules to be added independently wihtout being part of the OSC repo.

Epilogue
========

[This has not been a Quinn-Martin Production.  Remember those?]

The purpose here is to provide a nomenclature useful to discuss the hierarchy of projects as reflected in the projects above.  I'm including these three due to m direct involvement in them, this may also apply to Tempest or something else I am not aware of but I can not speak for those projects.
