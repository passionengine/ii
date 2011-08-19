
template "/usr/local/etc/dnsmasq.conf" do
  source "dnsmasq.conf.erb"
end

template "/usr/local/sbin/dnsmasq" do
  source "dnsmasq.erb"
end
