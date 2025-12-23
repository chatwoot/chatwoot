dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require File.join(dir, 'httparty')
require 'pp'

class Rep
  include HTTParty
end

pp Rep.get('http://whoismyrepresentative.com/getall_mems.php?zip=46544')
pp Rep.get('http://whoismyrepresentative.com/getall_mems.php', query: { zip: 46544 })
