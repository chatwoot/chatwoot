ENV['RAILS_ENV'] ||= 'test'
if ENV['CI'] == 'true' || ENV['CIRCLECI'] == 'true'
  require 'simplecov'
  require 'simplecov_json_formatter'
  SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
  SimpleCov.start 'rails' do
    SimpleCov.coverage_dir 'coverage'
  end
end

require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end
