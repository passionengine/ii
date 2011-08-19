current_dir = File.dirname(__FILE__)
cookbook_path            "#{Dir.getwd}/cookbooks", "#{Dir.getwd}/site-cookbooks"
json_attribs             "#{current_dir}/chef-apt-bootstrap-solo.json"
hostname = open('/etc/hostname').read.chomp

jsonconfig={"chef_server"=> {
    "webui_enabled"=>true,
    "server_url"=>"http://#{hostname}:4000",
    "init_style"=>"init",
    "ssl_req"=>
    "/C=NZ/ST=Bay of Plenty/L=Tauranga/O=PassionEngine.org/OU=DevOps/CN=chef.server/emailAddress=devops@passionengine.org"
  },
  "run_list"=> [
                "recipe[chef-bootstrap::apache-proxy]"
               ],
  "apache"=> {
    "contact"=>"devops@passionengine.org",
    "listen_ports"=>["80", "443"],
    "server_aliases"=>["#{hostname}"]
  }
}.to_json

jsonfile = open(@configuration[:json_attribs],'w')
jsonfile.write jsonconfig
jsonfile.close
