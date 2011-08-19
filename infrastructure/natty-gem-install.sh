#!/bin/bash
# Ubuntu 11.04 Natty Chef-Server from gem
exec > >(tee bootstrap.log|logger -t user-data -s 2>/dev/console) 2>&1
set -e -x


if ! (grep "127.1.2.3 `hostname` `hostname | cut -d . -f 1`" /etc/hosts); then
    echo 127.1.2.3 `hostname` `hostname | cut -d . -f 1` | sudo tee -a /etc/hosts
fi

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

if [ -a /etc/apt/sources.list.d/opscode.list ]; then
    rm /etc/apt/sources.list.d/opscode.list
fi

if [ -a /etc/apt/trusted.gpg.d/opscode-keyring.gpg ]; then
    rm /etc/apt/trusted.gpg.d/opscode-keyring.gpg
    apt-get update
fi

### using only ubuntu and gems

# install ruby et all
apt-get -y install ruby ruby-dev libopenssl-ruby irb #rdoc ri 
apt-get -y install build-essential wget ssl-cert git git-core curl
# optional and not needed for chef-client or chef-solo
apt-get -y install libxslt1-dev libxml2-dev
# if chef-server runs on ssl, you need this
apt-get -y install libopenssl-ruby
# you need this to build native gems from source with gem_package
apt-get -y install ruby-dev build-essential
# we will preconfigure so we dont get asked questions:
#apt-get -y install debconf-utils

# This is system-wide, dont use rvm
if (which rvm) ; then rvm use system; fi

# no docs anywhere please
if ! (grep no-rdoc /etc/gemrc); then
echo gem: --no-ri --no-rdoc >> /etc/gemrc 
fi

# get rubygems from source
if ! [ -a /usr/bin/gem ]; then
pushd /tmp
wget -c http://production.cf.rubygems.org/rubygems/rubygems-1.7.2.tgz
tar zxf rubygems-1.7.2.tgz
cd rubygems-1.7.2
ruby setup.rb --no-format-executable
cd -
popd
fi

if ! [ -a /usr/bin/chef-solo ]; then
    gem install chef #--verbose #<%= '--prerelease' if @config[:prerelease] %> #no erb yet ;)
fi

#librarian-chef install

chef-solo -c .chef/chef-gem-bootstrap-solo.rb -l debug
rm -f .chef/chef-gem-bootstrap-solo.json

# remove any current devops user
if knife client list -u chef-webui -k /etc/chef/webui.pem | grep devops
then knife client delete devops -y -u chef-webui -k /etc/chef/webui.pem -n; fi

# and create a new one
knife client create devops -f .chef/devops.pem -u chef-webui -k /etc/chef/webui.pem --defaults --admin -n

cat << EOF | sudo debconf-set-selections
# New password for the 'admin' user in the Chef Server WebUI:
chef-server-webui chef-server-webui/admin_password password `pwgen -1 -A 6`
EOF

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
