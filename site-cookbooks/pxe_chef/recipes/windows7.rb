
os='windows7'
flavor='32bit'
subos='enterprise'
mountfile='path/to/the.iso'

tftpdir='/tftproot'
osdir="#{tftpdir}/#{os}"
mountpoint="#{osdir}/#{flavor}"
extradir="#{mountpoint}_extra"
flavordir=mountpoint

mountonboot=true
#sorteddrivers='foo'
#activedrivers='foo'


directory osdir
directory flavordir
directory extradir

mount_iso mountfile mountpoint

sourcedir="#{mountpoint}/sources" # or uppercase
bootdir="#{mountpoint}/boot" # or uppercase

%q{ boot.wim bcd boot.sdi ei.cfg lang.ini} do |sourcefile|
  get_or_extract sourcedir, sourcefile, extradir, sourcefile
end

# pull lang from lang.ini with match #1 from /^\s*([^\s]+)\s*=\s*3\s*$/

execute "Getting XML data of install.wim for later use" do
  command "$BINDIR/wimxmlinfo #{sourcedir}/install.wim | sed 's/\\(<\\/[A-Z]*>\\)/\\1\\n/g' | sed 's/></>\\n</g' > $extradir/install.xml"
end

%q{ bootmgr.exe wdsnbp.com pxeboot.n12 } do |extractfile|
  execute "wimextract sourcedir/boot.wim //Windows/Boot/PXE #{extractfile}" do
    cwd extradir
  end
end


updatewim = true
if updatewim
  wimdir = tmdir.new 'wim.'
  %q{ winpeshl.ini windows7.cmd } do |wim_contentfile|
    # cp -f BINDIR/#{wim_contentfile} ./wimdir
  end
  file "#{wimdir}/actionfile.txt" do
    content =<<-EOF
    rename //setup.exe setup.uda
    rename //sources/setup.exe setup.uda
    add winpeshl.ini //windows/system32
    mkdir uda //sources
    add windows7.cmd //sources/uda
    EOF
  end
  winpeconfdir='/etc/winpedrv'
  #getwinpeconfig winpeconfdir/*/*driver.dat
  # if ( $line =~ /^\s*([A-Za-z0-9]+)\s*=\s*(.*)$/)
  #   {
  #     $drivers{$filename}{$1}=$2;
  #   }

  driverfile = open('/path/to/drivers.txt','w')
  %w{ driver5 } do |driver|
    inffile=winpeconfig[driver][:infile]
    sysfile=winpeconfig[driver][:sysfile]
    driverfile.write "#{driver} ENABLED #{inffile} #{sysfile}"
    copy inffile wimdir/inffile
    actionfile.write "add #{inffile} //sources/uda"
    copy inffile wimdir/sysfile
    actionfile.write "add #{sysfile} //sources/uda"
  end
  driverfile.close
  actionfile.write "add drivers.txt //sources/uda"
  actionfile.close
  
  execute "updatewim $sourcedir/boot.wim $destdir/winpe.wim $wimdir/actionfile.txt" do
    cwd $wimdir
  end
end



