# Author:: Chris McClimans <chris@idealinfrastructure.org>
# Cookbook Name:: pxe_knife
# Recipe:: default
#
# Copyright 2011, Ideal Infrastructure

require 'chef/file_cache'
cache_dir = "#{Chef::Config[:file_cache_path]}/pxe_chef/"
directory cache_dir

# install all needed software packages

# it's tofrodos on ubuntu 10.04
# it's dos2unix on 11.04

%w{ p7zip-full tofrodos }.each do |needed_package|
  package needed_package
end

