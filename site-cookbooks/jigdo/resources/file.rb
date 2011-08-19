def initialize(*args)
  super
  @action = :run
end

actions :run
attribute :source, :kind_of => String, :name_attribute => true
attribute :http_proxy, :kind_of => String
attribute :cwd, :kind_of => String, :default => './'
attribute :umask, :kind_of => String
attribute :user, :kind_of => String
attribute :group, :kind_of => String
