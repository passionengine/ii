# require 'chef/file_cache'
# require 'chef/file_access_control'
# require 'digest/sha1'
# require 'chef/mixin/checksum'
# require 'tempfile'
# require 'uri'
# include Chef::Mixin::Checksum

# action :create do
#   nr = @new_resource.clone
#   target_dir = ::File.dirname(nr.path)
#   cache_dir_path = "#{Chef::Config[:file_cache_path]}/#{cookbook_name}/#{nr.path.gsub('/','_'}"
#   cache_zip_path = "#{cache_path}.zip"

#   cache_zip = remote_file "#{cache_zip_path}" do
#     source nr.source
#     backup nr.backup
#     checksum nr.checksum if nr.checksum
#     not_if { ::File.exists? cache_zip_path }
#   end

#   directory cache_dir_path do
#     recursive true
#     not_if { ::File.directory? cache_dir_path }
#   end

#   execute "unzip -o #{cache_zip_path} && touch #{cache_zip_path}.decompressed" do
#     cwd cache_dir_path
#     umask nr.umask
#     creates "#{cache_zip_path}.decompressed"
#   end

#   directory target_dir do
#     recursive true
#     not_if { ::File.directory? target_dir }
#   end

#   # do something similar to cookbook_file here, but grab from cache
#   source_dir="#{cache_dir_path}/#{nr.source_subdir}"
#   ruby_block "Copy #{source_dir} to #{nr.path}" do
#     block do
#       if not FileUtils.uptodate?(source_dir, nr.path)
#         FileUtils.cp source_dir, nr.path, :preserve => true
#       end
#       #Chef::FileAccessControl.new(cache_zip, nr.path).set_all
#     end
#     #not_if { ::File.exists? nr.path }
#     # only_if do 
#     #   not ::File.exists? nr.path
#     # end
#   end
#   #cache_zip.set_all_access_controls nr.path

# end

