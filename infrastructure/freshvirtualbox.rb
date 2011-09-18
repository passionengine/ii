require 'virtualbox'
require 'fileutils'
require 'chef'
Chef::Config.from_file '.chef/knife.rb'


def createvbox(os=:windows,x64=false)
  boxnum = rand.to_s[2..4+1].to_i
  boxname="winxp___#{boxnum}" if os == :windows
  if os == :ubuntu 
    if x64
      boxname="ubuntu64_#{boxnum}"
    else
      boxname="ubuntu__#{boxnum}" 
    end
  end

  vbox = VirtualBox::VM.create boxname
  vbox.description="A Box to Remember"
  
  vbox.memory_size = 360 #I want to run a few of these
  vbox.vram_size = 32 #just enough for fullscreen + 2d accel
  vbox.accelerate_2d_video_enabled=true #needed?
  vbox.audio_adapter.enabled=false # not needed
  vbox.usb_controller.enabled=false # not needed... yet
  
  newhd=VirtualBox::HardDrive.new
  newhd.location=File.join(File.dirname(vbox.settings_file_path),vbox.name+'.vdi') #within the VM dir
  gigabyte=1000*1000*1024
  newhd.logical_size=10*gigabyte
  newhd.save

  controller_name='Ye Olde IDE Controller'
  vbox.with_open_session do |session|
    machine = session.machine
    #possibly change the screen on each boot... for demo?
    #machine.bios_settings.logo_image_path='/var/www/ii.bmp' #256/8bit BMP
    machine.bios_settings.pxe_debug_enabled=true
    #machine.create_shared_folder 'Sharename', '/path', RW?, Automount?
    machine.create_shared_folder 'HostRoot', '/', false, true
    machine.create_shared_folder 'Unattended', '/var/unattended/install', false, true
    machine.create_shared_folder 'Tmp', '/tmp', true, true
    machine.add_storage_controller controller_name, :ide
    machine.attach_device(controller_name, 0, 0, :hard_disk, newhd.interface)
    machine.attach_device(controller_name, 0, 1, :dvd, nil) 
  end

  vbox.storage_controllers[0].controller_type = :ich6 #or :piix4

  # this will boot from nerk only if we can't boot from disk
  vbox.boot_order=[:hard_disk ,:network,:null,:null]
  vbox.extra_data['VBoxInternal/Devices/pcnet/0/LUN#0/Config/BootFile']='pxelinux.0'
  vbox.extra_data['VBoxInternal/Devices/pcnet/0/LUN#0/Config/TFTPPrefix']='/var/www/'
  

  vbox.extra_data['VBoxInternal/Devices/VMMDev/0/Config/KeepCredentials']='1'

  nic = vbox.network_adapters[0]
  nic.attachment_type = :nat
  nic.enabled = true
  nic.save
  
  # we should be able to ssh localhost -P <the 5 digits of after randomname>

  port = VirtualBox::NATForwardedPort.new
  port.name = 'ssh'
  port.guestport = 22
  port.hostport = boxnum
  port.protocol = :tcp
  vbox.network_adapters[0].nat_driver.forwarded_ports << port
  # Thank you Taylor for this:
  # "0800273B51A9".taylor_ruby_foo() # => "08-00-27-3B-51-A9" 
  tftp_conffile = "01-#{nic.mac_address.split(/(..)/).reject do|c| c.empty? end.join('-').downcase}"
  if os == :windows
    vbox.os_type_id="WindowsXP"
    File.symlink '/var/www/pxelinux.cfg/default-winxp', "/var/www/pxelinux.cfg/#{tftp_conffile}"
  elsif os == :ubuntu and x64
    vbox.os_type_id="Ubuntu_64"
    File.symlink '/var/www/pxelinux.cfg/default-ubuntu64', "/var/www/pxelinux.cfg/#{tftp_conffile}"
    # not needed anymore, as we just boot pxelinux.0 and use the same tftpprefix everytime now!!
    #vbox.extra_data['VBoxInternal/Devices/pcnet/0/LUN#0/Config/TFTPPrefix']='/var/www/ubuntu-installer/amd64'
  else # default os == :ubuntu i632
    vbox.os_type_id="Ubuntu"
    File.symlink '/var/www/pxelinux.cfg/default-ubuntu', "/var/www/pxelinux.cfg/#{tftp_conffile}"
    #vbox.extra_data['VBoxInternal/Devices/pcnet/0/LUN#0/Config/TFTPPrefix']='/var/www/ubuntu-installer/i386'
    #vbox.extra_data['VBoxInternal/Devices/pcnet/0/LUN#0/Config/TFTPPrefix']='/var/www/pxe_dust'
  end

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
  mylines = []
  myline = ""
  puts 'entering dasloop'
  # while true do
  #   puts 'screenshoting'
  #   `VBoxManage controlvm '#{vbox.name}' screenshotpng  /tmp/post#{Time.now.utc.iso8601}.png`
  # end
  @last_snap = Time.now
  while 1
    read_until2 IO.popen("/usr/lib/virtualbox/vboxshell.py -c 'monitorGuest #{vbox.name} 3'"), /aoeu/, vbox, false
  end
end


def read_until2(pipe, stop_at, vbox, verbose = true)
  lines = []
  line = ""
  #puts "YY: #{pipe}, #{stop_at}"
  last_snap = Time.now
  while result = IO.select([pipe], nil, nil, 5)
    next if result.empty?

    c = pipe.read(1)
    #puts "C: #{c}"
    break if c.nil?

    line << c
    break if line =~ stop_at
    #puts 'XX: #{line}'
    # Start a new line?
    if line[-1] == ?\n
      puts line if verbose
      $stdout.flush
      case line
      when /Running VirtualBox version/
        line = ""
        next
      when /got event: 62 OnEventSourceChanged/
        # someone is listening!
        line = ""
        next
      when /got event: 58 OnCanShowWindow/
        # Not interesting... has to do with UI
        line = ""
        next
      when /got event: 44 OnMouseCapabilityChanged/
        # Not sure how interesting this is
        # vbox.pause
        # vbox.save_state
        # sleep 4
        # vbox.take_snapshot("MouseCapabilityChanged-#{`date`}", '')
        # vbox.start
        # print 'A'
        lines << line
        line = ""
        next
      when /got event: 45 OnKeyboardLedsChanged/
        timelapse = Time.now - @last_snap
        print "l#{timelapse}"
        # Seems to happen after OS loads
        next if timelapse < 10
        vbox.pause
        vbox.save_state
        sleep 4
        vbox.take_snapshot("KeyboardLedsChanged-#{`date`}", '')
        vbox.start
        @last_snap=Time.now
        print 'L'
        # 1st - Linux Kernel keyboard or usb init?
        lines << line
        line = ""
        next
      when /got event: 47 OnAdditionsStateChanged/
      when /pointer shape event/
        # vbox.pause
        # vbox.save_state
        # sleep 4
        # vbox.take_snapshot("AdditionStateChanged-#{`date`}", '')
        # vbox.startwj
        # First winboot
        print 'A'
        lines << line
        line = ""
        next
      else
        vbox.pause
        vbox.save_state
        sleep 4
        vbox.take_snapshot("SomethingElseChanged-#{`date`}", line)
        vbox.start
        print '!'
        lines << line
        line = ""
      end
    end
  end
  lines
end
 

#ENV['VBOX_PROGRAM_PATH']='/usr/lib/virtualbox'
#ENV['VBOX_SDK_PATH']='/usr/lib/virtualbox/sdk/bindings/xpcom/python/'


# ENV['PYTHONPATH']='/usr/lib/virtualbox:/home/chris/boot/rr'
# require 'rubypython'
# RubyPython.start
# vboxpy = RubyPython.import 'vbox' 
# vmach = vboxpy.argsToMach(vboxpy.ctx, ['','randomname69618'])
# #vboxpy.monitorGuestCmd vboxpy.ctx, ['','randomname69618',999]


# def handleEvent(ev)
#   puts '####{ev.inspect}'
# end

# vboxpy.cmdExistingVm vboxpy.ctx, vmach, 'guestlambda', lambda {
#   |ctx,mach,console,args|
#   duration = 30
#   #
#   es = console.eventSource
#   listener = es.createListener()
#   begin
#     es.registerListener(listener, [ctx['global'].constants.VBoxEventType_Any], active)
#     endtime = Time::now + duration
#     while Time::now < endtime
#       ev = es.getEvent(listener, 500)
#       handleEvent(ev) and es.eventProcessed(listener, ev) if ev
#     end
#   rescue
#     # We need to catch all exceptions here, otherwise listener will never be unregistered
#     es.unregisterListener(listener)
#     # now raise?
#     nil
#   end
# }
#     #    end = time.time() + dur
#     #     while  time.time() < end:
#     #         if active
#     #             ctx['global'].waitForEvents(500)
#     #         else:
#     #             ev = es.getEvent(listener, 500)
#     #             if ev:
#     #                 handleEventImpl(ev)
#     #                 # otherwise waitable events will leak (active listeners ACK automatically)
#     #                 es.eventProcessed(listener, ev)
#     # # We need to catch all exceptions here, otherwise listener will never be unregistered
#     # except:
#     #     traceback.print_exc()
#     #     pass
#     # if listener and registered:
#     #     es.unregisterListener(listener)

  





# def read_monitor
#   stop_at = /foo/
#   verbose = true
#   lines = []
#   line = ""
#   puts "YY: #{pipe}, #{stop_at}"
#   [stdout,stdin,stderr] = Open3.popen3("/usr/lib/virtualbox/vboxshell.py -c 'monitorGuest #{vbox.name} 999999'")
#   while result = IO.select([stdout], nil, nil, 1 )
#     next if result.empty?
#     puts "result: #{result}"

#     c = pipe.read(1)
#     puts "C: #{c}"
#     break if c.nil?

#     line << c
#     break if line =~ stop_at
#     puts 'XX: #{line}'
#     # Start a new line?
#     if line[-1] == ?\n
#       puts line if verbose
#       $stdout.flush
#       lines << line
#       line = ""
#     end
#   end
#   lines
# end

# read_monitor

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
