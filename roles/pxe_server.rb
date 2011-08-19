name "pxe_server"
description "PXE Dust Boot Server"
#run_list "recipe[apache2]", "recipe[apache2::mod_ssl]", "role[monitor]"
#run_list "recipe[getting-started]"
run_list(
         "recipe[pxe_dust::server]",
         "recipe[pxe_dust::ubuntu-studio]",
         "recipe[dnsmasq]",
         "recipe[unattended]"
         )
#,
#         "recipe[apt::cacher]"
# apt::cacher is interesting, but I'm using squid-deb-proxy
#env_run_lists "prod" => ["recipe[apache2]"], "staging" => ["recipe[apache2::staging]"]
default_attributes(
                   "tftp" => {
                     "directory" => "/var/lib/tftpboot"
                   },
                   "pxe_dust" => {
                     "arch" => "amd64",
                     "version" => "natty",
                     "directory" => "/var/www",
                     "user" => {
                       "fullname" => "Chris McClimans",
                       "username" => "chris",
                       "crypted_password" => "$6$0p1qarPw$pLagFhmT5GWGplneNF/sKM77rbdii8nHdl4Fbhl/sqwA7dWgNbFMjcSq97ITQqpj6FrL3Qi4OJaKyJvzaRHlt0"
                     }
                   },
                   "samba" => {
                     "interfaces" => "eth0 eth1",
                     "hosts_allow" => "0.0.0.0/32"
                   }
                   )
#FIXME: sambda should probably not listen everywhere, fix at some pont
#env_run_lists "prod" => ["recipe[apache2]"], "staging" => ["recipe[apache2::staging]"]
#default_attributes "apache2" => { "listen_ports" => [ "80", "443" ] }
#override_attributes "apache2" => { "max_children" => "50" }