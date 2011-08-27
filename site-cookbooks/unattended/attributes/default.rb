#
# Author:: Matt Ray <matt@opscode.com>
# Cookbook Name:: pxe_dust
# Attributes:: default
#
# Copyright 2011 Opscode, Inc
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


default[:unattended][:iso][:torrents] = []
default[:unattended][:workgroup] = 'WORKGROUP'
default[:unattended][:domain] = ''
default[:unattended][:orgname] = 'PassionEngine'
default[:unattended][:adminpass] = 'passion'
default[:unattended][:fullname] = 'Chris McClimans'
default[:unattended][:top_scripts] = 'base.bat'
default[:unattended][:middle_scripts] = '7-zip.bat emacs.bat gimp.bat'
default[:unattended][:ntp_servers] = 'pool.ntp.org'
default[:unattended][:top_scripts] = 'base.bat'
default[:unattended][:media_base] = 'xpprosp3'
default[:unattended][:xp_pro_key] = 'AAAAA-BBBBB-CCCCC-DDDDD-EEEEE'
default[:unattended][:xp_home_key] = 'AAAAA-BBBBB-CCCCC-DDDDD-EEEEE'
default[:unattended][:partitions] = 'fdisk /clear 1;fdisk /pri:100,100;fdisk /delete /pri:1;fdisk /pri:4000;fdisk /activate:1'


# could be something like:
#[['xphomesp2',"http://torrents.mycompany.com/xphomesp2.torrent"],
#[ 'xpprosp3',"http://torrents.mycompany.com/xpprosp3.torrent"],
