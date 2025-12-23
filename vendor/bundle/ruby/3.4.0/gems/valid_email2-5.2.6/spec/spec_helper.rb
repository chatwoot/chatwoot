$:.unshift File.expand_path("../lib",__FILE__)
require "valid_email2"

# Include and configure  benchmark
require 'rspec-benchmark'
RSpec.configure do |config|
  config.include RSpec::Benchmark::Matchers
end
RSpec::Benchmark.configure do |config|
  config.disable_gc = true
end

class TestModel
  include ActiveModel::Validations

  def initialize(attributes = {})
    @attributes = attributes
  end

  def read_attribute_for_validation(key)
    @attributes[key]
  end
end
