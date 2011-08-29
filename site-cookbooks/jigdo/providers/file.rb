#
# Author:: Chris McClimans (<chris@hippiehacker.org>)
# Copyright:: Copyright (c) 2011 HippieHacker.org
# License:: Apache License, Version 2.0
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

require 'chef/log'
require 'chef/provider'
require 'chef/mixin/checksum'
require 'chef/mixin/shell_out'

include Chef::Mixin::ShellOut
include Chef::Mixin::Checksum

def load_current_resource
  true
end

def jigdo_file_path
  @new_resource.cwd + ::File.basename(@new_resource.source)
end

def new_resource
  #instance variables are not available in recipie_eval, but functions are
  @new_resource
end

def download_jigdo_template

  recipe_eval do

    if not ::File.exists?(jigdo_file_path)
      remote_file jigdo_file_path do 
        Chef::Log.info("FOOO #{new_resource.inspect}")
        source new_resource.source
      end
    end

    # Commented out a remote check to see if remote file is newer... jidgo's don't change that often
    # and it slows down the chef-run

    # remote_file jigdo_file_path do 
    #   Chef::Log.info("FOOO #{new_resource.inspect}")
    #   source new_resource.source
    #   action :nothing
    # end

    # http_request "HEAD #{new_resource.source}" do
    #   message ""
    #   url new_resource.source
    #   action :head
    #   if ::File.exists?(jigdo_file_path)
    #     headers "If-Modified-Since" => ::File.mtime(jigdo_file_path).httpdate
    #   end
    #   notifies :create, resources(:remote_file => jigdo_file_path), :immediately
    # end
    
  end
  
  #read jigdo file to get hashes and filenames
  jigdo_content = open(jigdo_file_path).read()
  template_name = jigdo_content.grep(/Template=()/).first.chomp.split('=')[1]

  template_local_path = @new_resource.cwd + template_name
  template_source_url = ::File.dirname @new_resource.source + '/'+ template_name
  #chef checksum is SHA256, so the md5 listed here isn't useful
  #template_md5 = jigdo_content.grep(/Template-MD5Sum=()/).first.chomp.split('=')[1]
  recipe_eval do
    # Only download it once... no more checking 
    if not ::File.exists?(template_local_path)
      remote_file template_local_path do 
        source template_source_url
      end
    end
    # Could be useful to check remote and local timestamps, download if remote is newer
    # remote_file template_local_path do 
    #   source template_source_url
    #   action :nothing
    # end

    # http_request "HEAD #{template_source_url}" do
    #   message ""
    #   url template_source_url
    #   action :head
    #   if ::File.exists?(template_local_path)
    #     headers "If-Modified-Since" => ::File.mtime(template_local_path).httpdate
    #   end
    #   notifies :create, resources(:remote_file => template_local_path), :immediately
    # end
  end
  
end


def jigsaw_download
  opts = {}
  # original implementation did not specify a timeout, but ShellOut
  # *always* times out. So, set a very long default timeout
  #opts[:timeout] = @new_resource.timeout || 3600
  #opts[:returns] = @new_resource.returns if @new_resource.returns
  #environment = @new_resource.environment ? @new_resource.environment : {}
  # @new_resource.http_proxy ? environment.merge({'http_proxy' => @new_resource.http_proxy}) : environment
  opts[:environment] = {'http_proxy' => @new_resource.http_proxy} if @new_resource.http_proxy
  opts[:user] = @new_resource.user if @new_resource.user
  opts[:group] = @new_resource.group if @new_resource.group
  opts[:cwd] = @new_resource.cwd if @new_resource.cwd
  opts[:umask] = @new_resource.umask if @new_resource.umask
  opts[:command_log_level] = :info
  opts[:command_log_prepend] = @new_resource.to_s
  if STDOUT.tty? && !Chef::Config[:daemon] && Chef::Log.info?
    opts[:live_stream] = STDOUT
  end
  
  command = "jigdo-lite --noask #{@jigdo_file_path}"
  result = shell_out!(command, opts)
  @new_resource.updated_by_last_action(true)
  Chef::Log.info("#{@new_resource} ran successfully")
end

def action_run
  download_jigdo_template

  jigdo_content = open(jigdo_file_path).read()
  iso_name = jigdo_content.grep(/Filename=()/).first.chomp.split('=')[1]
  iso_sha256 = jigdo_content.grep(/Image Hex SHA256Sum/).first.chomp.split()[4]
  iso_local_path = @new_resource.cwd + iso_name
  
  if not ::File.exists?(iso_local_path)
    jigsaw_download
  elsif checksum(iso_local_path) != iso_sha256
    Chef::Log.info("#{@new_resource} PROBLEM #{checksum(iso_local_path)} != #{iso_sha256}")
    raise "file exists and checksum invalid"
  else
    Chef::Log.info("#{@new_resource} turned into #{iso_local_path}!")
  end
    
end
