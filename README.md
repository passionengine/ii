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

The above fails even thought I specifically install the multi_json gem in the [vagrant.sh postinstall](https://github.com/passionengine/ii/blob/master/definitions/vvii/vagrant.sh#L15).

```
FATAL: Gem::InstallError: gem_package[transmission-simple] (transmission::default line 31) had an error: multi_json requires RubyGems version >= 1.3.6
```

So just ssh into the newly broken box by running 'vagrant ssh'

```
vagrant ssh
Linux vvii 2.6.32-33-generic #72-Ubuntu SMP Fri Jul 29 21:08:37 UTC 2011 i686 GNU/Linux
Ubuntu 10.04.3 LTS

Welcome to Ubuntu!
 * Documentation:  https://help.ubuntu.com/
Last login: Sat Oct 15 02:29:29 2011 from 10.0.2.2
vagrant@vvii:~$ 
vagrant@vvii:~$ logout
Connection to 127.0.0.1 closed.
chris@breeze:~/boot/chef-repo$ vagrant ssh 
Linux vvii 2.6.32-33-generic #72-Ubuntu SMP Fri Jul 29 21:08:37 UTC 2011 i686 GNU/Linux
Ubuntu 10.04.3 LTS

Welcome to Ubuntu!
 * Documentation:  https://help.ubuntu.com/
Last login: Sat Oct 15 02:29:57 2011 from 10.0.2.2
vagrant@vvii:~$
```

And continue the chef-solo provisioning....

```
sudo su -
chef-solo -c /vagrant/cache/solo.rb -j /vagrant/cache/dna.json -l debug
gem update --system 1.3.7 #for some reason this doesn't seem to stick
service chef-expander start
service chef-solr start
service chef-server start
service chef-server-webui start
```

This provisions the new vvii box with chef-solo.

Basically populates ./cache within your host OS
with the files it will eventually populate into the guest os.

This directory is shared between vagrant provisoning runs, so you only have
to download all the big stuff once. Currently it's around 2.3 gig.

The results is a a chef-server, with the ability to provision linux and windows xp
via dhcp+tftp (pxe) that will eventually work against new Virtualboxes...
AND real hardware boxes.
