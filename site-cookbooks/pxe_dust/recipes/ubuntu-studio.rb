# Author:: Matt Ray <matt@opscode.com>
# Cookbook Name:: pxe_dust
# Recipe:: server
#
# Copyright 2011, Opscode, Inc
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

# could also do bit-torrent, but at least jigdo allows us to fill our local cache

include_recipe 'jigdo'

jigdo_file "http://cdimage.ubuntu.com/ubuntustudio/releases/11.04/release/ubuntustudio-11.04-alternate-amd64.jigdo" do
  cwd "/var/www/"
  http_proxy 'localhost:8000'
end


