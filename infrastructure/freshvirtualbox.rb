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
  session.machine.bios_settings.logo_image_path='/var/www/ii.bmp' #256/8bit BMP
  session.machine.bios_settings.logo_display_time=3000 #3 seconds in ms
  session.machine.bios_settings.pxe_debug_enabled=true
  machine.add_storage_controller controller_name, :ide
  machine.attach_device(controller_name, 0, 0, :hard_disk, newhd.interface)
  machine.attach_device(controller_name, 0, 1, :dvd, nil) 
end


vbox.storage_controllers[0].controller_type = :ich6 #or :piix4

# this will boot from network only if we can't boot from disk
vbox.boot_order=[:hard_disk ,:network,:null,:null]
vbox.extra_data['VBoxInternal/Devices/pcnet/0/LUN#0/Config/BootFile']='pxelinux.0'
vbox.extra_data['VBoxInternal/Devices/pcnet/0/LUN#0/Config/TFTPPrefix']='/var/www'

nic = vbox.network_adapters[0]
nic.attachment_type = :nat
nic.enabled = true
nic.save

vbox.save

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

vbox.start 

# now to monitor reboots and such and save at various stages
