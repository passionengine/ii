for service in chef-server-webui chef-server chef-expander chef-solr jetty rabbitmq-server apache2 ; do
service $service stop
done

apt-get -y purge chef jetty solr-jetty rabbitmq-server rubygems rubygems1.8 apache2.2-common apache2.2-common
apt-get -y purge chef-server-webui chef-server chef-expander chef-solr

for service in chef-server-webui chef-server chef-expander chef-solr ; do
  rm -f /etc/init.d/$service 
  killall $service
done

rm -rf /usr/lib/ruby/gems /usr/bin/gem
rm -rf /usr/lib/ruby/1.8/rubygems /usr/local/lib/site_ruby/1.8/rubygems*
rm -rf /var/lib/chef /var/run/chef /etc/chef /usr/bin/chef-*
rm -rf /etc/apache2/sites-*/chef-server-proxy.conf
rm -f .chef/devops.pem
