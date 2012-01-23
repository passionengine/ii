Description
===========

Configures a tftpd server for serving applications and installers over PXE.

To debug:
Use the following display filter in wireshark:

(!(tftp.opcode == 4)) && !(tftp.opcode == 3)

Requirements
============

In progress

Attributes
==========

Attributes under the `pxe_chef` namespace.

* `["pxe_chef"]["foo"]` - some interesting thing in the future

Templates
=========

defaultmenu.erb
----------------

Set's the menu option on first boot


Recipes
=======

Default
-------

The recipe does the following:

1. Downloads the proper netboot.tar.gz to boot from.
2. Untars it to the `[:tftp][:directory]` directory.
3. Instructs the installer prompt to automatically install.
4. Passes the URL of the preseed.cfg to the installer.
5. Uses the preseed.cfg template to pass in any `apt-cacher` proxies.

Usage
=====

Create a role, `pxe_server`.

    name "pxe_server"
    description "PXE Dust Boot Server"
    run_list("recipe[pxe_chef]")
    default_attributes(
      "pxe_chef" => {
      "foo" => "bar"
      }
    )

License and Author
==================

Author:: Chris McClimans <chris@instantifrastructure.org>

Copyright:: 2011 InstantInfrastructure.org

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
