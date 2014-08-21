---
title: OpenStack Clients
author: dtroyer
date: 2013-06-20 06:20:00
categories: OpenStack, Windows
tags: client windows
---

## OpenStack Client Projects

The developers of OpenStack maintain a series of [library projects](https://wiki.openstack.org/wiki/ProjectTypes) which are the Python interfaces to the OpenStack REST APIs and also include command-line clients:

* [python-ceilometerclient](http://launchpad.net/python-ceilometerclient)
* [python-cinderclient](http://launchpad.net/python-cinderclient)
* [python-glanceclient](http://launchpad.net/python-glanceclient)
* [python-heatclient](http://launchpad.net/python-heatclient)
* [python-keystoneclient](http://launchpad.net/python-keystoneclient)
* [python-novaclient](http://launchpad.net/python-novaclient)
* [python-quantumclient](http://launchpad.net/python-quantumclient)
* [python-swiftclient](http://launchpad.net/python-swiftclient)

Each project is managed through the same development process as the integrated OpenStack projects so you can expect to find the latest source on [GitHub](http://github.com/openstack). The master branch in the project repositories should theoretically never be 'broken,' but realistically they are not tested between releases with the same vigor as the core projects. The bug and feature tracking happens on Launchpad; each of the projects above are linked to their respective Launchpad projects.

The client libraries are simply REST (HTTP) API clients and are backward compatible with the core supported API versions. For example, ``python-novaclient`` works with any version of Nova that supports matching API versions.  The client projects are versioned and released to PyPI independently of the integrated OpenStack releases.  There is no 'Grizzly' version of ``python-novaclient``, for example, but any ``python-novaclient`` released after Grizzly's release will be compatible as long as the same API versions are enabled.

## Installing the Clients

Official releases of the clients are distributed by developers through [PyPi](http://pypi.python.org).  Some Linux distributions also package the clients in their native format (RPM, APT, etc).  As the client projects are still evolving quite rapidly, the packages distributed by the distributions can fall out of date.  However, the client packages distributed with Grizzly server packages will be known to be compatible with Grizzly.

Users who want to be curent or are working with OpenStack development releases will want to install the clients from PyPi. As there are drawbacks to using PyPi both methods will be covered here.

Most of the installation steps here require administrative privileges.  Python virtual environments (virtualenvs) can be used to work around this if necessary, in addition to their other benefits (see below).

### Python Runtime

OpenStack command line clients consist of a set of Python modules and their dependencies. There are three layers to the Python stack: a Python runtime, the Python modules that provide an interface to PyPI and the client library modules and their dependencies.  All supported platforms (Linux, OS X and Windows) have all of these layers but only Windows doesn't include any of them in the box so everything from the ground up needs to be installed.  And there is more than one way to do it.

The OpenStack client libraries are officially supported on Python 2.6 and 2.7.  While Python 3 is also available for all of these platforms, the work to support it in the clients is underway but not yet complete.

#### Linux Installation

Linux distributions usually include Python installed by default.  While all recent releases are Python 2.6 or 2.7, some long-term-support distributions may still contain Python 2.5 or older and require a newer Python runtime.  For example, [the OpenStack wiki](https://wiki.openstack.org/wiki/NovaInstall/CentOSNotes#CentOS_5.2F_RHEL_5_.2F_Oracle_Enterprise_Linux_5) documents installing Nova on RHEL 5 and friends.  From that document the steps to enable the EPEL repo and install Python 2.6 are sufficient to support installing the client libraries.

#### OS X Installation

All OS X releases since 10.6 (Snow Leopard) include a supported Python runtime although it is usually a few minor versions behind the current release.  Alternatives are available to install current versions of Python but are out of scope here.

OS X 10.5 (Leopard) includes Python 2.5.1 and needs to have particular considerations addressed in order to update it.  See the [Leopard wiki page](http://wiki.python.org/moin/MacPython/Leopard) for more information.  

#### Windows Installation

Windows has a couple of options for Python installations.  Each Python release includes official Python binaries for both 32-bit and 64-bit Windows. The python.org [Windows releases](http://www.python.org/getit/windows/) page lists some of the other Python runtime packages that are available.  One additional that will be familiar to UNIX users living in a Windows world is the [Cygwin](http://www.cygwin.com/) Python port. Once Cygwin's Python interpreter is installed the rest is very similar to the steps here.

This guide will use the official 32 bit 2.7.5 runtime on Windows 7 as the example installation but it also works on XP and Vista.  The Python interpreter can be installed anywhere, the default folder is ``C:\Python27``.  If you change it remember to make the corresponding change in the rest of this guide.  Also, be aware that putting it in certain places, such as ``Program files``, will cause Windows UAC in Vista and newer to require an administrative token to perform module installs.  While not impossible to deal with, this is currently beyond the scope of this guide.

  * Download and install the [Windows runtime installer](http://www.python.org/ftp/python/2.7.5/python-2.7.5.msi):

    * **Select whether to install Python for all users of this computer**: Select 'Install for all users'
    * **Select Destination Directory**: The default Destination Directory is ``C:\Python27\``.
    * **Customize Python**: The default selections are fine.  At a minimum the
      **Register Extensions** and **Utility Scripts** selections should be enabled.
  
  * Add the destination directory to the System PATH via Control Panel:

    * On Windows XP: **Control Panel → System → Advanced → Environment Variables**
    * On Windows 7: **Control Panel → System and Security → System → Advanced system settings → Environment Variables**
    * Edit the Path entry in the **System variables** list
    * Add the Python installation path and the Python scripts directory to the beginning
      of the Path variable: ``C:\Python27;C:\Python27\Scripts;``

Open a command prompt window and test the Python installation:

    Microsoft Windows [Version 6.1.7601]
    Copyright (c) 2009 Microsoft Corporation.  All rights reserved.

    C:\Users\fozzier>python
    Python 2.7.5 (default, May 15 2013, 22:43:36) [MSC v.1500 32 bit (Intel)] on win32
    Type "help", "copyright", "credits" or "license" for more information.
    >>>

### Python Module Distribution

In addition to the base Python runtime some additional modules are required to bootstrap an environment for the OpenStack client install.  The state of packaging in the Python world can be describes as 'in flux' at best.  That said, OpenStack uses the Python Package Index (PyPI) as its source of released packaged modules.

PyPI provides a mechanism to install released versions of Python libraries and tools directly.  The `pip` command is the interface to PyPI and performs the download and install functions as well as dependency resolution (albiet occasionally poorly).  It does not play well with packages installed by the native package managers on some systems (*cough* Red Hat *cough*). The former is a shortcoming that continues to be slowly addressed by the Python community but the latter can be treated with a tool called `virtualenv` (see below).

Many Python modules have also been packaged by Linux distributions and can be installed using the native package manager.  Often it is beneficial to install the vendor packages for hybrid modules especially if a C compiler is not present, or not desired, on the system.  The consensus in the OpenStack community is not to mix the two methods any more than necessary.

#### PyPI and pip

The [pip](http://www.pip-installer.org/) command must be installed to use PyPI and for non-native package installations that is best done using ``easy_install`` which itself needs to be installed as part of the ``setuptools`` module.  Check to see if ``setuptools`` is installed:

    python -c "import setuptools"
  
If ``setuptools`` is not installed an error similar to this will be displayed:

    Traceback (most recent call last):
      File "<string>", line 1, in <module>
    ImportError: No module named setuptools

  * If necessary, install [setuptools](https://pypi.python.org/pypi/setuptools/0.7.4) using the [ez_setup.py](https://bitbucket.org/pypa/setuptools/raw/0.7.4/ez_setup.py) script:

        python ez_setup.py

  * Install ``pip`` using ``easy_install``:

        easy_install pip

#### Hybrid Python Modules

Some common Python modules are not pure Python and require a C compiler to install from PyPI.  On Linux these are generally installed via native system packages.  On Windows many of these packages also have Windows binary installers that can be used with the official Python runtime. 

OpenStack's Glance client requires ``pyOpenSSL`` which is one of these hybrid packages.  On Linux install the vendor-supplied package. OS X 10.7 and newer include an acceptable version.  On Windows it can be installed from PyPI directly using the supplied binary Windows install package:

  * Download and install the [pyOpenSSL installer](https://pypi.python.org/packages/2.7/p/pyOpenSSL/pyOpenSSL-0.13.winxp32-py2.7.msi):

    * **Select whether to install Python for all users of this computer**: Select 'Install for all users'
    * **Select Python Installations**: The default Python installation should be the one installed above.  Use it.

#### OpenStack Client Libraries

Installing the client libraries from PyPI will also bring in the required dependencies.  This step is the same for all platforms.

  * Install the client libraries from PyPI:

        pip install python-keystoneclient python-novaclient python-cinderclient \
          python-glanceclient python-swiftclient

#### virtualenv

Using `pip` in conjunction with a tool called `virtualenv` can be used to isolate the PyPi packages you install from your system packages. Install `virtualenv` using `pip`:

    pip install virtualenv

A new virtual environment is created and activated with the following commands:

    virtualenv ~/openstack-venv
    source ~/openstack-venv/bin/activate

Once activated all packages installed with `pip` will be placed into the virtual environment without affecting or conflicting with the root system:

    pip install python-novaclient

Deactivating your virtual evironment is as simple as this:

    deactivate
    
For those of you that want to level-up your `virtualenv` experience, use a tool called `virtualenvwrapper`. It abstracts away the management of the virtual environment directories on your local system:

    mkvirtualenv openstack-venv
    workon openstack-venv
    
    pip install python-novaclient
    
    deactivate
    rmvirtualenv openstack-venv

### Distro-specific Package Managers

There are a couple of tradeoffs when consuming packages from distro-managed repositories. In the case of the OpenStack clients, development happens so rapidly that these repositories can grow stale very quickly. In the case that you still want to use a distro-specific package manager, it should be as simple as installing the python-*client packages. For example, here's how you can install python-novaclient on Ubuntu:

    apt-get install python-novaclient
    
## Using the Clients

### Authentication

The first thing to tackle is authentication. Each of the OpenStack clients supports a set of common command-line arguments for this:

    --os-username
    --os-password
    --os-tenant-name
    --os-auth-url

For example, the following is how you would list Nova instances while authenticating as the user `bcwaldon` on the tenant `devs` with the password `snarf` against the authentication endpoint `http://auth.example.com:5000/v2.0`:

    nova --os-username bcwaldon --os-password snarf --os-tenant-name devs \ 
         --os-auth-url http://auth.example.com:5000/v2.0 list

Alternatively, the OpenStack clients offer the same configuration through environment variables:

    export OS_USERNAME=bcwaldon
    export OS_PASSWORD=snarf
    export OS_TENANT_NAME=devs
    expot OS_AUTH_URL=http://auth.example.com:5000/v2.0
    nova list

### Discovering Commands

New features and commands are added to the client projects just about as quickly as the upstream core project development happens, so it is suggested that you 

Each of the openstack client projects have a `help` command that will print a list of available commands:

```
% cinder help
usage: cinder [--version] [--debug] [--os-username <auth-user-name>]
              [--os-password <auth-password>]
              [--os-tenant-name <auth-tenant-name>]
              [--os-tenant-id <auth-tenant-id>] [--os-auth-url <auth-url>]
              [--os-region-name <region-name>] [--service-type <service-type>]
              [--service-name <service-name>]
              [--volume-service-name <volume-service-name>]
              [--endpoint-type <endpoint-type>]
              [--os-volume-api-version <compute-api-ver>]
              [--os-cacert <ca-certificate>] [--retries <retries>]
              <subcommand> ...

Command-line interface to the OpenStack Cinder API.

Positional arguments:
  <subcommand>
    absolute-limits     Print a list of absolute limits for a user
    backup-create       Creates a backup.
    backup-delete       Remove a backup.
    backup-list         List all the backups.
    backup-restore      Restore a backup.
    backup-show         Show details about a backup.
    create              Add a new volume.
    credentials         Show user credentials returned from auth
    delete              Remove a volume.
    ...

Optional arguments:
  --version             show program's version number and exit
  --debug               Print debugging output
  --os-username <auth-user-name>
                        Defaults to env[OS_USERNAME].
  ...
```

Each `help` command optionally takes an argument:

```
% cinder help create
usage: cinder create [--snapshot-id <snapshot-id>]
                     [--source-volid <source-volid>] [--image-id <image-id>]
                     [--display-name <display-name>]
                     [--display-description <display-description>]
                     [--volume-type <volume-type>]
                     [--availability-zone <availability-zone>]
                     [--metadata [<key=value> [<key=value> ...]]]
                     <size>

Add a new volume.

Positional arguments:
  <size>                Size of volume in GB

Optional arguments:
  --snapshot-id <snapshot-id>
                        Create volume from snapshot id (Optional,
                        Default=None)
  --source-volid <source-volid>
                        Create volume from volume id (Optional, Default=None)
  --image-id <image-id>
                        Create volume from image id (Optional, Default=None)
  --display-name <display-name>
                        Volume name (Optional, Default=None)
  --display-description <display-description>
                        Volume description (Optional, Default=None)
  --volume-type <volume-type>
                        Volume type (Optional, Default=None)
  --availability-zone <availability-zone>
                        Availability zone for volume (Optional, Default=None)
  --metadata [<key=value> [<key=value> ...]]
                        Metadata key=value pairs (Optional, Default=None)
```

## Troubleshooting

If you installed the clients using `pip`, the best thing to do when you feel like your clients are 'broken' is to destroy your virtual environment and reinstall.

If this doesn't solve your problem, you're unfortunately at the point that you need to use your search of engine of choice to find help, start debugging Python code or file a bug on Launchpad.