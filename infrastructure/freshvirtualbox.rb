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
# Other options:
# :hard_disk, :usb, :dvd, :null

nic = vbox.network_adapters[0]
# our attachment_type has a huge impact on which pxe implementation we have
# since we don't seem to have much control over the DHCP server,

# :nat forces us to use a TFTP directory under the
# directory containing the VirtualBox.xml file
nic.attachment_type = :nat
case VirtualBox::Global.global.host.operating_system
when 'Linux'
  vboxhome=File.join(ENV['HOME'],'.VirtualBox')
  vbox_tftp_path=File.join(vboxhome,'TFTP') #must be uppercase
  vbox_pxe_path=File.join(vbox_tftp_path,vbox.name+'.pxe') #Our boot file
  #Copying might be interesting at some point
  #FileUtils.mkdir_p vboxhome_tftp
  #FileUtils.cp '/var/www/ipxe.pxe', "#{File.join(vboxhome_tftp,vbox.name+'.pxe')}"
  # but symlinking the whole dir works as well
  FileUtils.ln_sf('/var/www', vbox_tftp_path) if not FileTest::exists? vbox_tftp_path
  if FileTest::exists? vbox_pxe_path
    FileUtils.remove vbox_pxe_path
  end
  FileUtils.ln_sf('pxelinux.0', vbox_pxe_path) 

# else #windows must be something different... where is the VirtualBox.xml for linux?
#   ""
end

# :bridged seems to have a more lifelike pxe implementation, at least on Oracle Virtualbox (non-OSE)
#nic.attachment_type = :bridged
#nic.bridged_interface='eth1'

nic.enabled = true
nic.save

newhd=VirtualBox::HardDrive.new

newhd.location=File.join(File.dirname(vbox.settings_file_path),vbox.name+'.vdi') #within the VM dir
gigabyte=1000*1000*1024
newhd.logical_size=10*gigabyte
newhd.save

controller_name='My IDE Controller'
vbox.with_open_session do |session|
  machine = session.machine
  machine.add_storage_controller controller_name, :ide
  machine.attach_device(controller_name, 0, 0, :hard_disk, newhd.interface)
  #need dvd/cdrom
  #machine.attach_device(controller_name, 0, 0, :hard_disk, newhd.interface)
end

vbox.storage_controllers[0].controller_type = :ich6 #:piix4
vbox.save


vbox.start 
