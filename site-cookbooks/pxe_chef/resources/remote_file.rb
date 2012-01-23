def initialize(*args)
  super
  @action = :create
end

actions :create, :update
attribute :path, :kind_of => String, :name_attribute => true
attribute :source, :kind_of => String, :required => true
attribute :backup, :kind_of => [ Integer, FalseClass ], :default => false
attribute :checksum, :regex => /^[a-zA-Z0-9]{64}$/
attribute :owner, :regex => Chef::Config[:group_valid_regex]
attribute :group, :regex => Chef::Config[:group_valid_regex]
attribute :mode, :default => '0755', :callbacks => { 
  "not in valid numeric range" => lambda { |m| 
    if m.kind_of?(String)
      m =~ /^0/ || m="0#{m}"
    end 
    Integer(m)<=07777 && Integer(m)>=0
  }
}



