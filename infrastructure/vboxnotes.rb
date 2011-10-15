# this will boot from network only if we can't boot from disk
vbox.boot_order=[:hard_disk ,:network,:null,:null]
# Other options:
# :hard_disk, :usb, :dvd, :null

nic = vbox.network_adapters[0]
# our attachment_type has a huge impact on which pxe implementation we have
# since we don't seem to have much control over the DHCP server,

# :nat forces us to use a TFTP directory under the
# directory containing the VirtualBox.xml file
nic.attachment_type = :nat
# replace 'pcnet' with 'e1000' for the Intel nic
vbox.extra_data['VBoxInternal/Devices/pcnet/0/LUN#0/Config/BootFile']='pxelinux.0'
vbox.extra_data['VBoxInternal/Devices/pcnet/0/LUN#0/Config/TFTPPrefix']='/var/www'

  machine.bios_settings.logo_fade_in = true
  machine.bios_settings.logo_fade_out = true
  machine.bios_settings.logo_display_time=3000 #3 seconds in ms

# YES
# vbox.control 'power_down'
# vbox.stop # :power_down
# vbox.shutdown # :power_button
# vbox.pause
# vbox.resume
# vbox.save_state
# vbox.discard_state
# vbox.destroy :destroy_medium
# vbox.starting? running? poweroff? paused? saved? aborted?
# vbox.take_snapshot('foo1', 'fantastic snap') # can take a block
# vbox.export 'filex'
# vbox.import 'filey'
# vbox.state

#          function :create_shared_folder, nil, [WSTRING, WSTRING, T_BOOL, T_BOOL]

#you get this on connect:
# got event: 62 OnEventSourceChanged
#you get this on boot... and possibly other times
# got event: 47 OnAdditionsStateChanged
#you get this on boot at least
# got event: 45 OnKeyboardLedsChanged
#as the mouse moves around the host OS
# got event: 43 OnMousePointerShapeChanged



# vbox> monitorGuestKbd randomname37562 999
# got event: 62 OnEventSourceChanged
# got event: 64 OnGuestKeyboard
# Kbd:  [18]
# got event: 64 OnGuestKeyboard
# Kbd:  [146]

# Must be run against started virtualbox, will be cached until it is read from windows gina
#`VBoxManage controlvm "#{vbox.name}" setcredentials "administrator" "passion" "none" --allowlocallogon yes`
# Should probably just setcredentials on every boot, unless there are security concerns


####### vbox.interface.session.console.event_source.create
# ree-1.8.7-2011.03 :010 > vbox.interface.session.console.event_source.create_
# vbox.interface.session.console.event_source.create_appliance
# vbox.interface.session.console.event_source.create_base_storage
# vbox.interface.session.console.event_source.create_db
# vbox.interface.session.console.event_source.create_design_document
# vbox.interface.session.console.event_source.create_dhcp_server
# vbox.interface.session.console.event_source.create_diff_storage
# vbox.interface.session.console.event_source.create_dirs_before_symlink
# vbox.interface.session.console.event_source.create_ext
# vbox.interface.session.console.event_source.create_ext_from_array
# vbox.interface.session.console.event_source.create_ext_from_hash
# vbox.interface.session.console.event_source.create_ext_from_string
# vbox.interface.session.console.event_source.create_extension
# vbox.interface.session.console.event_source.create_group
# vbox.interface.session.console.event_source.create_hard_disk
# vbox.interface.session.console.event_source.create_id_map
# vbox.interface.session.console.event_source.create_keys
# vbox.interface.session.console.event_source.create_machine
# vbox.interface.session.console.event_source.create_path
# vbox.interface.session.console.event_source.create_shared_folder
# vbox.interface.session.console.event_source.create_url
# vbox.interface.session.console.event_source.create_user
# vbox.interface.session.console.event_source.create_vfs_explorer

###  vbox.interface.session.console.create <tab tab>
# vbox.interface.session.console.create                      vbox.interface.session.console.create_extension
# vbox.interface.session.console.create_appliance            vbox.interface.session.console.create_group
# vbox.interface.session.console.create_base_storage         vbox.interface.session.console.create_hard_disk
# vbox.interface.session.console.create_db                   vbox.interface.session.console.create_id_map
# vbox.interface.session.console.create_design_document      vbox.interface.session.console.create_keys
# vbox.interface.session.console.create_dhcp_server          vbox.interface.session.console.create_machine
# vbox.interface.session.console.create_diff_storage         vbox.interface.session.console.create_path
# vbox.interface.session.console.create_dirs_before_symlink  vbox.interface.session.console.create_shared_folder
# vbox.interface.session.console.create_ext                  vbox.interface.session.console.create_url
# vbox.interface.session.console.create_ext_from_array       vbox.interface.session.console.create_user
# vbox.interface.session.console.create_ext_from_hash        vbox.interface.session.console.create_vfs_explorer
# vbox.interface.session.console.create_ext_from_string      vbox.interface.session.console.creates

# Poweroff
#`VBoxManage controlvm "#{vbox.name}" acpipowerbutton`
# Send keyboardscancode
#`VBoxManage controlvm "#{vbox.name}" keyboardputscancode 12`
# Screenshot
#`VBoxManage controlvm "#{vbox.name}" screenshotpng /tmp/foo.png`
# Snapshots:
# Take:
# `VBoxManage snapshot "#{vbox.name}" take "snapshot123" --description "SnapShot123" --pause`
# Restore: (vbox must be stopped)
#  vbox.stop
# `VBoxManage snapshot "#{vbox.name}" restore "snapshot123"`
# OR
# `VBoxManage snapshot "#{vbox.name}" restorecurrent
#  vbox.start
# `VBoxManage modifyvm "#{vbox.name}" --nattftpserver1 10.0.2.2`
# `VBoxManage modifyvm "#{vbox.name}" --nattftpfile1 /srv/tftp/boot/MyPXEBoot.pxe`


# `VBoxManage clonevm "#{vbox.name}" --register --name "#{vbox.name} New Clone"`
# `VBoxManage clonevm "#{vbox.name}" --register --name "#{vbox.name} New Clone w/ Snapshots" --mode all`

# `VBoxManage export "#{vbox.name}" \
# -o /tmp/my.ova \
# --vsys 0 --product ii --producturl ii.code.org.nz --vendor PassionEngine --vendorurl PassionEngine.org --version 0.1`
# now to monitor reboots and such and save at various stages

# case VirtualBox::Global.global.host.operating_system
# when 'Linux'
# # else #windows?
# #   ""
# end

# :bridged seems to have a more lifelike pxe implementation, at least on Oracle Virtualbox (non-OSE)
#nic.attachment_type = :bridged
#nic.bridged_interface='eth1'

# ree-1.8.7-2011.03 :044 > print `VBoxManage guestproperty enumerate "#{vbox.name}"`                                                    
# Name: /VirtualBox/HostGuest/SysprepExec, value: , timestamp: 1315537557488150000, flags: TRANSIENT, RDONLYGUEST
# Name: /VirtualBox/HostGuest/SysprepArgs, value: , timestamp: 1315537557488192000, flags: TRANSIENT, RDONLYGUEST
# Name: /VirtualBox/GuestAdd/HostVerLastChecked, value: 4.1.2, timestamp: 1315536716605769000, flags: 
# Name: /VirtualBox/GuestInfo/OS/Product, value: Windows XP Professional, timestamp: 1315537562069077000, flags: 
# Name: /VirtualBox/GuestInfo/OS/Release, value: 5.1.2600, timestamp: 1315537562069699000, flags: 
# Name: /VirtualBox/GuestInfo/OS/Version, value: , timestamp: 1315537562070277000, flags: 
# Name: /VirtualBox/GuestInfo/OS/ServicePack, value: 3, timestamp: 1315537562070732000, flags: 
# Name: /VirtualBox/GuestAdd/Version, value: 4.1.2, timestamp: 1315537562071233000, flags: 
# Name: /VirtualBox/GuestAdd/VersionExt, value: 4.1.2, timestamp: 1315537562071649000, flags: 
# Name: /VirtualBox/GuestAdd/Revision, value: 73507, timestamp: 1315537562072153000, flags: 
# Name: /VirtualBox/GuestAdd/InstallDir, value: C:/Program Files/Oracle/VirtualBox Guest Additions, timestamp: 1315537562072670000, flag
# s:                                                                                                                                   
# Name: /VirtualBox/GuestAdd/Components/VBoxControl.exe, value: 4.1.2r73507, timestamp: 1315537562074075000, flags: 
# Name: /VirtualBox/GuestAdd/Components/VBoxHook.dll, value: 4.1.2r73507, timestamp: 1315537562075023000, flags: 
# Name: /VirtualBox/GuestAdd/Components/VBoxDisp.dll, value: 4.1.2r73507, timestamp: 1315537562075854000, flags: 
# Name: /VirtualBox/GuestAdd/Components/VBoxMRXNP.dll, value: 4.1.2r73507, timestamp: 1315537562076944000, flags: 
# Name: /VirtualBox/GuestAdd/Components/VBoxService.exe, value: 4.1.2r73507, timestamp: 1315537562077794000, flags: 
# Name: /VirtualBox/GuestAdd/Components/VBoxTray.exe, value: 4.1.2r73507, timestamp: 1315537562079053000, flags: 
# Name: /VirtualBox/GuestAdd/Components/VBoxGINA.dll, value: 4.1.2r73507, timestamp: 1315537562080258000, flags: 
# Name: /VirtualBox/GuestAdd/Components/VBoxCredProv.dll, value: -, timestamp: 1315537562090160000, flags: 
# Name: /VirtualBox/GuestAdd/Components/VBoxOGLarrayspu.dll, value: 4.1.2r73507, timestamp: 1315537562091159000, flags: 
# Name: /VirtualBox/GuestAdd/Components/VBoxOGLcrutil.dll, value: 4.1.2r73507, timestamp: 1315537562092071000, flags: 
# Name: /VirtualBox/GuestAdd/Components/VBoxOGLerrorspu.dll, value: 4.1.2r73507, timestamp: 1315537562092966000, flags: 
# Name: /VirtualBox/GuestAdd/Components/VBoxOGLpackspu.dll, value: 4.1.2r73507, timestamp: 1315537562094212000, flags: 
# Name: /VirtualBox/GuestAdd/Components/VBoxOGLpassthroughspu.dll, value: 4.1.2r73507, timestamp: 1315537562095134000, flags: 
# Name: /VirtualBox/GuestAdd/Components/VBoxOGLfeedbackspu.dll, value: 4.1.2r73507, timestamp: 1315537562096308000, flags: 
# Name: /VirtualBox/GuestAdd/Components/VBoxOGL.dll, value: 4.1.2r73507, timestamp: 1315537562097638000, flags: 
# Name: /VirtualBox/GuestAdd/Components/VBoxGuest.sys, value: 4.1.2r73507, timestamp: 1315537562098489000, flags: 
# Name: /VirtualBox/GuestAdd/Components/VBoxMouse.sys, value: 4.1.2r73507, timestamp: 1315537562099537000, flags: 
# Name: /VirtualBox/GuestAdd/Components/VBoxSF.sys, value: 4.1.2r73507, timestamp: 1315537562101190000, flags: 
# Name: /VirtualBox/GuestAdd/Components/VBoxVideo.sys, value: 4.1.2r73507, timestamp: 1315537562101967000, flags: 
# Name: /VirtualBox/GuestInfo/OS/LoggedInUsersList, value: Administrator, timestamp: 1315537562102466000, flags: TRANSIENT, TRANSRESET
# Name: /VirtualBox/GuestInfo/OS/LoggedInUsers, value: 1, timestamp: 1315537562102945000, flags: TRANSIENT, TRANSRESET
# Name: /VirtualBox/GuestInfo/OS/NoLoggedInUsers, value: false, timestamp: 1315537562103418000, flags: TRANSIENT, TRANSRESET
# Name: /VirtualBox/GuestInfo/Net/0/V4/IP, value: 10.0.2.15, timestamp: 1315537562104349000, flags: 
# Name: /VirtualBox/GuestInfo/Net/0/V4/Broadcast, value: 255.255.255.255, timestamp: 1315537562104836000, flags: 
# Name: /VirtualBox/GuestInfo/Net/0/V4/Netmask, value: 255.255.255.0, timestamp: 1315537562105288000, flags: 
# Name: /VirtualBox/GuestInfo/Net/0/Status, value: Up, timestamp: 1315537562105807000, flags: 
# Name: /VirtualBox/GuestInfo/Net/0/MAC, value: 08002763AE79, timestamp: 1315537562106292000, flags: 
# Name: /VirtualBox/GuestInfo/Net/Count, value: 1, timestamp: 1315537662272468000, flags: 
# Name: /VirtualBox/HostInfo/VBoxVer, value: 4.1.2, timestamp: 1315537557488681000, flags: TRANSIENT, RDONLYGUEST
# Name: /VirtualBox/HostInfo/VBoxVerExt, value: 4.1.2, timestamp: 1315537557488714000, flags: TRANSIENT, RDONLYGUEST
# Name: /VirtualBox/HostInfo/VBoxRev, value: 73507, timestamp: 1315537557488748000, flags: TRANSIENT, RDONLYGUEST
