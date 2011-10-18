Overview
========

ii allows you to provision windows xp and ubuntu boxes via network boot and provision them as chef-clients.


Current State
==========

I am able to boot windows xp and ubuntu, but they aren't provisioned as chef-clients.


Next Steps
==========

Install ruby and chef-client on ubuntu and xp with credentials to become new clients.


Getting Started
==========

Download and install required gems from the [Gemfile](https://github.com/passionengine/ii/blob/master/Gemfile#L7), and be sure to use vagrant from the bundle.

```
git clone git://github.com/passionengine/ii.git
cd ii
#if you are using rvm
rvm use ree@ii --create 
gem install bundler
bundle install
alias vagrant="bundle exec vagrant"
```

The VeeWee [vvii/definition.rb](https://github.com/passionengine/ii/blob/master/definitions/vvii/definition.rb) creates a Vagrant basebox from the ubuntu-10.04 iso with the help of our [preseed.cfg](https://github.com/passionengine/ii/blob/master/definitions/vvii/preseed.cfg) and [postinstall vagrant.sh](https://github.com/passionengine/ii/blob/master/definitions/vvii/vagrant.sh).

```
vagrant basebox build vvii
vagrant basebox validate vvii
vagrant basebox export vvii
vagrant box add vvii vvii.box
```

Once you have the basebox defined and imported into your ~/.vagrant.d/boxes directory,
it is available for referencing from our [Vagrantfile](https://github.com/passionengine/ii/blob/master/Vagrantfile#L3).

```
vagrant up
```

This provisions the new vvii box with chef-solo.

Basically populates ./cache within your host OS
with the files it will eventually populate into the guest os.

This directory is shared between vagrant provisoning runs, so you only have
to download all the big stuff once. Currently it's around 2.3 gig.

```
bundle exec ruby ./infrastructure/newubuntu.rb
bundle exec ruby ./infrastructure/newxp.rb
```

This should bring up a fresh new empty virtualbox, bridged to your new boot server.
Select Windows XP or Ubuntu Linux to install.
It should come up all the way.

Now bring up a real computer on the same bridged network and try it on real hardware as well.


The results is a a chef-server, with the ability to provision linux and windows xp
via dhcp+tftp (pxe) that will work against new Virtualboxes...AND raw hardware.
