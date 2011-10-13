# Author:: Chris McClimans <chris@idealinfrastructure.org>
# Cookbook Name:: pxe_knife
# Recipe:: default
#
# Copyright 2011, Ideal Infrastructure


pxe_root=node.pxe_knife.root

directory "#{pxe_root}" do
  mode "0755" 
end
directory "#{pxe_root}/pxelinux.cfg" do
  mode "0777" # FIXME: Security hole put here for test, remove me...TEST FIX
end

for pxe_file in %w{ help-rhel.txt help.txt memdisk menu.c32 pxelinux.0 vesamenu.c32 pxebootsplash-linuxbox.jpg pxebootsplash-help.jpg}
  cookbook_file "#{pxe_root}/#{pxe_file}" do
    source pxe_file
    mode "0444"
  end
end

for pxe_cfg in %w{ centos.menu graphics.conf imaging.menu mandriva.menu rhel.menu }
  cookbook_file "#{pxe_root}/pxelinux.cfg/#{pxe_cfg}" do
    source "pxelinux.cfg/#{pxe_cfg}"
    mode "0444"
  end
end

#images from
#http://www.panoramio.com/photo/45353125
# and
#http://spanz10.wordpress.com/2010/03/15/tauranga-the-mount/
template "#{pxe_root}/pxelinux.cfg/default" do
  source 'defaultmenu.erb'
  variables ({
      :default => :local
    })
  mode "0644" 
end
template "#{pxe_root}/pxelinux.cfg/default-winxp" do
  source 'defaultmenu.erb'
  variables ({
      :default => :windows
    })
  mode "0644" 
end
template "#{pxe_root}/pxelinux.cfg/default-ubuntu" do
  source 'defaultmenu.erb'
  variables ({
      :default => :ubuntu
    })
  mode "0644" 
end
template "#{pxe_root}/pxelinux.cfg/default-ubuntu64" do
  source 'defaultmenu.erb'
  variables ({
      :default => :ubuntu64
    })
  mode "0644" 
end
