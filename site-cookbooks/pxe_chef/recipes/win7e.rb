# Author:: Chris McClimans <chris@idealinfrastructure.org>
# Cookbook Name:: pxe_knife
# Recipe:: default
#
# Copyright 2011, Ideal Infrastructure

require 'chef/file_cache'
cache_dir = "#{Chef::Config[:file_cache_path]}/pxe_chef/"
directory cache_dir

pxe_root=node.pxe_knife.root

include_recipe 'pxe_chef::binl'
include_recipe 'pxe_chef::hivex'
include_recipe 'pxe_chef::wimlib'
include_recipe 'pxe_chef::win_support'



isofile='/var/www/iso/7600.16385.090713-1255_x64fre_enterprise_en-us_EVAL_Eval_Enterprise-GRMCENXEVAL_EN_DVD.iso'
tftproot='/var/www/'

pxe_chef_remote_file isofile do
  source "http://wb.dlservice.microsoft.com/dl/download/release/Win7/3/b/a/3bac7d87-8ad2-4b7a-87b3-def36aee35fa/7600.16385.090713-1255_x64fre_enterprise_en-us_EVAL_Eval_Enterprise-GRMCENXEVAL_EN_DVD.iso"
  checksum "24010879d98e90a989c420a503b07d9d784ef33fb3c67920c1979961d6cd7b57"
end


execute "7z x #{isofile} -so sources/boot.wim > #{tftproot}boot.wim" do
      not_if { File.exists? "#{tftproot}boot.wim" }
end

execute "7z x #{tftproot}boot.wim -so 1/Windows/Boot/DVD/PCAT/BCD > #{tftproot}wimbcd" do
  not_if { File.exists? "#{tftproot}wimbcd" }
end

['boot.sdi','bcd'].each do |isobootfile|
  execute "7z x #{isofile} -so boot/#{isobootfile} > #{tftproot}#{isobootfile}" do
    not_if { File.exists? "#{tftproot}#{isobootfile}" }
  end
end

['pxeboot.n12','wdsnbp.com','bootmgr.exe'].each do |wimbootfile|
  execute "7z x #{tftproot}boot.wim -so 1/Windows/Boot/PXE/#{wimbootfile} > #{tftproot}#{wimbootfile}" do
    not_if { File.exists? "#{tftproot}#{wimbootfile}" }
  end
end

directory "#{tftproot}Boot"
directory "#{tftproot}Boot/Fonts"
execute "7z x #{tftproot}boot.wim -so 1/Windows/Boot/Fonts/wgl4_boot.ttf > #{tftproot}Boot/Fonts/wgl4_boot.ttf" do
  not_if { File.exists? "#{tftproot}Boot/Fonts/wgl4_boot.ttf" }
end


directory "#{tftproot}boot"
directory "#{tftproot}/sources"
execute "cp #{tftproot}/bcd #{tftproot}/Boot/BCD" # in wrong place
execute "ln -f #{tftproot}/boot.sdi #{tftproot}/boot/boot.sdi" # in wrong place
execute "ln -f #{tftproot}/boot.wim #{tftproot}/sources/boot.wim" # in wrong place


directory "#{tftproot}system1"
execute "cp #{tftproot}/bcd #{tftproot}/system1/bcd"
execute "cp #{tftproot}/pxeboot.n12 #{tftproot}/system1/pxeboot.0"
execute "/vagrant/site-cookbooks/pxe_chef/files/default/bcdedit.pl #{tftproot}system1/bcd /boot.wim /boot.sdi INFO=10.42.43.1:system1"

