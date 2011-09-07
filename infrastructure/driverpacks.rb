require 'rubygems'
require 'mechanize'
require 'bencode' # for .bdecode on torrent blob
require 'digest/sha1' # for .hexdigest on torrent blob
require 'pp' # this output does have to go in a human reable file!
require 'orderedhash' # to make the chef_attrib_entries have a specified order

agent = Mechanize.new

latest = agent.get 'http://driverpacks.net/driverpacks/latest'

xp_urls = latest.links_with(:href=>/xp\/x86/).map &:href

xp_driver_torrent_urls = xp_urls.map do |xp_driver_url|
  resp = agent.get xp_driver_url
  resp.link_with(:href=>/torrent$/).href
end

chef_attrib_entries = xp_driver_torrent_urls.map do |url|
  resp = agent.get url

  url_inc_host = "#{resp.uri.scheme}://#{resp.uri.host}#{url}"
  sha = Digest::SHA256.hexdigest resp.body
  content_filename = resp.body.bdecode["info"]["name"]
  torrent_filename = resp.filename

  entry = OrderedHash[
    :url, url_inc_host,
    :sha256, sha,
    :content_filename, content_filename,
    :torrent_filename, torrent_filename
  ]
  entry
end

pp chef_attrib_entries
