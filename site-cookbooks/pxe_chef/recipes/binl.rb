# Author:: Chris McClimans <chris@idealinfrastructure.org>
# Cookbook Name:: pxe_knife
# Recipe:: default
#
# Copyright 2011, Ideal Infrastructure

cookbook_file '/etc/init.d/binl' do
  source 'binl/binl.init'
  mode '755'
end

cookbook_file '/usr/local/bin/binlsrv2.py' do
  source 'binl/binlsrv2.py'
  mode '755'
end

cookbook_file '/usr/local/bin/getbcdlocation.sh' do
  source 'binl/getbcdlocation.sh'
  mode '755'
end

execute 'touch /var/www/devlist.cache'

service 'binl' do
  action :start
end
