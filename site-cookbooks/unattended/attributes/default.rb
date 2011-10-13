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


default[:unattended][:virtualbox][:additions_iso] = '/usr/share/virtualbox/VBoxGuestAdditions.iso'
default[:unattended][:iso][:torrents] = []
# could be something like:
#[['xphomesp2',"http://torrents.mycompany.com/xphomesp2.torrent"],
# ['xpprosp3',"http://torrents.mycompany.com/xpprosp3.torrent"] ]

default[:unattended][:workgroup] = 'WORKGROUP'
default[:unattended][:domain] = ''
default[:unattended][:orgname] = 'PassionEngine'
default[:unattended][:adminpass] = 'passion'
default[:unattended][:fullname] = 'Chris McClimans'

#default[:unattended][:top_scripts] = 'base.bat'
#Add vboxadd.bat here for virtualboxes
# default[:unattended][:top_scripts] = 'vboxbase.bat'
# vboxadds.bat
# VBoxWindowsAdditions-x86.exe /S
#   To extract the 32-bit drivers to "C:\Drivers", do the following:
#  VBoxWindowsAdditions-x86 /extract /D=C:\Drivers
#  For the 64-bit drivers:
#  VBoxWindowsAdditions-amd64 /extract /D=C:\Drivers
# Might be nice to just extract under wine!
# package wine1.3
#debconf-get-selections for msttcorefonts
#ttf-mscorefonts-installer	msttcorefonts/accepted-mscorefonts-eula	boolean	true
# TrueType core fonts for the Web EULA
#ttf-mscorefonts-installer	msttcorefonts/present-mscorefonts-eula	note	


#wine /mnt/foo/VBoxWindowsAdditions-x86.exe   /S /extract /D=C:\\tmp
#wine /mnt/foo/VBoxWindowsAdditions-amd64.exe /S /extract /D=C:\\tmp
# ~/.wine/drive_c/tmp/{x86|amd64}

# options
# /depth=BPP # Set the guests display color depth (bits per pixel)
# /extract   # Only extract installation files 
# /force     # Force installations on unknown/undetectect versions of windows versions
# /uninstall # Just uninstalls the Guest Additions and exits
# /with_autologon # Installs auto-logon support 
# /with_d3d # Installed Direct 3d support (requires SAFE MODE) 
# /xres=X # set's display width 
# /yres=Y # set's display height
# # params
# /l #log
# /S #Silent
# /D=<path> #intall dir 

#Order mandatory

# Install updates and shutdown?
# Slipstreaming via wine?




default[:unattended][:middle_scripts] = 'iimiddle.bat 7-zip.bat'# emacs.bat gimp.bat'
default[:unattended][:ntp_servers] = 'pool.ntp.org'
default[:unattended][:top_scripts] = 'iibase.bat'
default[:unattended][:media_base] = 'xpprosp3'
default[:unattended][:xp_pro_key] = 'AAAAA-BBBBB-CCCCC-DDDDD-EEEEE'
default[:unattended][:xp_home_key] = 'AAAAA-BBBBB-CCCCC-DDDDD-EEEEE'
default[:unattended][:partitions] = 'fdisk /clear 1;fdisk /pri:100,100;fdisk /delete /pri:1;fdisk /pri:4000;fdisk /activate:1'
default[:unattended][:driverpack][:torrents] = [
  {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/bluetooth/9.10/download/torrent",
  :sha256=>"1bc4d487fae0c0b963e8f5a98778fe5ebd07ce403d0b6bc48f748a8363e0caaf",
  :content_filename=>"DP_Bluetooth_wnt5_x86-32_910.7z",
  :torrent_filename=>"DP_Bluetooth_wnt5_x86-32_910.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/chipset/11.08/download/torrent",
  :sha256=>"fcbcd23b21b29b36db2e5e7899b40757a3b40a006e3f837c6e7678a6477dc432",
  :content_filename=>"DP_Chipset_wnt5_x86-32_1108.7z",
  :torrent_filename=>"DP_Chipset_wnt5_x86-32_1108.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/cpu/10.05/download/torrent",
  :sha256=>"413f840f3c86e406e8a0ef7015aa5dcbb616553f8c6fdccbad7a18f650a51316",
  :content_filename=>"DP_CPU_wnt5_x86-32_1005.7z",
  :torrent_filename=>"DP_CPU_wnt5_x86-32_1005.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/graphics-a/11.07/download/torrent",
  :sha256=>"1b5ae144a27cc1ee3e459a9e21cde4107cf3e570a612a309cf4e3d037c72114b",
  :content_filename=>"DP_Graphics_A_wnt5_x86-32_1107.7z",
  :torrent_filename=>"DP_Graphics_A_wnt5_x86-32_1107.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/graphics-b/11.07/download/torrent",
  :sha256=>"154affeeed34fd8793fd036612f7efc5a85ed75dffc9d74b069377c9d6423378",
  :content_filename=>"DP_Graphics_B_wnt5_x86-32_1107.7z",
  :torrent_filename=>"DP_Graphics_B_wnt5_x86-32_1107.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/graphics-c/11.07/download/torrent",
  :sha256=>"055e655361c3f9b449180c81b9ab9a2b86c3e598b3ff235d2c4ee63f5e6ed4ef",
  :content_filename=>"DP_Graphics_C_wnt5_x86-32_1107.7z",
  :torrent_filename=>"DP_Graphics_C_wnt5_x86-32_1107.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/graphics-languages/11.07/download/torrent",
  :sha256=>"18658255115d535c6fbecee1ab9d0ecb6e9250aba8de8ee36f8bcddf91602534",
  :content_filename=>"DP_Graphics_Languages_wnt5_x86-32_1107.7z",
  :torrent_filename=>"DP_Graphics_Languages_wnt5_x86-32_1107.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/graphics-physx/11.07/download/torrent",
  :sha256=>"1ba601b55ad4d6aeb11c82b448f7ade0180071d79f5b9ba4050a9ceca8ccc170",
  :content_filename=>"DP_Graphics_PhysX_wnt5_x86-32_1107.7z",
  :torrent_filename=>"DP_Graphics_PhysX_wnt5_x86-32_1107.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/hid/11.05/download/torrent",
  :sha256=>"fd128590930bebff76653aabd30d18100fb97e6a02a6f1a29db8a07c68a8c070",
  :content_filename=>"DP_HID_wnt5_x86-32_1105.7z",
  :torrent_filename=>"DP_HID_wnt5_x86-32_1105.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/lan/11.01/download/torrent",
  :sha256=>"522f1b6b217aaeec8eccf4508ebfdbbfd6a914e50ce51a3617470c2f13377e10",
  :content_filename=>"DP_LAN_wnt5_x86-32_1101.7z",
  :torrent_filename=>"DP_LAN_wnt5_x86-32_1101.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/lan-ris/10.11/download/torrent",
  :sha256=>"60093fb0393a747fc58be9c17555a3ea8e50068fbdaa57a021613327561584c4",
  :content_filename=>"DP_LAN-RIS_wnt5_x86-32_1011.7z",
  :torrent_filename=>"DP_LAN-RIS_wnt5_x86-32_1011.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/mass-storage/11.08/download/torrent",
  :sha256=>"c23f84577c47299e3ebb98898c22721a67ec9760f9bdd4aba382cdbc9efa0649",
  :content_filename=>"DP_MassStorage_wnt5_x86-32_1108.7z",
  :torrent_filename=>"DP_MassStorage_wnt5_x86-32_1108.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/miscellaneous/11.08/download/torrent",
  :sha256=>"271891cc4ab6fc6ee83f12b90892249fa041eb1c6d9aaddac1420600b2042107",
  :content_filename=>"DP_Misc_wnt5_x86-32_1108.7z",
  :torrent_filename=>"DP_Misc_wnt5_x86-32_1108.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/modem/11.01/download/torrent",
  :sha256=>"067013f217e7b8ea66e2c81a4cd92d0bbb011cde6245f51284f6549ac4682c68",
  :content_filename=>"DP_Modem_wnt5_x86-32_1101.7z",
  :torrent_filename=>"DP_Modem_wnt5_x86-32_1101.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/monitors/10.05/download/torrent",
  :sha256=>"8de280392aacc4edbb6aa1fc8b2eb216d134e90515b7a04f1b7c82b10bf3c14b",
  :content_filename=>"DP_Monitor_wnt5_x86-32_1005.7z",
  :torrent_filename=>"DP_Monitor_wnt5_x86-32_1005.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/runtimes-for-ati/11.07/download/torrent",
  :sha256=>"96bafb00f29c4fac037ea582885a7b24970edeb429eab298c2338cd538d7481c",
  :content_filename=>"DP_Runtimes_wnt5_x86-32_1107.7z",
  :torrent_filename=>"DP_Runtimes_wnt5_x86-32_1107.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/sound-a/11.08/download/torrent",
  :sha256=>"736030fda1c5e2ca779dc024d61f452210a0241a6b42609304b253ac5fe44f64",
  :content_filename=>"DP_Sound_A_wnt5_x86-32_1108.7z",
  :torrent_filename=>"DP_Sound_A_wnt5_x86-32_1108.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/sound-b/11.08/download/torrent",
  :sha256=>"11bf9e1840b1884f53fbfd02c46a88b5c763479aaeb5e7956aa6342f7eda1f86",
  :content_filename=>"DP_Sound_B_wnt5_x86-32_1108.7z",
  :torrent_filename=>"DP_Sound_B_wnt5_x86-32_1108.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/tvcard/10.05/download/torrent",
  :sha256=>"c0e43579a6385d3dd580f0e30de69dfdec2ea3efa8d183e88cf5003c6c4b678e",
  :content_filename=>"DP_TV_wnt5_x86-32_1005.7z",
  :torrent_filename=>"DP_TV_wnt5_x86-32_1005.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/webcam/11.07/download/torrent",
  :sha256=>"c52b0fc13789ebc0a8051e4814ac95c4665028e767151fd36c36dc9112910d07",
  :content_filename=>"DP_WebCam_wnt5_x86-32_1107.7z",
  :torrent_filename=>"DP_WebCam_wnt5_x86-32_1107.torrent"},
 {:url=>"http://driverpacks.net/driverpacks/windows/xp/x86/wlan/11.01/download/torrent",
  :sha256=>"21de5d9ddad2164d1e3935e61cc0b9bcf57239e0cf55473d28b7c1c8ca8e1c7d",
  :content_filename=>"DP_WLAN_wnt5_x86-32_1101.7z",
  :torrent_filename=>"DP_WLAN_wnt5_x86-32_1101.torrent"}]
