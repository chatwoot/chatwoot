require 'rubygems' if RUBY_VERSION < '1.9.0'
require File.expand_path('../lib/os.rb', File.dirname(__FILE__))

require 'rspec' # rspec2
require 'rspec/autorun'

RSpec.configure do |config|
  config.expect_with :rspec, :stdlib # enable `should` OR `assert`
end

