dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require File.join(dir, 'httparty')

peer_cert = nil
HTTParty.get("https://www.example.com") do |fragment|
  peer_cert ||= fragment.connection.peer_cert
end

puts "The server's certificate expires #{peer_cert.not_after}"
