Vagrant::Config.run do |config|
  config.vm.define :chef do |chef_config|
    chef_config.vm.box = "vv16"
    # chef_config.vm.box_url = "http://domain.com/path/to/above.box"
    chef_config.vm.boot_mode = :gui
    # chef_config.vm.network "33.33.33.10"
    chef_config.vm.forward_port "http", 80, 9080
    chef_config.vm.forward_port "https", 443, 9443
    chef_config.vm.forward_port "keyfile", 444, 9444
    # chef_config.vm.share_folder "v-data", "/vagrant_data", "../data"
    
    chef_config.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = "cookbooks", "site-cookbooks"
      chef.add_recipe "chef-bootstrap::apache-proxy"
      chef.json = {
        "chef_server"=> {
          "webui_enabled"=>true,
          "server_url"=>"http://#{config.vm.box}:4000",
          "init_style"=>"init",
          "ssl_req"=>
          "/C=NZ/ST=Bay of Plenty/L=Tauranga/O=PassionEngine.org/OU=DevOps/CN=chef.server/emailAddress=devops@passionengine.org"
        },
        "apache"=> {
          "contact"=>"devops@passionengine.org",
          "listen_ports"=>["80", "443"],
          "server_aliases"=>["#{config.vm.box}"]
        }
      }
    end
  end

  # config.vm.provision :chef_client do |chef|
  #   chef.chef_server_url = "https://api.opscode.com/organizations/ORGNAME"
  #   chef.validation_client_name = "ORGNAME-validator"
  #   chef.validation_key_path = "ORGNAME-validator.pem"
  # end
end
