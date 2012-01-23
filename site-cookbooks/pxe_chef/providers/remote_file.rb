require 'chef/file_cache'
require 'chef/file_access_control'
require 'digest/sha1'
require 'chef/mixin/checksum'
require 'tempfile'
require 'uri'
include Chef::Mixin::Checksum



# def load_current_resource
#   @current_resource = Chef::Resource::PxeChefRemoteFile.new(@new_resource.name)
#   @new_resource.path.gsub!(/\\/, "/") # for Windows
#   @current_resource.path(@new_resource.path)
#   if ::File.exist?(@current_resource.path) && ::File.readable?(@current_resource.path)
#     cstats = ::File.stat(@current_resource.path)
#     @current_resource.owner(cstats.uid)
#     @current_resource.group(cstats.gid)
#     @current_resource.mode(octal_mode(cstats.mode))
#   end
#   @current_resource.checksum(checksum(@current_resource.path)) if ::File.exist?(@current_resource.path)
#   @current_resource
# end

action :create do
  nr = @new_resource.clone
  target_dir = ::File.dirname(nr.path)
  cache_file_path = "#{Chef::Config[:file_cache_path]}/#{cookbook_name}/#{nr.path}"
  cache_file_dir = ::File.dirname(cache_file_path)

  # cachedir and files shouldn't be writeable by anyone but root etc FIXME
  directory cache_file_dir do
    recursive true
    not_if { ::File.directory? cache_file_dir }
  end
  
  cache_file = remote_file "#{cache_file_path}" do
    source nr.source
    backup nr.backup
    mode nr.mode if nr.mode
    owner nr.owner if nr.owner
    group nr.group if nr.group
    checksum nr.checksum if nr.checksum
    not_if { ::File.exists? cache_file_path }
  end

  directory target_dir do
    recursive true
    not_if { ::File.directory? target_dir }
  end

  # do something similar to cookbook_file here, but grab from cache
  ruby_block "Copy #{cache_file_path} to #{nr.path}" do
    block do
      FileUtils.cp cache_file_path, nr.path, :preserve => true
    end
    not_if { ::File.exists? nr.path }
    # only_if do 
    #   not ::File.exists? nr.path
    # end
  end
  ruby_block "Set permissions on #{nr.path}" do
    block do
      Chef::FileAccessControl.new(cache_file, nr.path).set_all
    end
    #not_if { ::File.exists? nr.path }
    # only_if do 
    #   not ::File.exists? nr.path
    # end
  end
      
  #cache_file.set_all_access_controls nr.path

end

action :update do
  nr = @new_resource.clone
  target_dir = ::File.dirname(nr.path)
  cache_file_path = "#{Chef::Config[:file_cache_path]}/#{cookbook_name}/#{nr.path}"
  cache_file_dir = ::File.dirname(cache_file_path)

  directory cache_file_dir do
    recursive true
    not_if ::File.directory? cache_file_dir
  end
  
  cache_file = remote_file "#{cache_file_path}" do
    source nr.source
    backup nr.backup
    mode nr.mode if nr.mode
    owner nr.owner if nr.owner
    group nr.group if nr.group
    checksum nr.checksum if nr.checksum
    action :nothing  # download header and compare timestamp before doing anything
  end

  http_request "HEAD #{nr.source}" do
    message ""
    url nr.source
    action :head
    if File.exists? cache_file.path
      headers "If-Modified-Since" => File.mtime(cache_file_path).httpdate
    end
    notifies :create, resources(:remote_file => cache_file_path), :immediately
  end

  directory target_dir do
    recursive true
    not_if ::File.directory? target_dir
  end

  # do something similar to cookbook_file here, but grab from cache
  ruby_block "Copy #{cache_file_path} to #{nr.path}" do
    block do
      if not FileUtils.uptodate?(cache_file_path, nr.path)
        FileUtils.cp cache_file_path, nr.path, :preserve => true
      end
      Chef::FileAccessControl.new(cache_file, nr.path).set_all
    end
  end
end
