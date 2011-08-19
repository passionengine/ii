maintainer       "PassionEngine.org"
maintainer_email "chris@hippiehacker.org"
license          "Apache 2.0"
description      "Installs/Configures chef-bootstrap"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.0.1"
recipe            "chef-bootstrap::apache-proxy", "Replacement for broken chef_server::apache-proxy"
recipe            "chef-bootstrap::rabbitmq-password", "Support password changes for chef_server::rabbitmq"


depends 'chef-server'
