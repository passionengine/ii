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

Download and install required gems from the Gemfile, and use vagrant from the bundle.

```
git clone git://github.com/passionengine/ii.git
cd ii
#if you are using rvm
rvm use ree@ii --create 
gem install bundler
bundle install
alias vagrant="bundle exec vagrant"
```

Create a Vagrant basebox based on ubuntu-10.04 from the iso and install chef/puppet etc

```
vagrant basebox build vvii
```

Once you have the basebox defined and imported into your ~/.vagrant.d/boxes directory,
it is available for referencing from the Vagrantfile.

```
vagrant up
```

This provisions the new vvii box with chef-solo.

Basically populates ./cache within your host OS
with the files it will eventually populate into the guest os.

This directory is shared between vagrant provisoning runs, so you only have
to download all the big stuff once. Currently it's around 2.3 gig.

The results is a a chef-server, with the ability to provision linux and windows xp
via dhcp+tftp (pxe) that will eventually work against new Virtualboxes...
AND real hardware boxes.

Right now I'm limited because I haven't figured out how to create a Vagrant-basebox via veewee
that supports multiple nics:

```cucumber
Given a Vagrantfile pointing to a basebox with multiple network interfaces
When I need internet/network access (nat)
And I need NFS for fast access to shared cache (host-only)
And I need to boot real machines from a DHCP/TFTP service (bridge)
Then I should be able to configure the three network interfaces appropriately
```
