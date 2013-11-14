---
title: OpenStack Icehouse Developer Summit
author: dtroyer
date: 2013-11-10 11:10:00
categories: OpenStack
tags: openstack summit
---

Wow, OpenStack had already gone global but finally proved it by
taking the every-six-month roadshow called the Developer Summit (OSDS) to Hong Kong.
Of course the Conference is co-located and concurrent but I didn't make it to
any of those sessions this time and only know it was there by going to lunch in
the expo hall and seeing some familiar vendor faces.

During the wrap-up session at the end the feedback regarding room size
and the influx of non-technical folk filling the rooms was mostly positive.
There will always be a certain amount of that, especially in the high-visibility
and vendor-heavy projects but raising the bar for crashing sessions
seems to have lessened the impact on technical work getting done.  This is always a
sensitive subject because we do not want to be elitist or exclusive, but we actually
do.  Exclusing anyway to those who have typed ``git review`` and received +2/+A
at least once in the previous six months.  (If you don't know what that means,
then you will probably lose interest in the rest of this post quickly.  sorry.)
These sessions are meant to cover specific technical topics and the off-topic comments
and questions in prior summits have prevented that from happening at times.

Again, my focus starts with the three projects I am core on, DevStack, Grenade
and OpenStackclient.  All three had sessions this time around, and DevStack
even has 'program' status now which basically means Thierry designamtes a slot
or two for it from the top.  Doug Hellmann loaned OSC a slot and there may be
further organizational ties in that direction (more later).

**DevStack**

New Bits

DevStack added some significant changes late in the Havana cycle and I felt it
warranted some time to talk about them and get some feedback on the direction
and completeness of those additions.  The `local config`_ work has gotten coverage
here already while extras.d has not been addressed.

!!!TODO: fix internal link
.. _`local config`: 20130917-devstack-local-config

Other highlights, some of which I intend to cover here in the future:

* bash8 - style testing for Bash scripts similar to hacking/pep8/flake8; there
is interest in this becoming a stand-alone project if it proves to be useful

* DevStack tests - the addition of ``run_tests.sh`` is to provide a familiar,
if deprecated, interface to running the bash8 and other tests

* Exercises - the DevStack exercises are now unused in all gate testing except
Grenade's 'base' phase.  As they are still generally useful outside the gate
test environment a new Jenkins job needs to be added to check them for bit rot.

Distro Support

sdague led a session discussing distros with supported status by DevStack and
what we need to do to bring the current ones up to snuff and what might
be required of new additions.

The primary requirement to adding the support tag is the ability to have it tested
in the DevStack gate.  Unfortunately, neither of the clouds that provide
test resources to our CI/infrastructure allow arbitrary images to be uploaded
so only distros that have supported images in HP Cloud and Rackspace Cloud Servers
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

**Grenade**

**OpenStackClient**

Still my favorite target of +2/+A returned to the regular session schedule.  I
conducted our talk in Portland as an Unconference session partly because I really
just wanted to talk to the group of regular comitters to sort out a plan.  That
may have been short-sighted as the level of interest and contribution dropped off
sharply.

This summit dhellmann offered an Oslo slot for OSC and I snapped it up as there really
isn't any other cross-project home.  That had the side effect of prompting the question
of putting OSC under Oslo organizationally.  While until now Oslo has been focused on
libraries, I am OK with that.  It would not change names, repos or anything.  another
option has been to treat it like Horizon as a distinct project.  We passed on that initially
in San Francisco as the consensus was that it was not large enough to warrant that status.
That is still the case in my view, but as it grows and absorbs additional layers of
the client stack that may change.

**Keystone Client**

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

**Other Bits**

All-in-all it was a good week.  Multiple trips off Landau Island into the city for
sight-seeing, street-level eating, parties, 102nd story eating, death-marches down
Nathan Road in search of (open) Starbucks,
you know, all the usual stuff.  Breakfast in the airport every morning, Maxim's Deluxe
sticky-top cheese buns rule.  Catching up with team-mates over non-IRC channels.
Wondering WTF happened to jeblair's hat (my bet is HK customs impounded it,
even though afazekas managed to smuggle in his red fedora).  Wondering if Vishy and Termie
survived Macau without going broke the first night.

On top of it all, the OSF board may have finally determined how to determine what 'core'
means in our world even though the two largest public cloud deployments don't qualify.
This is exactly why that word must be avoided in all technical contexts in OpenStack.
I like `layers`_ for describing the technical relationships of the projects.

.. _`layers`: 20130905-open-stack-layers.rst

And so the OpenStack March on Atlanta begins.  I have a hunch the city will fare better
next May than it did when Sherman came for a visit back in the day.  And I will forever
hope that there will be more carbonated caffiene.  I think Pepsi would be a fine
choice, Moountain Dew even.  In Coke's back yard, yeah, right.

It is too bad we're not
coming up to the 'S' release, I'd lobby for calling it Savannah just to mess with people
trying to keep track of the Savanna Savannah release.  Or would that be the Savannah
Savanna release?  See, the fun we could have!

'J': Not Jacksonville, too far away and I don't want to type that many letters.


