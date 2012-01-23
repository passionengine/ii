#
# Author:: Chris McClimans <chris@idealinfrastructure.org>
# Cookbook Name:: pxe_knife
# Attributes:: default
#
# Copyright 2011 Ideal Infrastructure

default[:pxe_knife][:root] = "/var/www"

# earlier versions have trouble building https://www.redhat.com/archives/libguestfs/2011-November/msg00232.html
default[:hivex][:version] = "1.2.5"
default[:hivex][:checksum] = "f6a984a139df3a433d7eb9ebc55c56cea792848322e81560e94f66751c50e4da"

default[:wimlib][:version] = "0.2"
default[:wimlib][:checksum] = "3cf8c732eb306f6cda0519158ae27fbf288cff29e0934bcd0365f3d0c346b929"

