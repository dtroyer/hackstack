---
title: OpenStackClient Is Three and Official
author: dtroyer
date: 2015-04-18 15:03:18
categories: OpenStackClient
tags: openstack openstackclient
---

I was looking forward to writing a bit about OpenStackClient becoming the first
project added to OpenStack under the 'big yurt' [#]_ governance model.  It was
even mostly written and set to publish right after the QA Code sprint article
when Nebula did what so many startups do, which is to abruptly cease to exist.
On April 1 no less.  So instead I'll rehash this as a note on OSC's third birthday,
based on the first repo commit.

Looking Backward
================

I don't want to spend too much energy looking at where we have been, except to note
that a lot has happened since I shared a cab to SFO with Dolph Matthews and I floated the
idea of scrapping all of the OpenStack project CLIs and starting over.  He was
just receptive enough that I spent most of the flight home teasing out the basic
set of command actions and objects.  And he backed that up by later choosing to not
implement a CLI for the Identity v3 API but instead use OSC.

The rigorous `command structure`_ is what I consider the big win for OSC, having a
small set of common actions and a set of known objects that are manipulated with
those actions.  Define a common operation and then do that operation on **EVERY**
object the same way, even if that means a bunch of work under the hood because
the REST API doesn't work that way.

.. _`command structure`: http://docs.openstack.org/developer/python-openstackclient/commands.html

One now-forgotten tidbit here is that I designed the commands to look similar
to VMS's DCL command line set, in that the action preceeds the object.  One
complaint was that the objects needed to be pluralized on some actios, like ``list``,
because that's the proper English thing to do.  I ignored plurals completely,
although it does seem like we could have done it only with the list command.

It was at the Portland summit that I was persuaded to make the change when
someone who understands bash command completion better than I do (which is to say
'I never looked at it') mentioned that it would be **much** simpler if the
object came first.  OK, finally, a good technical reason to change so we did.
I think dhellmann said something like "I expected that to be much harder"
afterward.  I do change my mind, sometimes.

Looking Around Today
====================

In the three years we have had just over 1000 commits from around 70 contributors.
I want to grow the team; we have a small band of regulars now with
a core review team of 4, having recently added Terry Howe, who has also spent
a significant amount of time working on the Python SDK.

We have a couple of interesting features brewing for the next significant release,
support for the ``os-client-config`` cloud configuration files and a client-side
caching that will significantly improve responsiveness in many instances. [#]_

Another historical bit is that for most of its life, OSC was mostly a side project
for me.  I was able to eventually give it some real time along side DevStack and
the other things but it seems to be the kind of project that doesn't seem so
important until you really really need it now.

As I was talking to a lot of people over the last couple of weeks trying to find
my next professional home, it became clear to me how some people and organizations feel
about projects like OSC.  They're not sexy, not the sort of thing that 'sells'
customers on your cloud or your service or whatever.  There were a couple of companies
that totally did not view this as worth spending time on.  Fortunately for us all,
there are more companies that do think it is worth the time and I expect to be able
to give OSC and other client/app developer projects a significant part of my time
going forward.

When OSC was added as an official project, we also brought the `os-client-config`_
(from Stackforge) and `cliff`_ (from Oslo) repos with it.  ``Cliff`` was written
by Doug Hellmann specifically for OSC to manage the numerous command implementations
and give a solid basis for each of the actions.  I think it has worked out great
and been a great help in maintaining the consistency  in OSC so far.  It has also
been adopted by other projects, some outside of the OpenStack ecosystem.

``os-client-config`` (aka ``o-c-c``) was originated by Monty Taylor to add client-side
cloud configuration along with his `shade`_ library.
BTW, if you ever want to see what the challenges of using multiple clouds in the
same project, have a look at ``shade``.  In an ideal world it should not need to exist,
especially since it only talks to OpenStack clouds.

OSC will be using ``o-c-c`` to implement the same cloud configuration that will
make it **simple** to switch between cloud authentication configurations with a
single command line option.  And also to share public cloud configuration templates
without sharing authentication details for them.  I plan to follow up with details
on how to use this soon, watch this space.

.. _`cliff`: http://git.openstack.org/cgit/openstack/cliff
.. _`os-client-config`: http://git.openstack.org/cgit/openstack/os-client-config
.. _`shade`: http://git.openstack.org/cgit/openstack-infra/shade

Looking Ahead
=============

Technically we still have a lot of work to do.  There are significant APIs
that are still not implemented (Network, Volume v2) and incomplete (Image v1 and
v2).  We need to speed up the load time, eliminate unnecessary dependencies,
and fix bugs.  Always fix bugs.

On a slightly longer scope, we will switch to use the OpenStack SDK when
it is ready, continue to better enable plugins to support upper layer services,
and most importantly, we MUST drive down the
number of dependencies required to install OSC and make it easy to use for
non-Python developers.  There needs to be a single file install that 'just works'.

I do still want to duplicate it all in Go.  My Go prototype is older than
OSC, actually...and is a single file install...


----

.. [#] Yeah, I know the usual term is `big tent`.  Every time I hear that I
   think of a `big top` and I really don't want to be thought of as 'one of the
   clowns in the big top'... even if it might be accurate...

.. [#] **Update:** Caching didn't make it.