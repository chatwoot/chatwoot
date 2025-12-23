dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require File.join(dir, 'httparty')
require 'logger'
require 'pp'

my_logger = Logger.new STDOUT

my_logger.info "Logging can be used on the main HTTParty class. It logs redirects too."
HTTParty.get "http://google.com", logger: my_logger

my_logger.info '*' * 70

my_logger.info "It can be used also on a custom class."

class Google
  include HTTParty
  logger ::Logger.new STDOUT
end

Google.get "http://google.com"

my_logger.info '*' * 70

my_logger.info "The default formatter is :apache. The :curl formatter can also be used."
my_logger.info "You can tell which method to call on the logger too. It is info by default."
HTTParty.get "http://google.com", logger: my_logger, log_level: :debug, log_format: :curl

my_logger.info '*' * 70

my_logger.info "These configs are also available on custom classes."
class Google
  include HTTParty
  logger ::Logger.new(STDOUT), :debug, :curl
end

Google.get "http://google.com"
