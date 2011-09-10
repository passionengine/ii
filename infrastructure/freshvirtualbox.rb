require 'virtualbox'
require 'fileutils'
require 'chef'
Chef::Config.from_file '.chef/knife.rb'

boxname="randomname#{rand.to_s[2..5+1]}"
vbox = VirtualBox::VM.create boxname
vbox.os_type_id="WindowsXP"
vbox.description="A Box to Remember"

vbox.memory_size = 360
vbox.audio_adapter.enabled=false
vbox.usb_controller.enabled=false

newhd=VirtualBox::HardDrive.new
newhd.location=File.join(File.dirname(vbox.settings_file_path),vbox.name+'.vdi') #within the VM dir
gigabyte=1000*1000*1024
newhd.logical_size=10*gigabyte
newhd.save

controller_name='Ye Olde IDE Controller'
vbox.with_open_session do |session|
  machine = session.machine
  #possibly change the screen on each boot... for demo?
  machine.bios_settings.logo_image_path='/var/www/ii.bmp' #256/8bit BMP
  machine.bios_settings.pxe_debug_enabled=true
  #machine.create_shared_folder 'Sharename', '/path', RW?, Automount?
  machine.create_shared_folder 'HostRoot', '/', false, true
  machine.create_shared_folder 'Unattended', '/var/unattended/install', false, true
  machine.create_shared_folder 'Tmp', '/tmp', true, true
  machine.add_storage_controller controller_name, :ide
  machine.attach_device(controller_name, 0, 0, :hard_disk, newhd.interface)
  machine.attach_device(controller_name, 0, 1, :dvd, nil) 
end
# YES
# vbox.control 'power_down'

#          function :create_shared_folder, nil, [WSTRING, WSTRING, T_BOOL, T_BOOL]

vbox.storage_controllers[0].controller_type = :ich6 #or :piix4

# this will boot from nerk only if we can't boot from disk
vbox.boot_order=[:hard_disk ,:network,:null,:null]
vbox.extra_data['VBoxInternal/Devices/pcnet/0/LUN#0/Config/BootFile']='pxelinux.0'
vbox.extra_data['VBoxInternal/Devices/pcnet/0/LUN#0/Config/TFTPPrefix']='/var/www'
vbox.extra_data['VBoxInternal/Devices/VMMDev/0/Config/KeepCredentials']='1'

nic = vbox.network_adapters[0]
nic.attachment_type = :nat
nic.enabled = true
nic.save
vbox.save

# requires a real tftp server
#`VBoxManage modifyvm "#{vbox.name}" --nattftpserver1 192.168.2.7`
#`VBoxManage modifyvm "#{vbox.name}" --nattftpfile1 pxelinux.0`

if not Chef::DataBag.cdb_list.include? 'virtualboxen'
  Chef::DataBag.json_create({'name'=>'virtualboxen'}).save
end

Chef::DataBagItem.json_create({
    'data_bag'=>'virtualboxen',
    'raw_data'=> {
      'id'=>vbox.name,
      'mac_address'=>nic.mac_address
    }
  }).save

# This doesn't seem possible from Ruby yet:
# http://www.virtualbox.org/manual/ch09.html#autologon_win
# 

vbox.start
# Must be run against started virtualbox, will be cached until it is read from windows gina
`VBoxManage controlvm "#{vbox.name}" setcredentials "administrator" "passion" "none" --allowlocallogon yes`
# Should probably just setcredentials on every boot, unless there are security concerns



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
