# Author:: Chris McClimans <chris@idealinfrastructure.org>
# Cookbook Name:: pxe_knife
# Recipe:: default
#
# Copyright 2011, Ideal Infrastructure

require 'chef/file_cache'
cache_dir = "#{Chef::Config[:file_cache_path]}/pxe_chef/"
directory cache_dir

wimlib_ver=node[:wimlib][:version]
wimlibtgz="#{cache_dir}/wimlib-#{wimlib_ver}.tgz"

remote_file wimlibtgz do
  source "http://www.ultimatedeployment.org/wimlib-#{wimlib_ver}.tgz"
  checksum node[:wimlib][:checksum]
end

bash "install_wimlib" do
  user "root"
  cwd "/tmp"
  code <<-EOH
    tar -zxf #{wimlibtgz}
    (cd wimlib-#{wimlib_ver}/src && make && cp -a updatewim wimextract wiminfo wimxmlinfo /usr/local/bin)
  EOH
  not_if { File.exists? "/usr/local/bin/updatewim" }
end


