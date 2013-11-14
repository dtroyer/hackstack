---
title: OpenStack Icehouse Developer Summit
author: dtroyer
date: 2013-11-10 11:10:00
categories: OpenStack, DevStack
tags: openstack summit
---

OpenStack has had a global reach since the early days but the Design Summits
have always been a US-based affair.  Last week we finally took the every-six-month
roadshow off-continent and ventured out to Hong Kong.
Of course the Conference is co-located and concurrent but I didn't make it to
any of those sessions this time and only knew it was there by going to lunch in
the expo hall and seeing some familiar vendor faces.

We begin with the projects most subject to my attention, DevStack, Grenade and
OpenStackClient.

DevStack
========

This is the first summit where DevStack has program status and thus its own
track of two back-to-back sessions.  I hear russellb is jealous...

New Bits
--------

The DevStack 'New Bits' session (`EtherPad`__)
was spent talking about a couple of the significant additions
to DevStack late in the Havana cycle.  I wrote about the
`local config </x/blog/2013/09/07/devstack-local-config>`_
work as it was being developed, the discussion in the session was primarily a Q&A.
One bit that was covered was converting devstack-gate to use this form rather
than ``localrc``.

__ https://etherpad.openstack.org/p/icehouse-summit-devstacks-new-bits
 
The other major DevStack addition is a plugin mechanism
to configure and start additional services without requiring changes to DevStack.
This is partially intended for new projects to be able to use DevStack for their
Jenkins testing without requiring them to be added to the DevStack repo.

This is an expansion of the existing hook into ``extras.d`` that automagically
ran scripts at the end of ``stack.sh``.  These scripts are essentially 
dispatchers as they are called multiple times from ``stack.sh``, ``unstack.sh`` and
``clean.sh``.  `devstack.org <http://devstack.org/plugins.html>`_ has an example of an
``extras.d`` dispatch script.

Savanna and Tempest have been converted to the plugin format with Marconi in progress.
Most of the remaining `layer 4 </x/blog/2013/09/05/openstack-seven-layer-dip-as-a-service/>`_
projects should also be able to be converted to the plugin format.

Other highlights, some of which I intend to cover here in the future:

* bash8 - style testing for Bash scripts similar to hacking/pep8/flake8;
  there is interest in this becoming a stand-alone project if it proves to be useful

* DevStack tests - the addition of ``run_tests.sh`` provides a familiar, if
  deprecated, interface to running ``bash8`` and other tests

* exercises - the DevStack exercises are now unused in all gate testing except
  Grenade's *base* phase.  As they are still generally useful outside the
  gate test environment a new Jenkins job needs to be added to check them for bit rot.

Distro Support
--------------

sdague led the DevStack 'Distro Support' session (`EtherPad`__)
discussing distro supported status and what we need to do to bring the current
ones up to snuff and what might be required of new additions.

__ https://etherpad.openstack.org/p/icehouse-summit-devstack-support

The primary requirement to adding the support tag is the ability to have it tested
in the DevStack gate.  Unfortunately, neither of the clouds that provide
test resources to our CI infrastructure 
(HP Cloud and Rackspace Cloud Servers)
allow arbitrary images to be uploaded so only distros that have supported images 
are able to be tested.  The third-party testing hooks might be able to be used
to mitigate some of this but the resources for that testing will need to be supplied.

There was also some discussion around projects getting supported status from DevStack.
A lot of this is a timing and process issue for incubation/integration process wanting
to see testing before graduation from those steps but not wanting to add projects
to DevStack that are not on that track.  The addition of the extras.d capability
for projects to be easily added to DevStack without modifying it goes a long way
toward setting up the needed testing to demonstrate the capability of the project and
team before actually adding it to the repo.

The flow will look like:

* third-party testing in StackForge will utilize the extras.d plugins to do the
  required pre-incubation testing

* after incubation, the project gets added to the DevStack repo (still utilizing the
  plugin mech) and added to the gate as a requirement for graduation to integrated status.

Grenade
=======

The Grenade session (`EtherPad`__) focused mostly on expanding the test matrix
of ``base`` and ``target`` releases that need testing.  This includes tests from
stable releases to trunk and stable release updates as well as from 
stable release updates to next stable or trunk.

__ https://etherpad.openstack.org/p/icehouse-summit-qa-grenade

A couple of new control variables need to be added:

* Need to be able to turn off the ``db_sync`` operation for rolling upgrade
  testing that is not able to do the long-running sync operation.

* Need to designate services to not be upgraded, i.e. test everything new with the
  old nova-compute (``n-cpu``).

Adding more projects to Grenade is desirable, the conclusion on the initial set:

* Neutron is not ready; will not be considered for Grenade at least until it
  is voting in the gate.

* Ceilometer has no Tempest tests; in order to be added to Grenade it will also
  need tests backported to Tempest ``stable/havana``.

* Heat has few Tempest tests; is considered out of scope at this time.

* Trove needs to have Tempest tests and a Grenade plan by graduation from incubation.

There has also been some desire expressed to be able to use the upgrade scripts
outside of Grenade itself.  Right now they rely heavily on DevStack components,
the work to separate that is low priority, but contributions welcome as always.

OpenStackClient
===============

My favorite project returned to the regular session schedule in Hong Kong.  I
conducted our talk in Portland as an Unconference session partly because I really
just wanted to talk to the group of regular comitters to sort out a plan.  That
may have been short-sighted as the level of interest and contribution dropped off
sharply.  Oops.

This time around dhellmann offered an Oslo slot for OSC and I snapped it up as
that is probably the least ill-fitting track for it.  That had the side
effect of prompting the question of putting OSC under Oslo organizationally.
I am OK with that even though Oslo has traditionally been focused on
libraries and reusable code.  Another that has come up before would be to
treat it as a distinct project like Horizon.  We passed on that initially
in San Francisco as the consensus was that it was not large enough to warrant
that status, and that is still the case in my view.

In the session (`EtherPad`__) I reviewed the recent activities including the
0.2 release last July and the addition of unit test templates.

__ https://etherpad.openstack.org/p/icehouse-oslo-openstack-client-update

Implementation of the Objet API has begun, utilizing a new ``restapi.py`` module
to perform the low-level ``requests`` interface.  Why not just use swiftclient?
Good question, and at the time I was looking for an excuse to try out a
thinner approach to implementing the REST APIs.

I also have started work on API version detection, in parallel with a couple other
projects.  I see this as mostly a platform for testing approaches and to
free the client from requiring versions in the service catalog.

Future work will look into Jamie's Keystone auth refactor and leverage that
as the common REST library.  Segue...

Keystone Client
===============

The Keystone core devs were in the OSC session and strongly suggested I come to
their Keystone client sessions on Wednsday afternoon, which I was planning to do
anyway so my arm remained undamanged.  I finally met Jamie Lennox, who has been
doing a lot of work refactoring the auth bits of the client lib and absorbing
much of the bits Alessio started a whil eback and proposed to Oslo last May.

I liked most of what I heard and liked it even better after Jamie straightened out
some of my confusion-because-of-lack-of-source-code-reading at dinner Friday night.
I think we are on the same page to create the one client to rule them all and just
need to tune some details that are likely to appear after the post-summit haze clears.
And while this space doesn't officially speak for the projects I am core on, because
this is essentially my brain-dump space you, dear reader, get an advance look at
what is likely to be proposed sooner than later.

One CLI, one core^H^H^H^Hintegrated^H^H^H^H^H^H^Hbasic API lib, user-pluggable additional
API libs.  I see it like this:

* python-openstackclient - continues to be a single project focused on an ultra-consistent
  command line interface; directly consumes:
* python-os-identityclient - a new Identity API library born out of Jamie's refactoring
  auth/session work with a new library API that doesn't even try to be compatible with
  the old stuff.  No cli, speaks Identity v2 and v3, directly usable by all other libraries and
  projects to handle authenticated communication to openStack APIs.
* python-XXXclient - TBD how the division of the other API libraries fall out.  I want
  to minimize the number of moving parts for most users and not have the higher-level
  optional projects impose an undue burden on dependencies.

Other Bits
==========

All-in-all it was a good week, including multiple trips into the city for
sight-seeing, street-level eating, parties, 102nd story eating, death-marches down
Nathan Road in search of (open) Starbucks,
you know, all the usual stuff.  Breakfast in the airport every morning (Maxim's Deluxe
sticky-top cheese buns rule).  Catching up with team-mates over non-IRC channels.
Wondering WTF happened to jeblair's hat (my bet is HK customs impounded it,
even though afazekas managed to smuggle in his red fedora).  Wondering if Vishy and Termie
survived Macau without going broke the first night.

The OSF board finalized the intent to agree on an agreement on the definition
of ``core`` and how it is a totally overloaded word in the OpenStack world.
Wait, I may have dreamed part of that...or all of it.  Anyway, the usage of
`layers`_ when describing
the technical relationships of the projects seems to be catching on, I heard
it at least once outside the sessions where I used it.

.. _`layers`: 20130905-open-stack-layers.rst

And so the OpenStack March on Atlanta begins.  I have a hunch the city will
fare better next May than it did when General Sherman came for a visit back
in the day.  And I will forever hope that there will be more carbonated
caffiene.  I think Pepsi would be a fine choice given the locale, Mountain Dew
even.  In Coke's back yard, yeah, right.

It is too bad we're not
coming up to the 'S' release, I'd lobby for calling it Savannah just to enjoy
watching people trying to keep track of the Savanna Savannah release.  Or
would that be the Savannah Savanna release?  See, the fun we could have!

'J': Not Jacksonville, they are both in the wrong state and I don't want to
type that many letters.  Let's start a campaign for 'Joyland'!
