dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require File.join(dir, 'httparty')
require 'pp'

class Idn
    include HTTParty
    uri_adapter Addressable::URI
end

pp Idn.get("https://i❤️.ws/emojidomain/💎?format=json")