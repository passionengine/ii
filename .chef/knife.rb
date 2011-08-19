current_dir = File.dirname(__FILE__)
cookbook_copyright "PassionEngine.org"
cookbook_email "chris@hippiehacker.org"
cookbook_license "apachev2"

chef_server_url          "https://chef"
node_name                "devops"
client_key               "#{current_dir}/devops.pem"
validation_client_name   "validator"
validation_key           "#{current_dir}/validator.pem"

log_level                :info
log_location             STDOUT
cache_type               'BasicFile'
cache_options            :path =>  "#{ENV['HOME']}/.chef/checksums"

begin
require 'librarian/chef/integration/knife'
cookbook_path Librarian::Chef.install_path, "#{current_dir}/../site-cookbooks"
rescue LoadError
cookbook_path            "#{current_dir}/../cookbooks", "#{current_dir}/../site-cookbooks"
end


