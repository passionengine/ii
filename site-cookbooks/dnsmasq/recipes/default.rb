#
# Cookbook Name:: dnsmasq
# Recipe:: default
#
# Copyright 2011, HippieHacker.org
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

require 'chef/file_cache'
cache_dir = "#{Chef::Config[:file_cache_path]}/dnsmasq/"
directory cache_dir

package 'dnsmasq'
service 'dnsmasq'

template "/etc/dnsmasq.d/ii.conf" do
  source "ii.conf.erb"
  mode "0644"
  #notifies :restart, "service[dnsmasq]" #FIXME: if I'm running  ubuntu sharing, it can't restart due to ports
end

# I'm in favor of using some type of new thing called...
# remote_file_from_cache
ipxe_cache = cache_dir + 'ipxe.pxe'
ipxe_exe="/var/www/ipxe.exe"
remote_file ipxe_cache do
  source "http://boot.ipxe.org/ipxe.pxe"
  checksum '9c5aa99005711f8c9ad2e00ecb8e98ecc1400d6317821beb8359dabc3f179766'
  mode '0644'
  not_if { File.exists? ipxe_cache }
  #notifies :run, "execute[unzip -o #{zipfile}]", :immediately
end

execute "cp -a #{ipxe_cache} #{ipxe_exe}" do
  creates ipxe_exe
end


execute "ln -sf /var/www/ipxe.pxe /var/www/ipxe.pxe.0" do
  creates "/var/www/ipxe.pxe.0"
end
