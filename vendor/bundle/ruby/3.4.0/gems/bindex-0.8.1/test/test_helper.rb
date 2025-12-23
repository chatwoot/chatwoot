$LOAD_PATH << File.expand_path('../lib', __FILE__)

require 'minitest/autorun'
require 'skiptrace'

current_directory = File.dirname(File.expand_path(__FILE__))

# Fixtures are plain classes that respond to #call.
Dir["#{current_directory}/fixtures/**/*.rb"].each do |fixture|
  require fixture
end

module Skiptrace
  class Test < MiniTest::Test
    def self.test(name, &block)
      define_method("test_#{name}", &block)
    end
  end
end
