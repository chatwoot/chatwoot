# frozen_string_literal: true

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'rspec'
require 'rspec/autorun'

require 'hashdiff'

RSpec.configure do |config|
  config.mock_framework = :rspec

  config.include RSpec::Matchers
end
