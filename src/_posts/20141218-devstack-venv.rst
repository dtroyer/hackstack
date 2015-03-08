---
title: DevStack and Virtual Environments - Friends or Foes?
author: dtroyer
date: 2014-12-18 12:18:00
categories: DevStack
tags: openstack devstack
draft:true
---

DevStack has always utilized a mix of distro-provided and PyPI-installed
packages in creating the Python operating environment for OpenStack services.
The actual mix has varied over time, but as the complexity of the
environment continues to increase that mix swings toward more of the
packages coming from PyPI.

The extreme position of the swing toward PyPI packages is to build a virtual
environment that does not utilize system Python packages and run all of OpenStack
there.  DevStack has actively avoided using virtual environments, until now.

This is the story of shoving the venv rug *under* DevStack...

I've created ``tools/build_venv.sh`` to encapsulate all of the build logic
so it can stand alone or be called from ``stack.sh``,
similar to how ``tools/install_prereqs.sh`` is used.  Some
Python packages require distro packages to be installed to properly build
(pyOpenSSL, etc) so we need to install the distro packages and build and
install the PyPI packages
in the venv.

There is no mapping between PyPI packages and their distro-specific
package dependencies; DevStack has a set of files listing the package
requirements per-project for Debian/Ubuntu, Fedora/RHEL/CentOS and openSUSE,
but that is a little too broad for our base use.  A new file ``files/*/venv``
lists the dependencies, with comments linking back to the PyPI package
that requires it.  ``tools/build_venv.sh`` installs the distro packages
before doing the pip installs.

The list of Python packages to be installed by default is kept in
``files/venv-requirements.txt`` in the usual requirements file format.
``tools/build_venv.sh`` uses that as the source for additional packages
to install in the new venv, essentially feeding it directly to pip.
It also accepts package names on the command line.

Once ``tools/build_venv.sh`` successfully builds and installs all of the
requested packages, it is time to teach ``stack.sh`` to build the venv.
It turns out there are a handfull of places in DevStack that made some
assumptions or need to know when a venv is active:

* ``get_python_exec_prefix()`` needs to return the venv ``bin`` dir rather than
  the distro-supplied installation directory.
* ``pip_install()`` should not be root to install into a venv.
* Keystone running under ``mod_wsgi`` needs to know to activate the venv.
  This means modifying the ``.wsgi`` files in ``/var/www/keystone``, which as
  you might have noticed, have no ``.wsgi`` extension.
* Nova rootwrap is configured globally and is not required...move it into
  ``configure_nova_rootwrap()`` function.  But that's just cosmetic.  The real
  rootwrap problem is that sudo is resetting the PATH and the ``nova-rootwrap``
  binary can not be found, so set the default sudo path to $PATH.  In a more
  secure world we would append ``$VIRTUAL_ENV/bin`` to the default sudo path.

Setting ``USE_VENV=True`` in ``local.conf`` causes ``stack.sh`` to build a
virtual environment in ``/opt/stack/global-venv`` (by default, set
``VENV_PATH`` to change) and activate it so everything else uses it during that run.

The major problem now is anything that wants to run Python code in that
namespace must also activate the venv.  Saving off the venv environment
variables in ``.stackenv`` at the end of ``stack.sh`` simplifies the
activation in other scripts.  Adding the activation to ``openrc`` is
really the right solution as all DevStack exercises and other stuff
uses ``openrc`` to set up the operating environment.

As of post time this work is being done in `this review`_ in Gerrit.
Stay tuned to see how it all works out...

.. _`this review`: https://review.openstack.org/#/c/142822/
