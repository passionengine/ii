#
# Cookbook Name:: unattended
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

require 'bencode' # for .bdecode on torrent
require 'chef/file_cache'
include_recipe 'dnsmasq'

version="4.9"
ua_mirror="http://surfnet.dl.sourceforge.net/project/unattended/unattended/#{version}/"
ua_dir="/var/unattended/"
ua_zip="unattended-#{version}.zip"
ua_dos_zip="unattended-#{version}-dosboot.zip"
ua_lin_zip="unattended-#{version}-linuxboot.zip"
cache_dir = "#{Chef::Config[:file_cache_path]}/unattended/"

directory cache_dir

[[ua_zip, 'e9b8e7a73ff3f95601f6ed30b92257b8a8da4692289f75be2ee5e3d7b23f18c4'],
# [ua_dos_zip, 'a473d4b070b2655ccbcaaba85b27930647fa24c0267f7c07d420a2d5f60bb15c'],
 [ua_lin_zip, '48606a60f1f08adda69d688f9a2133e1c5d1708e94a521f7bc87809086c359d8']
].each do |zipfile, sha256sum|
  execute "unzip -o #{zipfile}" do
    cwd cache_dir
    action :nothing
  end
  remote_file cache_dir + zipfile do
    source ua_mirror + zipfile
    checksum sha256sum
    notifies :run, "execute[unzip -o #{zipfile}]", :immediately
  end
end

[["linuxboot/tftpboot", "unattended-installer"]
# ["bootdisk/tftpboot",  "unattended-dos"]
].each do |pxe_src, pxe_dest|
  execute "rsync -a #{cache_dir}unattended-#{version}/#{pxe_src}/ #{node[:pxe_dust][:directory]}/#{pxe_dest}/" do
    creates "#{node[:pxe_dust][:directory]}/#{pxe_dest}"
  end
end

# directory "#{cache_dir}/initrd"

# execute 'extract initrd from source' do
#   command "cpio -id < #{cache_dir}unattended-#{version}/linuxboot/tftpboot/initrd"
#   cwd "#{cache_dir}/initrd"
#   creates "#{cache_dir}/initrd/etc/master"
# end

# template "#{cache_dir}/initrd/etc/master" do
#   source "initrd-master.erb"
#   mode '0755'
#   notifies :run, "execute[update unattended initrd]", :immediately
# end

# execute 'update unattended initrd' do
#   command "find ./ | cpio --create -H newc > #{node[:pxe_dust][:directory]}/unattended-installer/initrd"
#   cwd "#{cache_dir}/initrd"
#   action :nothing
# end

directory ua_dir

execute "rsync -a #{cache_dir}unattended-#{version}/install/ #{ua_dir}/install" do
  creates "#{ua_dir}/install"
end


include_recipe 'transmission'
directory "#{ua_dir}/iso"

tuser=node['transmission']['rpc_username']
tpass=node['transmission']['rpc_password']

node['unattended']['iso']['torrents'].each do |shortname,torrenturl|
  tf=transmission_torrent_file "#{ua_dir}/iso/#{shortname}.iso"  do
    torrent torrenturl
    continue_seeding true
    rpc_username tuser
    rpc_password tpass
    action :create
  end
  # this only excutes if we have a torrent_file (probably in cache)
  # but the resultant file doesn't exist
  # we poll transmission to get the actaul file and link to it
  # @transmission = Opscode::Transmission::Client.new("http://#{tuser}:#{tpass}@#{node['transmission']['rpc_host']}:#{node['transmission']['rpc_port']}/transmission/rpc")
  # @transmission. tf.torrent_hash
  # execute "#{[tf.class, tf.methods.inspect, tf.inspect]}" do
    
  #   creates tf.name
  # end
end

# mount all iso's dumped into /var/unattended/iso and copy contents
# to /var/unattended/install/os/ISONAME
# I think they need to be only 8 characters long

Dir['/var/unattended/iso/*.iso'].each do |isofile|
  filename=File.basename(isofile)
  shortname=filename.split('.')[0]
  bash "copy contents of #{filename} to #{ua_dir}/install/os/" do
    creates "#{ua_dir}/install/os/#{shortname}"
    code <<-EOH
      mkdir -p #{cache_dir}#{shortname}
      mount -o loop,nojoliet #{isofile} #{cache_dir}#{shortname}
      rsync -a #{cache_dir}#{shortname} #{ua_dir}/install/os/
      umount #{cache_dir}#{shortname}
    EOH
    # # put anything in this dir that you want on C:\
    #directory "#{ua_dir/install/os/#{shortname}/i386/$oem$/$1/"
  end
  #FIXME: This is not required, it had to do with .reboot-on being removed... the error 195 kept us from moving forward
  #package 'cabextract'
  #execute "cabextract -d . #{ua_dir}/install/os/#{shortname}/i386/framedyn.dl_" do
  #  cwd     "#{ua_dir}/install/bin"
  #  creates "#{ua_dir}/install/bin/framedyn.dll"
  #end
end


directory "#{cache_dir}drivers"
directory "#{cache_dir}torrents"

node['unattended']['driverpack']['torrents'].each do |dpt|
  #Driver Pack Torrent
  next if dpt.class == Array #Why am I seeing an array here? It's not in the atrributes!
  t_url = dpt[:url]
  t_file = dpt[:torrent_filename]
  t_sha256 = dpt[:sha256]
  driver_file = dpt[:content_filename]
  
  local_torrent_file = "#{cache_dir}torrents/#{t_file}"
  local_driver_file = "#{cache_dir}drivers/#{driver_file}"

  remote_file local_torrent_file do
    source t_url
    backup false
    mode "0755"
    checksum t_sha256 if t_sha256
  end

  transmission_torrent_file local_driver_file  do
    torrent local_torrent_file
    continue_seeding true
    rpc_username tuser
    rpc_password tpass
    action :create
  end
end


# this could be interesting.... but some of these websites don't have
# direct download urls.... Dell hosts on google with an authkey...
# node['unattended']['drivers']['zips'].each do |shortname,url|
#   # this only excutes if we have a torrent_file (probably in cache)
#   # but the resultant file doesn't exist
#   # we poll transmission to get the actaul file and link to it
#   # @transmission = Opscode::Transmission::Client.new("http://#{tuser}:#{tpass}@#{node['transmission']['rpc_host']}:#{node['transmission']['rpc_port']}/transmission/rpc")
#   # @transmission. tf.torrent_hash
#   # execute "#{[tf.class, tf.methods.inspect, tf.inspect]}" do
    
#   #   creates tf.name
#   # end
# end

Dir['/var/unattended/drivers/*.zip'].each do |driverzip|
  filename=File.basename(driverzip)
  shortname=filename.split('.')[0]
  bash "unzip contents of #{filename} to #{ua_dir}/install/drivers/" do
    creates "#{ua_dir}/install/drivers/#{shortname}"
    code <<-EOH
    unzip #{driverzip} -d #{ua_dir}/install/drivers/#{shortname}
    EOH
    # # put anything in this dir that you want on C:\
    #directory "#{ua_dir/install/os/#{shortname}/i386/$oem$/$1/"
  end
end



# this just updates scripts from svn.... 
# we won't do this
#execute "./script-update" do
#  cwd "#{ua_dir}/install/tools/"
#  #creates "#{ua_dir}/install/os/#{shortname}"
#end

# this downloads lots of software and drivers...
# we should replace it with remote_file resources that have md5 hashes
# execute "./prepare" do
#   cwd "#{ua_dir}/install/tools/"
#   #creates "#{ua_dir}/install/os/#{shortname}"
# end


user 'guest' do
  comment 'guest for unattended'
  supports :manage_home => true
  #home '/var/unattended'
  #shell u['shell'] #/bin/false?
end

include_recipe 'samba::server'

# not needed for linux boot
#execute "make images tftpboot ; cp -a images/*.imz tftpboot/unattended/" do
#  cwd '#{ua_dir}/unattended-#{version}/bootdisk/'


# 
# #maybe run this later... it's very bandwidth intensive
# ./script-update ; ./prepare # long download


# create new default!
#ln -s unattended-linux/* .

template "/var/unattended/install/site/config.pl" do
  source "site-config.pl.erb"
  mode '0644'
end

template "/var/unattended/install/site/unattend.csv" do
  source "unattend.csv.erb"
  mode '0644'
end

template "#{node[:pxe_dust][:directory]}/unattended-installer/pxelinux.cfg/default" do
  source "pxelinux-default.erb"
  mode '0644'
end

# need to be prepared better, check to see if reboot-on is enabled and do an execute-block
# Dir[dir + '/var/unattended/install/scripts/winxpsp3-*.bat'].each do |name|
#   File.open(name, 'r+') do |f|
#     new_file = f.read.gsub 'reboot-on', 'ignore-on'
#     f.truncate 0
#     f.write new_file
#   end
# end
#
# v3.17 isn't available for download.... it's now v3.22
# File.open("/var/unattended/install/scripts/winxpsp3-extras.bat", 'r+') do |f|
#   new_content = f.read.gsub 'v3.17.exe', 'v3.22.exe'
#   f.truncate 0
#   f.write new_content
# end
