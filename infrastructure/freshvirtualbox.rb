require 'virtualbox'
require 'fileutils'

boxname="randomname#{rand.to_s[2..5+1]}"
vbox = VirtualBox::VM.create boxname
vbox.os_type_id="WindowsXP"
vbox.description="A Box to Remember"

vbox.memory_size = 360
vbox.audio_adapter.enabled=false
vbox.usb_controller.enabled=false

# this will boot from network only if we can't boot from disk
vbox.boot_order=[:hard_disk ,:network,:null,:null]
vbox.extra_data['VBoxInternal/Devices/pcnet/0/LUN#0/Config/BootFile']='pxelinux.0'
vbox.extra_data['VBoxInternal/Devices/pcnet/0/LUN#0/Config/TFTPPrefix']='/var/www'

nic = vbox.network_adapters[0]
nic.attachment_type = :nat
nic.enabled = true
nic.save

newhd=VirtualBox::HardDrive.new
newhd.location=File.join(File.dirname(vbox.settings_file_path),vbox.name+'.vdi') #within the VM dir
gigabyte=1000*1000*1024
newhd.logical_size=10*gigabyte
newhd.save

controller_name='Ye Olde IDE Controller'
vbox.with_open_session do |session|
  machine = session.machine
  machine.add_storage_controller controller_name, :ide
  machine.attach_device(controller_name, 0, 0, :hard_disk, newhd.interface)
  machine.attach_device(controller_name, 0, 1, :dvd, nil) 
end

vbox.storage_controllers[0].controller_type = :ich6 #or :piix4
vbox.save

#"#{nic.mac_address}","ComputerName","#{vbox.name}"
#"#{vbox.name}","top_scripts","vboxbase.bat"

# So we need to update some data on chef-server
# and trigger a chef-client run on the pxe_boot server
# what is the best way... databag? node-data?

vbox.start 

# now to monitor reboots and such and save at various stages
