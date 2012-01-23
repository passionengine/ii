# Author:: Chris McClimans <chris@idealinfrastructure.org>
# Cookbook Name:: pxe_knife
# Recipe:: default
#
# Copyright 2011, Ideal Infrastructure

require 'chef/file_cache'
cache_dir = "#{Chef::Config[:file_cache_path]}/pxe_chef/"
directory cache_dir

# 11.04 has libhivex-bin, maybe we should check for package first

# Download and install the wim file utilities


package 'pkg-config'
package 'libxml2-dev'



hivexver=node[:hivex][:version]

# Download and install the wim file utilities
hivextgz="#{cache_dir}/hivex-#{hivexver}.tgz"

remote_file hivextgz do
  source "http://libguestfs.org/download/hivex/hivex-#{hivexver}.tar.gz"
  checksum node[:hivex][:checksum]
  #notifies :run, "bash[install_hivex]", :immediately
end

bash "install_hivex" do
  user "root"
  cwd "/tmp"
  code <<-EOH
    tar -zxf #{hivextgz}
    (cd hivex-#{hivexver} && ./configure --prefix=/usr/local && make && make install)
  EOH
  not_if { File.exists? "/usr/local/bin/hivexget" }
  #action :nothing
end
