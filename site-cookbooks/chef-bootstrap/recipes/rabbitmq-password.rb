#
# Cookbook Name:: chef-bootstrap
# Recipe:: rabbitmq-password
#
# Copyright 2011, PassionEngine.org
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Security Risk: FIXME... I'd probably rather fork this, but not now

# /etc/chef/expander.rb:amqp_pass "testing"
# /etc/chef/solr.rb:amqp_pass "testing"

# unless node.chef_server_amqp_pass = open('/etc/chef/expander.rb').read.grep(/amqp_pass "(.*)"/)[0].match(/amqp_pass "(.*)"/)[1] 

# execute "rabbitmqctl change_password chef" do
#   command "rabbitmqctl change_password chef #{node.chef_server.amqp_pass}"
  
# end


