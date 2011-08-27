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

package 'dnsmasq'
service 'dnsmasq'

template "/etc/dnsmasq.d/dhcp-proxy.conf" do
  source "dhcp-proxy.conf.erb"
  #notifies :restart, "service[dnsmasq]" #FIXME: if I'm running  ubuntu sharing, it can't restart due to ports
end

remote_file "/var/www/ipxe.pxe" do
  source "http://boot.ipxe.org/ipxe.pxe"
  checksum '9c5aa99005711f8c9ad2e00ecb8e98ecc1400d6317821beb8359dabc3f179766'
  mode '0644'
end

execute "ln -s /var/www/ipxe.pxe /var/www/ipxe.pxe.0" do
  creates "/var/www/ipxe.pxe.0"
end
