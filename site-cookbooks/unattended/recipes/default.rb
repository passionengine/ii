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

#require 'bencode' # for .bdecode on torrent
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

# chef if exists first?
[[ua_zip, 'e9b8e7a73ff3f95601f6ed30b92257b8a8da4692289f75be2ee5e3d7b23f18c4', 'unattended-4.9/README.txt'],
# [ua_dos_zip, 'a473d4b070b2655ccbcaaba85b27930647fa24c0267f7c07d420a2d5f60bb15c'],
 [ua_lin_zip, '48606a60f1f08adda69d688f9a2133e1c5d1708e94a521f7bc87809086c359d8', 'unattended-4.9/linuxboot/tftpboot/pxelinux.0']
].each do |zipfile, sha256sum, content|
  remote_file cache_dir + zipfile do
    source ua_mirror + zipfile
    checksum sha256sum
    not_if { File.exists? cache_dir + zipfile }
    #notifies :run, "execute[unzip -o #{zipfile}]", :immediately
  end
  execute "unzip -o #{zipfile}" do
    cwd cache_dir
    umask "022"
    creates "#{cache_dir}/#{content}"
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
directory "#{cache_dir}/iso"
directory "#{ua_dir}/iso"

tuser=node['transmission']['rpc_username']
tpass=node['transmission']['rpc_password']

node['unattended']['iso']['torrents'].each do |shortname,torrenturl|
  # fix this to only download torrent if we don't already have the ISO
  # maybe just an 'unless ?'
  tf=transmission_torrent_file "#{cache_dir}/iso/#{shortname}.iso"  do
    torrent torrenturl
    continue_seeding true
    rpc_username tuser
    rpc_password tpass
    action :create
    not_if { File.exists? "#{cache_dir}/iso/#{shortname}.iso" }
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

# mount all iso's dumped into #{cache_dir}/iso and copy contents
# to /var/unattended/install/os/ISONAME
# I think they need to be only 8 characters long

Dir['#{cache_dir}/iso/*.iso'].each do |isofile|
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
    #directory "#{ua_dir}/install/os/#{shortname}/i386/$oem$/$1/"
  end
end



package 'p7zip'
package 'unzip'
directory "#{cache_dir}drivers"
directory "#{cache_dir}torrents"

node['unattended']['driverpack']['torrents'].each do |dpt|
  #Driver Pack Torrent
  t_url = dpt[:url]
  t_file = dpt[:torrent_filename]
  t_sha256 = dpt[:sha256]
  driver_file = dpt[:content_filename]
  
  local_torrent_file = "#{cache_dir}torrents/#{t_file}" #.torrent
  torrent_download = "#{cache_dir}torrents/#{driver_file}" #symlink to transmission
  local_driver_file = "#{cache_dir}drivers/#{driver_file}" #local cached copy

  remote_file "#{t_file} from #{t_url}" do
    path local_torrent_file
    source t_url
    backup false
    mode "0755"
    checksum t_sha256 if t_sha256
    not_if { File.exists? local_torrent_file }
  end

  transmission_torrent_file torrent_download  do
    torrent local_torrent_file
    continue_seeding true
    rpc_username tuser
    rpc_password tpass
    action :create
    not_if { File.exists? "#{local_driver_file}" }
  end
  
  execute "cp -a #{torrent_download} #{local_driver_file}" do
    creates "#{local_driver_file}"
  end
  # I don't know the contents of these 7zip files, but I can track if I've decompressed them
  # the .demcompressed file being in the shared cache isn't going to work..
  # must use something in target ua_dir
  execute "7zr x -y #{local_driver_file} && touch #{ua_dir}/install/drivers/#{driver_file}.decompressed" do
    cwd     "#{ua_dir}/install/drivers"
    creates "#{ua_dir}/install/drivers/#{driver_file}.decompressed"
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

#http://msysgit.googlecode.com/files/Git-1.7.6-preview20110708.exe

ruby_installer_cache="#{cache_dir}/rubyinstaller-1.8.7-p352.exe"
remote_file ruby_installer_cache do
  source "http://rubyforge.org/frs/download.php/75107/rubyinstaller-1.8.7-p352.exe"
  checksum "4720388633ff4f0661032db7b7c00fbc701d2be733e273600431d1cb02c85700"
  backup false
  mode "0755"
  not_if { File.exists? ruby_installer_cache }
end
directory "#{ua_dir}install/packages/ruby"
ruby_installer="#{ua_dir}install/packages/ruby/rubyinstaller-1.8.7-p352.exe"
execute "cp -a #{ruby_installer_cache} #{ruby_installer}" do
  creates "#{ruby_installer}"
end

rubydev_installer_cache="#{cache_dir}/DevKit-tdm-32-4.5.2-20110712-1620-sfx.exe"
remote_file rubydev_installer_cache do
  source "http://github.com/downloads/oneclick/rubyinstaller/DevKit-tdm-32-4.5.2-20110712-1620-sfx.exe"
  checksum "6230d9e552e69823b83d6f81a5dadc06958d7a17e10c3f8e525fcc61b300b2ef"
  backup false
  mode "0755"
  not_if { File.exists? rubydev_installer_cache }
end
rubydev_installer="#{ua_dir}install/packages/ruby/DevKit-tdm-32-4.5.2-20110712-1620-sfx.exe"
execute "cp -a #{rubydev_installer_cache} #{rubydev_installer}" do
  creates "#{rubydev_installer}"
end


devdir = "#{ua_dir}/install/packages/ruby/dev"
directory devdir
# 7zr creats directories that have a mode of 700, and are unreadable... 
# even though I set the umask... frustrating... so I add the find
execute "7zr x -y #{rubydev_installer}; find . -type d -exec chmod go+rx \\\{\\\} \\\;" do
  cwd     devdir
  creates "#{devdir}/bin/true.exe" 
  umask "022"
end



wmf_installer_cache="#{cache_dir}WindowsXP-KB968930-x86-ENG.exe"
remote_file wmf_installer_cache do
  source "http://download.microsoft.com/download/E/C/E/ECE99583-2003-455D-B681-68DB610B44A4/WindowsXP-KB968930-x86-ENG.exe"
  checksum "0ef2a9b4f500b66f418660e54e18f5f525ed8d0a4d7c50ce01c5d1d39767c00c"
  backup false
  mode "0755"
  not_if { File.exists? wmf_installer_cache }
end
wmf_installer="#{ua_dir}install/packages/ruby/WindowsXP-KB968930-x86-ENG.exe"
execute "cp -a #{wmf_installer_cache} #{wmf_installer}" do
  creates "#{wmf_installer}"
end



directory "#{ua_dir}install/packages/virtualbox"
virtualbox_installer_cache="#{cache_dir}/VirtualBox-4.1.2-73507-Win.exe"
remote_file virtualbox_installer_cache do
  source "http://download.virtualbox.org/virtualbox/4.1.2/VirtualBox-4.1.2-73507-Win.exe"
  checksum "dc0987219692f2d9fee90ab06ce2d2413fb620e5a00733628935be974d42c11d"
  backup false
  mode "0755"
  not_if { File.exists? virtualbox_installer_cache }
end
virtualbox_installer="#{ua_dir}install/packages/virtualbox/VirtualBox-4.1.2-73507-Win.exe"
execute "cp -a #{virtualbox_installer_cache} #{virtualbox_installer}" do
  creates "#{virtualbox_installer}"
end

virtualbox_extpack_cache="#{cache_dir}/Oracle_VM_VirtualBox_Extension_Pack-4.1.2-73507.vbox-extpack"
remote_file virtualbox_extpack_cache do
  source "http://download.virtualbox.org/virtualbox/4.1.2/Oracle_VM_VirtualBox_Extension_Pack-4.1.2-73507.vbox-extpack"
  checksum "3bc5ad8d7082b6debeec24c40a86629bf0ad6313343532d0ad0fee4131e8f9fc"
  backup false
  mode "0755"
  not_if { File.exists? virtualbox_extpack_cache }
end
virtualbox_extpack="#{ua_dir}install/packages/virtualbox/Oracle_VM_VirtualBox_Extension_Pack-4.1.2-73507.vbox-extpack"
execute "cp -a #{virtualbox_extpack_cache} #{virtualbox_extpack}" do
  creates "#{virtualbox_extpack}"
end

directory "#{ua_dir}install/packages/python"
python_installer_cache="#{cache_dir}/python-2.7.2.msi"
remote_file python_installer_cache do
  mode "0755"
  backup false
  not_if { File.exists? python_installer_cache }
  source "http://www.python.org/ftp/python/2.7.2/python-2.7.2.msi"
  checksum "b99c20bece1fe4ac05844aea586f268e247107cd0f8b29593172764c178a6ebe"
end
python_installer="#{ua_dir}install/packages/python/python-2.7.2.msi"
execute "cp -a #{python_installer_cache} #{python_installer}" do
  creates "#{python_installer}"
end

pik_installer_cache="#{cache_dir}/pik-0.3.0.pre.msi"
remote_file pik_installer_cache do
  mode "0755"
  backup false
  not_if { File.exists? pik_installer_cache }
  source "https://github.com/downloads/vertiginous/pik/pik-0.3.0.pre.msi"
  checksum "16d7c0c5bfa30f36ded41e8cfb7691024273aca5a77654257a44ba3e29d4534a"
end
pik_installer="#{ua_dir}install/packages/ruby/pik-0.3.0.pre.msi"
execute "cp -a #{pik_installer_cache} #{pik_installer}" do
  creates "#{pik_installer}"
end


directory "#{ua_dir}install/packages/microsoft"
dotnetsp1_installer_cache="#{cache_dir}/NetFx20SP1_x86.exe"
remote_file dotnetsp1_installer_cache do
  mode "0755"
  backup false
  not_if { File.exists? dotnetsp1_installer_cache }
  source "http://download.microsoft.com/download/0/8/c/08c19fa4-4c4f-4ffb-9d6c-150906578c9e/NetFx20SP1_x86.exe"
  checksum "c36c3a1d074de32d53f371c665243196a7608652a2fc6be9520312d5ce560871"
end
dotnetsp1_installer="#{ua_dir}install/packages/microsoft/NetFx20SP1_x86.exe"
execute "cp -a #{dotnetsp1_installer_cache} #{dotnetsp1_installer}" do
  creates "#{dotnetsp1_installer}"
end

dotnet_installer="#{ua_dir}install/packages/microsoft/dotnetfx.exe"
dotnet_installer_cache="#{cache_dir}/dotnetfx.exe"
# :: dotnetfx.exe /?
# :: /Q -- Quiet modes for packgage.
# :: /T:<full path> -- Specifies temporary working folder,
# :: /C -- Extract files only to the folder when also used with /T
# :: /C:<cmd> -- Override Install Command defined by author

# todo.pl ".ignore-err 3010 %Z%\packages/microsoft/dotnet.exe /C /T:C:\dotnet"
remote_file dotnet_installer_cache do
  mode "0755"
  backup false
  not_if { File.exists? dotnet_installer_cache }
  source "http://download.microsoft.com/download/5/6/7/567758a3-759e-473e-bf8f-52154438565a/dotnetfx.exe"
  checksum "46693d9b74d12454d117cc61ff2e9481cabb100b4d74eb5367d3cf88b89a0e71"
end
execute "cp -a #{dotnet_installer_cache} #{dotnet_installer}" do
  creates "#{dotnet_installer}"
end

dotnet35_installer="#{ua_dir}install/updates/common/dotnetfx35-sp1.exe"
dotnet35_installer_cache="#{cache_dir}/dotnetfx35-sp1.exe"

# :: dotnetfx.exe /?
# :: /Q -- Quiet modes for packgage.
# :: /T:<full path> -- Specifies temporary working folder,
# :: /C -- Extract files only to the folder when also used with /T
# :: /C:<cmd> -- Override Install Command defined by author

# todo.pl ".ignore-err 3010 %Z%\packages/microsoft/dotnet.exe /C /T:C:\dotnet"
remote_file dotnet35_installer_cache do
  mode "0755"
  backup false
  not_if { File.exists? dotnet35_installer_cache }
  source "http://download.microsoft.com/download/2/0/e/20e90413-712f-438c-988e-fdaa79a8ac3d/dotnetfx35.exe"
  #checksum "46693d9b74d12454d117cc61ff2e9481cabb100b4d74eb5367d3cf88b89a0e71"
end
execute "cp -a #{dotnet35_installer_cache} #{dotnet35_installer}" do
  creates "#{dotnet35_installer}"
end

dotnet4_installer="#{ua_dir}install/updates/common/dotNetFx40_Full_x86_x64.exe"
dotnet4_installer_cache="#{cache_dir}/dotNetFx40_Full_x86_x64.exe"
# dotNetFx40_Full_x86_x64.exe /?
# /CIEPconsent - Optionally send anonymous feedback to improve the customer experience
# /chainingpackage <name> - Optionally record the name of a package chaining this one
# /createlayout <full path> - Download all files and associated resources to the specified location. Perform no other action *Disabled*
# /lcid - Set the display language to be used by this program, if possible. example: /lcid 1031
# /log <file | folder> - Location of the log fil. Default is the process temporary folder with a name based on the package
# /msioptions - Specify options to be passed for .msi and msp items. Example: /msioptins: "PROPERTY1='Value'"
# /norestart - If the operation requires a reboot to complete, Setup should neither prompt nor cause a reboot
# /passive - Shows progress bar advancing but requires no user interaction
# /showfinalerror - Passive mode only: shows final page if the install is not successful
# /pipe <name> - Optionally create a communication channel to allow a chaining package to get progress
# /promptrestart - If the operation requires a reboot to complete, Setup should prompt, and trigger it if the user agrees
# /q - Quiet mode, no user input required or output shown.
# /repair - Repair the payloads
# /serialdownload - Force install operation to happen only after all the payload is downloaded
# /uninstall - Uninstall the payloads
# /parameterfolder <full path> - Specifies the path to the Setup's configuration and data files
# /NoSetupVersionCheck - Do net check ParameterInfo.xml for setup version conflicts
# /uninstallpatch {patch code} - Removes the update for all products the patch has been applied to
# ex:
# Silently install the package and create log file SP123.htm in the temp folder:
# Setup.exe /q /log %temp%\SP123.htm
# Install with no user interaction unless a reboot is needed to complete the operation:
# Setup /passive /promptrestart
#
# Some command line switches are disabled for this package: createlayout

# todo.pl ".ignore-err 3010 %Z%\packages/microsoft/dotnet.exe /C /T:C:\dotnet"
remote_file dotnet4_installer_cache do
  mode "0755"
  backup false
  not_if { File.exists? dotnet4_installer_cache }
  source "http://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe"
  checksum "65e064258f2e418816b304f646ff9e87af101e4c9552ab064bb74d281c38659f"
end
execute "cp -a #{dotnet4_installer_cache} #{dotnet4_installer}" do
  creates "#{dotnet4_installer}"
end

# http://www.cygwin.com/install.html
# http://www.cygwin.com/setup.exe
# http://www.cygwin.com/key/pubring.asc
# http://www.cygwin.com/setup.exe.sig
cygwin_targetdir = "#{ua_dir}install/cygwin/"
directory cygwin_targetdir
cygwin_exe="#{cygwin_targetdir}setup.exe"
cygwin_exe_cache="#{cache_dir}/cygwin_setup.exe"
remote_file cygwin_exe_cache do
  mode "0755"
  backup false
  not_if { File.exists? cygwin_exe_cache }
  source "http://www.cygwin.com/setup.exe"
  #checksum "a8898d37f8b0d3b534128abe4f086d7cb7c76c7918df28c015c3f47f9be69880"
end
execute "cp -a #{cygwin_exe_cache} #{cygwin_exe}" do
  creates "#{cygwin_exe}"
end

# Z:\cygwin\setup.exe -q --local-install --root c:\cygwin -l f:\cygwin
# within-cygwin
# ssh-host-config --yes --cygwin "ntsec tty"
# net start sshd

# http://technet.microsoft.com/en-us/sysinternals/bb896645.aspx
procmon_exe="#{ua_dir}install/updates/common/Procmon.exe"
procmon_exe_cache="#{cache_dir}/Procmon.exe"
remote_file procmon_exe_cache do
  mode "0755"
  backup false
  not_if { File.exists? procmon_exe_cache }
  source "http://live.sysinternals.com/Procmon.exe"
  checksum "a8898d37f8b0d3b534128abe4f086d7cb7c76c7918df28c015c3f47f9be69880"
end
execute "cp -a #{procmon_exe_cache} #{procmon_exe}" do
  creates "#{procmon_exe}"
end



# Better to pull these down from the web I think FIXME!
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



# Will wine need X?
# Wine does lots of downloading as it is installed... fonts etc
# would be interesting to see how to cache it completely for no network access
#package 'wine1.3' do # as wine1.3 isn't available on 10.04 etc
package 'wine' do
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

execute "wine #{dotnet_installer} /C /T:C:\\\\dotnet" do
  cwd winehome
  environment ({'HOME'=>winehome})
  creates "#{winehome}/.wine/drive_c/dotnet/install.exe"
end

directory "#{ua_dir}install/packages/microsoft/dotnet"
execute "cp -a #{winehome}/.wine/drive_c/dotnet/* #{ua_dir}install/packages/microsoft/dotnet" do
  creates "#{ua_dir}install/packages/microsoft/dotnet/install.exe"
end


template "/var/unattended/install/scripts/vboxadd.bat" do
  source "virtualbox.bat.erb"
  mode '0644'
end

template "/var/unattended/install/scripts/vboxbase.bat" do
  source "vboxbase.bat.erb"
  mode '0644'
end

template "/var/unattended/install/scripts/iibase.bat" do
  source "iibase.bat.erb"
  mode '0644'
end

template "/var/unattended/install/scripts/iimiddle.bat" do
  source "iimiddle.bat.erb"
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


##DMI
dmi_zip="#{cache_dir}/dmidecode-2.9.zip"
remote_file dmi_zip do
  checksum "af408e584c4a882d9aa704e6c767b0f86dbab05901c086173f3475090725d2c5"
  source "http://wpkg.org/files/3rd_party/dmidecode-2.9.zip"
  not_if { File.exists? dmi_zip }
  backup false
  mode "0755"
end

execute "unzip -o #{dmi_zip}" do
  cwd "#{ua_dir}/install/drivers/"
  creates "#{ua_dir}/install/drivers/dmidecode-2.9/dmidecode.exe"
  umask "022"
end



# This is where XP Drivers from Dell and Big vendors might be useful...
Dir['/var/unattended/drivers/*.zip'].each do |driverzip|
  filename=File.basename(driverzip)
  shortname=filename.split('.')[0]
  bash "unzip contents of #{filename} to #{ua_dir}/install/drivers/" do
    creates "#{ua_dir}/install/drivers/#{shortname}"
    code <<-EOH
    unzip #{driverzip} -d #{ua_dir}/install/drivers/#{shortname}
    EOH
    umask "022"
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

if Chef::Config[:solo]
  vboxes = [] # no searches in chef-solo
else 
  vboxes = search("virtualboxen", "*:*")
end

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
