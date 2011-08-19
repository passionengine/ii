maintainer       "HippieHacker.org"
maintainer_email "chris@hippiehakcer.org"
license          "GPL"
description      "Installs/Configures jigdo"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.0.1"

#tested with Ubuntu, assume Debian works similarly 
%w{ ubuntu }.each do |os|
  supports os
end
