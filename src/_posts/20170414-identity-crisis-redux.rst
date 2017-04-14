---
title: Who Are We?  Really?  Really!
author: dtroyer
date: 2017-04-14 04:14:00
categories: OpenStack
tags: stuffs
xdraft: true
---

[Most of this originally appeared in a `thread on the openstack-dev mailing list`_ but seemed interesting enough to repost here.]

.. _`thread on the openstack-dev mailing list`: http://lists.openstack.org/pipermail/openstack-dev/2017-April/115297.html

It is TC election season again in OpenStack-land and this time around a few days gap has been included between the self-nomination period and the actual election for those standing for election to be quizzed on various topics.  One of these questions[0] was the usual "what is OpenStack?" between One Big Thing and Loosely Familiar Many Things.

I started with a smart-alec response to ttx's comparison of OpenStack to Lego (which I still own more of than I care to admit to my wife): "something something step on them in the dark barefoot".  OpenStack really can be a lot like that, you think you are cruising along fine getting it running and BAM, there's that equivalent to a 2x2 brick in the carpet locating your heel in the dark.  Why are those the sharpest ones???

Back to the topic at hand:  This question comes up over and over, almost like clockwork at election time. This is a signal to me that we (the community overall) still do not have a shared understanding of the answer, or some just don't like the stated answer and their process to change that answer is to repeat the question hoping for a different answer.

In my case, the answer may be changing a bit. We've `used the term`_ 'cloud operating system' in various places, but not in our defining documents:

.. _`used the term`: https://www.openstack.org/software/

* The `OpenStack Foundation Bylaws`_ use the phrase "the open source cloud computing project which is known as the OpenStack Project"
* The `Technical Committee Charter`_ uses the phrase "one community with one common mission, producing one framework of collaborating components"
* The `User Committee Charter`_ does not include a statement on "what is OpenStack"

.. _`OpenStack Foundation Bylaws`:  https://www.openstack.org/legal/bylaws-of-the-openstack-foundation/
.. _`Technical Committee Charter`:  https://governance.openstack.org/tc/reference/principles.html#one-openstack
.. _`User Committee Charter`: https://governance.openstack.org/uc/reference/charter.html

I've never liked the "cloud operating system" term because I felt it mis-represented how we defined ourself and is too generic and used in other places for other things. But I've come to realize it is an easy-to-understand metaphor for what OpenStack does and where we are today.  Going forward it is increasingly apparent that hybrid stacks (constellations, etc) will be common that include significant components that are not OpenStack at layers other than "layer 0" (ie, below all OpenStack components: database, message queue, etc).  The example commonly given is of course Kubernetes, but there are others.

UNIX caught on as well as it did partly because of its well-defined interfaces between components at user-visible levels, specifically in userspace.  The 'everything is a file' metaphor, for all its faults, was simple to understand and use, until it wasn't, but it still serves us well.  There was a LOT of 'differentiation' between the eventual commercial implementations of UNIX which caused a lot of pain for many (including me) but the masses have settled on the highly-interoperable GNU/Linux combination. (I am conveniently ignoring the still-present 'differentiation' that Linux distros insist on because that will never go away).

This is where I see OpenStack today.  We are in the role of being the cloud for the masses, used by both large (hi CERN!) and small (hi mtreinish's closet!) clouds and largely interoperable.  Just as an OS (operating system) is the enabling glue for applications to function and communicate, our OS (OpenStack) is in position to do that for cloud apps.  What we are lacking for guidance is a direct lineage to 20 years of history.  We have to have our own discipline to keep our interfaces clean and easy to consume and understand, and present a common foundation for applications to build on, including applications that are themselves higher layers of an OS stack.

Phew!  Thank you again for reading this far, I know this is not news to a lot of our community, but the assumption that "everyone knows this" is not true, we need to occasionally repeat ourselves to remind ourselves and inform our newer members what we are, where we are headed and why we are all here in the first place: to enable awesome work to build on our foundation, and if we sell a few boxes or service contracts or chips along the way, our sponsors are happy too.
