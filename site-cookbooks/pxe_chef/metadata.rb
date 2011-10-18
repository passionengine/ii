maintainer       "Chris McClimans"
maintainer_email "chris@idealinfrastructure.org"
license          "Apache 2.0"
description      "Configures a server to netboot freshs installs of any os and connect to chef"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"
#depends          "apache2"
#depends          "jigdo"

#tested with Ubuntu, assume Debian works similarly 
%w{ ubuntu }.each do |os|
  supports os
end
