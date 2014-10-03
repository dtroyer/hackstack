---
title: A Funny Thing Happened On The Way To The Summit
author: dtroyer
date: 2014-10-03 10:03:00
categories: OpenStack
tags: projects
xdraft: true
---

So back in `the old days </x/blog/2013/09/05/openstack-seven-layer-dip-as-a-service/>`_ I started throwing around different terminology to describe some of the technical relationships between OpenStack projects because it was useful to sort out things like startup order requirements in DevStack and other semi-obvious stuff.

And wow have things happened since then.  To recap, oh nevermind, I'm just going to take back the term **layer** for technical use and propose anything else other than **layer 1** (there is no other layer?) for the rest of the conversation. The various alternate approaches all boil down to a **nucleus** with a cloud (heh) of projects with probabilistic locations.  I wasn't a physics major but I do know that doesn't sound like that Q-word that shall not be spoken.

I think it is important to remember that one of the primary purposes of OpenStack is to enable the creation of **useful clouds**.  In my dictionary what makes a useful cloud is described as "the set of services that enable useful work to be done".  In a cloud.

The original layers idea has been picked up, painted, folded, carved and whitewashed to a shadow of its original.  Even so, in the end all of the ideas still end up looking similar.  Now seems like a good time to see how the orignal layers have held up.

Layer 1
-------

*We're still the one...*

We open with the addition of Neutron as a viable alternative to Nova Network, and the likelihood of it becoming the default configuration in DevStack early in the Juno cycle.

  * Identity (Keystone)
  * Image (Glance)
  * Network (Neutron)
  * Compute (Nova)

What really stands out to me now is the realization that all of these were originally part of Nova itself (plus the cinder volume service, more on that later).  They were broken apart or re-implemented to scale the development as Nova kept growing.  In fact, there is talk again of need to break out more simply because Nova continues to expand.

This is the smallest working set for a compute-enabled cloud.  Realistic useful clouds of course offer more than this, so we have...

Layer 2
-------

Layer 2 services are optional in a useful compute cloud but some are also useful in their own right as non-compute cloud services.

So the current Layer 2 still contains:

  * Volume (Cinder)
  * Object (Swift)
  * Bare-metal (Ironic)

These all build on the Layer 1 nucleus and get us a practical useful cloud.  They also all have the characteristic of having dependency arrows pointing *out* of Layer 1 when used with a compute cloud, such as Glance using Swift as its backend store.  This is a defining characteristic that brings a project in to Layer 2.

Even though Cinder was literally carved out of the Nova code base it stays in Layer 2 because it is an optional service to a Layer 1 cloud.  Manila will also fit here for the same reasons.

I neglected to mention last time the ability of Swift to stand alone as a useful cloud service as it has maintained its own authentication capability.  However, using it with any other OpenStack services requires Swift to use Keystone.

I also think it is worth considering the direction of the trademark usage constraints the board is refining with the DefCore work.  The current DefCore capability proposal is satisfied using only Layer 1 and 2 projects.  Also, the stand-alone services currently would not be able to qualify for trademark usage when deployed alone.

Layer 3
-------

Do something useful.  Host services for paying customers.  Provide Lego blocks for them to build awesome cloud apps.  Warn about runaway ``while true; done`` loops.  Count cycles burned and bits sent so paying customers know what to pay.  Communicate with your useful cloud.

The rest of the OpenStack-affiliated projects (for some value of *affiliated*) go in Layer 3 to populate the **big tent**.  If we've done our job right the majority of everything else should be able to be accomplished without special consideration from Layers 1 and 2.  Broad categories of Layer 3 projects include:

  * User Interfaces - You need one but a feature of well documented REST APIs is allowing the client side to be easily replaceable.

    * Orchestration (Heat) (it is basically a smart automated cloud client, no?)
    * Web UI (Horizon)
    * <insert-one-of-the-other-CLI-or-web-clients-here>

  * Something-as-a-Service - These are all services a deployer may choose to offer.

    * Database (Trove)
    * Message Passing (Zaqar)

  * Tracking Snooping and Counting - Keeping an eye on the useful cloud

    * Telemetry (Ceilometer)

Why is Heat in Layer 3???  Heat is essentially a smart automated cloud client and should be treated as one.   It needs to meet the same requirements for API compatibility to be useful over time.

Layer 4
-------

Layer 4 is everything else that is not OpenStack-affiliated but might be a part of an especially useful OpenStack cloud.  Things like Ceph or Apache jclouds are useful with and as part of OpenStack clouds, but they also have a life of their own and we should respect that and not call late at night.

What About Layer 0?
-------------------

Ah, right, where the Libraries live.  The last year has seen significant changes to how OpenStack-related libraries are integrated with a number of Oslo libraries being released stand-alone.  In most cases these can and should be thought of as dependencies just as any non-OpenStack project dependency (like ``SQLAlchemy`` or ``requests``) that happen to live in either the ``openstack`` or ``stackforge`` namespaces in our Git repositories.

It also seems appropriate to add the client API libraries and SDKs to Layer 0 as the dependency model and release schedule is very similar to the other libraries.  I am specifically not including command-line interfaces here as I think those belong in Layer 3 but the project client libraries have an embedded CLI so the'll straddle the boundaries no matter what.


So How Do We Govern and Test All This?
--------------------------------------

OK, I lied.  I said I would skip this, but anyone still reading must think this is has a thread of merit, right?  I choose to make that assumption going forward, and those of you still reading for a laugh, here is your cue.

I'll lay out an overview of a developers perspective because I am primarily an OpenStack developer and I need the world to know what I think.  However, I am also an application developer and cloud end-user so those perspectives are not lost.  I have not managed to add cloud deployer to my CV, yet.

Releases
~~~~~~~~

If you turn your head sideways and squint, the Layer picture can also be grouped according to release-able/deploy-able units with decently defined and documented interfaces between them.

Maintaining the current notion of an Integrated Release the layers fall out like this:

  * Layers 1 and 2 *are* the Integrated Release.  The services required to meet DefCore are currently a subset of these layers.
  * Layer 3 projects treat the Integrated Release as a dependency like any other they may have so they can have the freedom to iterate at a pace that suits the service being provided.  Trove probably needs fewer releases in the next year than Zaqar.

Switching to a more modularized set of released units the first 'natural' groupings are:

  * Layer 1 plus the semi-tightly coupled Nova projects like Cinder (and Manila) comprise a Compute Release.
  * Swift comprises an Object Store release
  * Ironic comprises an (insert-catchy-name-here) release and not in the Compute Release as it can also stand alone (right?)
  * Actually, everything else is on its own because Independence From Tyranny!  Things that need to talk to each other or to the Integrate projects need to correctly identify and handle the documented APIs available to them.

Basically, this alternative splits the Integrated Release into a Compute Release and two stand-alone releases for Swift and Ironic.  The Release Management team may reconsider the criteria required for them to continue to handle other project releases or allow (force?) the projects to handle their own.

Note how the difference in those two approaches to releases is exactly two things, pulling Swift and Ironic out of the Integrated Release bundle so they can stand alone.

Testing
~~~~~~~

As current work is showing, the actual detailed relationships between OpenStack services is very complex.  Describing it to a level of detail that can drive a test matrix is not simple.  We can, however, reduce the problem space by re-thinking at a higher level what needs to be tested together.

Layers 1 and 2 are really where the work needs to be done. By changing the perspective of Layer 3 projects we can reduce the piling-on of additional projects that are currently in our Test All The Things check/gate jobs.  Individual project relationships across that boundary may be important enough to warrant specific test jobs but those are considered exceptions and not the rule.

A significant amount of the gains to me made here are contingent on the projects developing comprehensive functional tests.

Horizontal Projects
-------------------

While it feels like I'm saving the best for last, in reality much of the above has to have some structure to know the scope that Infrastructure, Docs and QA need to be able to support.  Focusing these on Layers 1 and 2 provides a clear limit to the scope required.  This is not to say that other projects are not going to be accommodated, particularly those already in the current release, but it does say that it is not assured.

Now What Smart Guy?
-------------------

With my thoughts on Layers updated to include the governance and testing considerations it is time to match up other perspectives, flesh out the above with the new information and catch up on the plethora of other posts on this topic.

Film at eleven...
