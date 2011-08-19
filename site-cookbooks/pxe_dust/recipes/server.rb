# Author:: Matt Ray <matt@opscode.com>
# Cookbook Name:: pxe_dust
# Recipe:: server
#
# Copyright 2011, Opscode, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "apache2"

package "squid-deb-proxy" # I'm choosing this for the proxy
#echo 'Acquire::http::Proxy "http://#{node[:ipaddress]}:8000";' > /etc/apt/conf.d/http_proxy

#include_recipe "tftp::server"

cache_dir = "#{Chef::Config[:file_cache_path]}/pxe_dust/"
directory cache_dir

remote_file "#{cache_dir}/netboot.tar.gz" do
  source "http://archive.ubuntu.com/ubuntu/dists/#{node[:pxe_dust][:version]}/main/installer-#{node[:pxe_dust][:arch]}/current/images/netboot/netboot.tar.gz"
  action :create_if_missing
end

execute "tar -xzf netboot.tar.gz -C #{node[:pxe_dust][:directory]}" do
  cwd cache_dir
  creates "#{node[:pxe_dust][:directory]}/ubuntu-installer"
end


#skips the prompt for which installer to use
template "#{node[:pxe_dust][:directory]}/pxelinux.cfg/default" do
  source "syslinux.cfg.erb"
  mode "0644"
  action :nothing
end

#sets the URL to the preseed
template "#{node[:pxe_dust][:directory]}/ubuntu-installer/#{node[:pxe_dust][:arch]}/boot-screens/(txt.cfg|text.cfg)"  do
  if node[:pxe_dust][:version] == 'lucid'
    path "#{node[:pxe_dust][:directory]}/ubuntu-installer/#{node[:pxe_dust][:arch]}/boot-screens/text.cfg"
  else
    path "#{node[:pxe_dust][:directory]}/ubuntu-installer/#{node[:pxe_dust][:arch]}/boot-screens/txt.cfg"
  end
  source "txt.cfg.erb"
  mode "0644"
  action :create
end

#search for any apt-cacher proxies
#servers = search(:node, 'recipes:apt\:\:cacher') || []
servers = [] #no searches on chef-solo
if servers.length > 0
  proxy = "d-i mirror/http/proxy string http://#{servers[0].ipaddress}:3142"
else
  proxy = "#d-i mirror/http/proxy string url"
end
# apt-cacher doesn't seem to function as an http proxy
### FIXME: figureing out the server's actual ip!
#proxy = "d-i mirror/http/proxy string http://#{node[:ipaddress]}:8000" #our role includes apt::cacher
proxy = "d-i mirror/http/proxy string http://10.42.43.1:8000" #our role includes apt::cacher
#proxy = "d-i mirror/http/proxy string http://10.42.43.1:3142" #our role includes apt::cacher

template "/var/www/preseed.cfg" do
  source "preseed.cfg.erb"
  mode "0644"
  variables({
              :proxy => proxy
            })
  action :create
end

# just until we dynamically generate all the configs!!
execute "ln -s /var/www/ubuntu-installer /var/www/ubuntu-installer/amd64/ubuntu-installer" do
  creates "/var/www/ubuntu-installer/amd64/ubuntu-installer"
end
