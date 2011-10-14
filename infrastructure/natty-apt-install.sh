#!/bin/bash
# Ubuntu 11.04 Natty Chef-Server from opscode apt repo
exec > >(tee bootstrap.log|logger -t user-data -s 2>/dev/console) 2>&1
set -e -x

# short hostname and possible hostname with domain will have an alias to a loopback
if ! (grep "127.1.2.3 `hostname` `hostname | cut -d . -f 1`" /etc/hosts); then
    echo 127.1.2.3 `hostname` `hostname | cut -d . -f 1` | sudo tee -a /etc/hosts
fi

# chef will now point to loopback
if ! (grep "127.1.2.4 chef" /etc/hosts); then
    echo 127.1.2.4 chef | sudo tee -a /etc/hosts
fi

if ! (grep opscode /etc/squid-deb-proxy/mirror-dstdomain.acl); then
    # setup caching, lets not waste these downloads!
    apt-get -y install squid-deb-proxy squid-deb-proxy-client 
    # we get them from a few extra places... lets enable them!
    cat << EOF >> /etc/squid-deb-proxy/mirror-dstdomain.acl 
cdimage.ubuntu.com
ppa.launchpad.net
dl.google.com
apt.opscode.com
EOF
    service squid-deb-proxy restart
fi

if ! (grep opscode /etc/apt/sources.list.d/opscode.list); then
    echo     "deb http://apt.opscode.com/ `lsb_release -cs`-0.10 main" >  /etc/apt/sources.list.d/opscode.list
    echo "deb-src http://apt.opscode.com/ `lsb_release -cs`-0.10 main" >> /etc/apt/sources.list.d/opscode.list
fi

if ! [ -a /etc/apt/trusted.gpg.d/opscode-keyring.gpg ]; then
    mkdir -p /etc/apt/trusted.gpg.d
    gpg --keyserver keys.gnupg.net --recv-keys 83EF826A
    gpg --export packages@opscode.com | tee /etc/apt/trusted.gpg.d/opscode-keyring.gpg > /dev/null
    sudo apt-get update
fi


### using optcode apt repository

cat << EOF | sudo debconf-set-selections
# URL of Chef Server (e.g., http://chef.example.com:4000):
chef chef/chef_server_url string http://`hostname`:4000
# New password for the 'chef' AMQP user in the RabbitMQ vhost "/chef":
chef-solr chef-solr/amqp_password password `pwgen -1 32`
# New password for the 'admin' user in the Chef Server WebUI:
chef-server-webui chef-server-webui/admin_password password `pwgen -1 -A 6`
rabbitmq-server rabbitmq-server/upgrade_previous note
EOF

apt-get -y install opscode-keyring # permanent upgradeable keyring
apt-get -y install chef-server-webui # depends on everything

apt-get -y install debconf-utils #debconf-get-selections

chef-solo -c .chef/chef-apt-bootstrap-solo.rb # setup apache+ssl to point to chef etc
rm -f .chef/chef-apt-bootstrap-solo.json

# remove any current devops user
if knife client list -u chef-webui -k /etc/chef/webui.pem | grep devops
then knife client delete devops -y -u chef-webui -k /etc/chef/webui.pem -n; fi

# and create a new one
knife client create devops -f .chef/devops.pem -u chef-webui -k /etc/chef/webui.pem --defaults --admin -n

ruby <<EOF
require 'rubygems'
require 'chef/config'
require 'chef/webui_user'
Chef::Config.from_file(File.expand_path(".chef/knife.rb"))
user = Chef::WebUIUser.load('admin')
user.set_password("`debconf-get-selections | grep chef-server-webui | cut -f 4`")
user.save
EOF

echo "Visit https://chef:444 with user=admin and password=`sudo debconf-get-selections | grep chef-server-webui | cut -f 4`"
