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
end



package 'p7zip'
directory "#{cache_dir}drivers"
directory "#{cache_dir}torrents"

node['unattended']['driverpack']['torrents'].each do |dpt|
  #Driver Pack Torrent
  t_url = dpt[:url]
  t_file = dpt[:torrent_filename]
  t_sha256 = dpt[:sha256]
  driver_file = dpt[:content_filename]
  
  local_torrent_file = "#{cache_dir}torrents/#{t_file}"
  local_driver_file = "#{cache_dir}drivers/#{driver_file}"

  remote_file "#{t_file} from #{t_url}" do
    path local_torrent_file
    source t_url
    backup false
    mode "0755"
    checksum t_sha256 if t_sha256
    not_if { File.exists? local_torrent_file }
  end

  transmission_torrent_file local_driver_file  do
    torrent local_torrent_file
    continue_seeding true
    rpc_username tuser
    rpc_password tpass
    action :create
  end
  
  # I don't know the contents of these 7zip files, but I can track if I've decompressed them
  execute "7zr x -y #{local_driver_file} && touch #{local_driver_file}.decompressed" do
    cwd     "#{ua_dir}/install/drivers"
    creates "#{local_driver_file}.decompressed" 
  end
end

# Might be interesting to slipstream this into the first boot...
remote_file "#{cache_dir}/ruby-1.8.7-p352-i386-mingw32.7z" do
  source "http://rubyforge.org/frs/download.php/75108/ruby-1.8.7-p352-i386-mingw32.7z"
  checksum "f5b21458b5d28bbffc634692ff53cf0ebe81ac9f6699d95fa6de25f46f90a37b"
  backup false
  mode "0755"
  not_if { File.exists? "#{cache_dir}/ruby-1.8.7-p352-i386-mingw32.7z" }
end

directory "#{ua_dir}install/packages/ruby"
ruby_installer="#{ua_dir}install/packages/ruby/rubyinstaller-1.8.7-p352.exe"
remote_file ruby_installer do
  source "http://rubyforge.org/frs/download.php/75107/rubyinstaller-1.8.7-p352.exe"
  checksum "4720388633ff4f0661032db7b7c00fbc701d2be733e273600431d1cb02c85700"
  backup false
  mode "0755"
  not_if { File.exists? ruby_installer }
end




directory "#{ua_dir}install/packages/virtualbox"
virtualbox_installer="#{ua_dir}install/packages/virtualbox/VirtualBox-4.1.2-73507-Win.exe"
remote_file virtualbox_installer do
  source "http://download.virtualbox.org/virtualbox/4.1.2/VirtualBox-4.1.2-73507-Win.exe"
  checksum "dc0987219692f2d9fee90ab06ce2d2413fb620e5a00733628935be974d42c11d"
  backup false
  mode "0755"
  not_if { File.exists? virtualbox_installer }
end

virtualbox_extpack="#{ua_dir}install/packages/virtualbox/Oracle_VM_VirtualBox_Extension_Pack-4.1.2-73507.vbox-extpack"
remote_file virtualbox_extpack do
  source "http://download.virtualbox.org/virtualbox/4.1.2/Oracle_VM_VirtualBox_Extension_Pack-4.1.2-73507.vbox-extpack"
  checksum "3bc5ad8d7082b6debeec24c40a86629bf0ad6313343532d0ad0fee4131e8f9fc"
  backup false
  mode "0755"
  not_if { File.exists? virtualbox_extpack }
end


directory "#{ua_dir}install/packages/python"
python_installer="#{ua_dir}install/packages/python/python-2.7.2.msi"
remote_file python_installer do
  mode "0755"
  backup false
  not_if { File.exists? python_installer }
  source "http://www.python.org/ftp/python/2.7.2/python-2.7.2.msi"
  checksum "b99c20bece1fe4ac05844aea586f268e247107cd0f8b29593172764c178a6ebe"
end




# virtualbox-additions
vboxadd_iso_path=node['unattended']['virtualbox']['additions_iso']
package 'virtualbox-guest-additions' do 
  # I think we need 4.1 as well, need to check
  not_if { File.exists? vboxadd_iso_path }
end

mountdir="#{cache_dir}/driveriso"
local_driver_dir = "#{ua_dir}/install/drivers"
bash "copy contents of #{vboxadd_iso_path} to #{local_driver_dir}" do
  creates "#{local_driver_dir}/VBoxWindowsAdditions-amd64.exe" #and "#{local_driver_dir}/VBoxWindowsAdditions-x86.exe"
  code <<-EOH
      mkdir -p #{mountdir}
      mount -o loop,nojoliet #{vboxadd_iso_path} #{mountdir}
      cp #{mountdir}/VBoxWindowsAdditions-amd64.exe #{local_driver_dir}
      cp #{mountdir}/VBoxWindowsAdditions-x86.exe #{local_driver_dir}
      umount #{mountdir}
  EOH
end


package 'wine1.3' do
  response_file 'wine.seed' #windows font eula... maybe we should alert user
end

winehome=File.join(cache_dir,'winehome')
directory winehome


# might be nicer to have wine dump it to somewhere within the cache or target dir
execute "wine #{local_driver_dir}/VBoxWindowsAdditions-x86.exe /S /extract /D=C:\\\\tmp" do
  cwd winehome
  environment ({'HOME'=>winehome})
  creates "#{winehome}/.wine/drive_c/tmp/x86"
end
execute "wine #{local_driver_dir}/VBoxWindowsAdditions-amd64.exe /S /extract /D=C:\\\\tmp" do
  cwd winehome
  environment ({'HOME'=>winehome})
  creates "#{winehome}/.wine/drive_c/tmp/amd64"
end

execute "cp -a #{winehome}/.wine/drive_c/tmp/amd64 #{local_driver_dir}/VBoxWindowsAdditions-amd64" do
  creates "#{local_driver_dir}/VBoxWindowsAdditions-amd64"
end
execute "cp -a #{winehome}/.wine/drive_c/tmp/x86 #{local_driver_dir}/VBoxWindowsAdditions-x86" do
  creates "#{local_driver_dir}/VBoxWindowsAdditions-x86"
end

execute "wine #{virtualbox_installer} -x -s -l -p C:\\\\vbox" do
  cwd winehome
  environment ({'HOME'=>winehome})
  creates "#{winehome}/.wine/drive_c/vbox/common.cab"
end

execute "cp -a #{winehome}/.wine/drive_c/vbox/* #{ua_dir}install/packages/virtualbox/" do
  creates "#{ua_dir}install/packages/virtualbox/common.cab"
end


template "/var/unattended/install/scripts/vboxadd.bat" do
  source "virtualbox.bat.erb"
  mode '0644'
end

template "/var/unattended/install/scripts/vboxbase.bat" do
  source "vboxbase.bat.erb"
  mode '0644'
end

#~/.wine/drive_c/tmp/{x86|amd64}

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

execute "#{ua_dir}/install/dosbin/search-win-drivers.pl -g -d . > search-win-drivers.cache" do
  cwd     "#{ua_dir}/install/drivers"
  creates "#{ua_dir}/install/drivers/search-win-drivers.cache"
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

vboxes = search("virtualboxen", "*:*")
template "/var/unattended/install/site/unattend.csv" do
  source "unattend.csv.erb"
  mode '0644'
  variables(
    :virtualboxen => vboxes
  )
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
