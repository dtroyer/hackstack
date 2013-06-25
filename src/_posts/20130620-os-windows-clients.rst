---
title: OpenStack Clients on Windows
author: dtroyer
date: 2013-06-20 06:20:00
categories: OpenStack, Windows
tags: client windows
---

OpenStack command line clients are a pile of Python modules and dependencies and can be a real joy to install.  On Linux there are often vendor-maintained packages available to simplify the task and capture all of the dependencies, while on Windows it is a completely different story as no version of Windows includes any version of Python out of the box.

There are three layers to the Python stack to get the OpenStack clients (or any Python app really) installed and working on Windows: a Python interpreter/runtime, the Python modules that provide an interface to PyPI, and the client libraries and their dependencies.  Actually, all platforms have all of these layers but only Windows doesn't include any of them in the default installation so everything from the ground up needs to be installed.  And there is more than one way to do it. [1]_

The OpenStack client libraries are officially supported on Python 2.6 and 2.7.  While not yet complete, work is underway to support Python 3, the installation of which is left as an exercise for the reader.  (Hint: It's not too different from the below.)

**Python Runtime**

Contrary to `PEP 20`_ (The Zen of Python) [2]_ there is not one obvious way to install a Python interpreter on Windows.  Of course, each Python release includes official Python binaries for Windows at python.org, but the `Windows releases`_ page lists some of the other Python runtime packages that are available, each with their own particular set of advantages.  One additional that will be familiar to UNIX users is the `Cygwin`_ Python port; once Cygwin's Python interpreter is installed the rest is very similar to the steps here.

.. _`PEP 20`: http://www.python.org/dev/peps/pep-0020/
.. _`Windows releases`: http://www.python.org/getit/windows/
.. _`Cygwin`: http://www.cygwin.com/

This guide installs the official 32 bit 2.7.5 runtime on Windows 7.  It also works on XP and presumably Vista although that remains untested for some reason.   The Python runtime can be installed anywhere, the default is ``C:\Python27``.
If you change it remember to make the corresponding change in the rest of this guide.  Also, be aware that putting it in certain places, such as ``Program files``, will cause Windows UAC (Vista and newer) to require an administrative token to perform module installs.  While not impossible to deal with, this is beyond the scope of this guide for now.

* Download and install the `Windows runtime installer`_

.. _`Windows runtime installer`: http://www.python.org/ftp/python/2.7.5/python-2.7.5.msi

  * **Select whether to install Python for all users of this computer**: Select 'Install for all users'
  * **Select Destination Directory**: Accept the default Destination Directory ``C:\Python27\``.
  * **Customize Python**: The default selections are fine.  At a minimum the
    **Register Extensions** and **Utility Scripts** selections should be enabled.

* Add the destination directory to the System PATH via Control Panel

  * On Windows XP: **Control Panel → System → Advanced → Environment Variables**
  * On Windows 7: **Control Panel → System and Security → System → Advanced system settings → Environment Variables**
  * Edit the Path entry in the **System variables** list
  * Add the Python installation path and the Python scripts directory to the beginning of the Path variable, being careful to not remove the existing value: ``C:\Python27;C:\Python27\Scripts;``

Open a command prompt window and test the Python installation::

    Microsoft Windows [Version 6.1.7601]
    Copyright (c) 2009 Microsoft Corporation.  All rights reserved.

    C:\Users\dtroyer>python
    Python 2.7.5 (default, May 15 2013, 22:43:36) [MSC v.1500 32 bit (Intel)] on win32
    Type "help", "copyright", "credits" or "license" for more information.
    >>>


**Additional Python Modules**

In addition to the base Python runtime some additional modules are required to
bootstrap an environment for the OpenStack client install.  The ``setuptools``
module contains the ``easy_install`` command that we use to install ``pip`` which
is itself used to install additional modules and their dependencies from PyPI.

* Install `setuptools`_ using the `ez_setup.py`_ script::

    python ez_setup.py

.. _`setuptools`: https://pypi.python.org/pypi/setuptools/0.7.4
.. _`ez_setup.py`: https://bitbucket.org/pypa/setuptools/raw/0.7.4/ez_setup.py

* Install ``pip``::

    easy_install pip

Some common Python modules are not pure Python and require a C compiler to install
from PyPI.  Fortunately
many of these packages also have Windows binary installers that can be used with
the official Python runtime. 

OpenStack's Glance client requires pyOpenSSL which is one of these hybrid packages.
It can be installed from PyPI directly using the supplied binary Windows installer.

* Download and install the `pyOpenSSL installer`_

  * **Select whether to install Python for all users of this computer**: Select 'Install for all users'
  * **Select Python Installations**: The default Python installation should be the one installed above.  Use it.

.. _`pyOpenSSL installer`: https://pypi.python.org/packages/2.7/p/pyOpenSSL/pyOpenSSL-0.13.winxp32-py2.7.msi


**OpenStack Client Libraries**

The OpenStack command line clients are included with the Python API libraries.
They are released to PyPI independently of the periodic OpenStack releases
and are backward compatible with older OpenStack releases so it should always
be safe to upgrade the clients.  So even if you are using a Folsom-era
OpenStack installation the current client libraries are going to work.

* Install the client libraries from PyPI::

    pip install python-keystoneclient python-novaclient python-cinderclient \
      python-glanceclient python-swiftclient


________

.. [1] Yeah, my Perl is showing...
.. [2] ``python -c "import this"``