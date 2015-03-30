---
title: OpenStackClient Is Official
author: dtroyer
date: 2015-03-18 15:03:18
categories: OpenStackClient
tags: openstack openstackcleint
draft: true
---

So it finally happened after a couple of false starts over the years, OpenStackClient
has been officially added to the list of OpenStack projects.

It is the first
new project added as part of the 'big tent' governance changes even though the
Technical Committee is still wrestling with implementation of the tagging process
that they expect to use as the advertisement for capabilities and status.  I'm
not going to rehash that here, now, though...

Looking Backward
================

I don't want to spend too much energy looking at where we have been, except to note
that a lot has happened since dolphm and I shared a cab to SFO and I floated the
idea of scrapping all of the OpenStack project CLIs and starting over.  He was
just receptive enough that I spent most of the flight home teasing out the basic
set of command objects and actions.

That right there is what I consider the big win for OSC, having a small set of
common actions and a set of known objects that are manipulated with those
actions.  Define a common operation and then do that operation on _EVERY_
object the same way, even if that means a bunch of work under the hood because
the REST API doesn't work that way.

One now-forgotten tidbit here is that I designed the commands to look similar
to VMS's DCL command line set, in that the action preceeds the object.  One
complaint was that the objects needed to be pluralized on some commands like list
because that's the proper English thing to do.  I ignored plurals completely,
although it does seem like we could have done it only with the list command.

It was at the Portland summit that I was persuaded to make the change when
someone who understands bash command completion better than I do (which is
'I never looked at it') mentioned that it would be _much_ simpler if the
object came first.  OK, finally, a good technical reason to change so we did.
I think dhellmann said something like "I expected that to be much harder"
afterward.  I do change my mind, sometimes.

Looking Around Today
====================

In the last nearly-three years we have had ~570 commits from ~70 contributors.

We have a couple of interesting features brewing for the next significant release,
support for the ``os-client-config`` cloud configuration files and a client-side
caching that will significantly improve responsiveness in many instances.

Looking Ahead
=============

Where we go from here is somewhat obvious, switch to use the OpenStack SDK when
it is ready, keep adding support for the lower layer services, enable plugins
to support upper layer services.  Most importantly, we MUST drive down the
number of dependencies required to install OSC and make it easy to use for
non-Python developers.

I do still want to re-write it all in Go...
