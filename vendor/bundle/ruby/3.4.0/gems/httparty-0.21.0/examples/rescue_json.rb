dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require File.join(dir, 'httparty')

# Take note of the "; 1" at the end of the following line. It's required only if
# running this in IRB, because IRB will try to inspect the variable named
# "request", triggering the exception.
request = HTTParty.get 'https://rubygems.org/api/v1/versions/doesnotexist.json' ; 1

# Check an exception due to parsing the response
# because HTTParty evaluate the response lazily
begin
  request.inspect
  # This would also suffice by forcing the request to be parsed:
  # request.parsed_response
rescue => e
  puts "Rescued #{e.inspect}"
end
