maintainer       "HippieHacker.org"
maintainer_email "chris@hippiehacker.org"
license          "Apache 2.0"
description      "Installs/Configures unattended"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.0.2"

depends 'dnsmasq'
depends 'samba'
depends 'transmission'
