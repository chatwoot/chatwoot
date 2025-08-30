ENV['RAILS_ENV'] ||= 'test'
require 'simplecov'
require 'simplecov_json_formatter'
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
                                                                 SimpleCov::Formatter::JSONFormatter,
                                                                 SimpleCov::Formatter::HTMLFormatter
                                                               ])
SimpleCov.start 'rails' do
  SimpleCov.coverage_dir 'coverage'
  SimpleCov::Formatter::JSONFormatter.output_filename = 'coverage.json'
end

require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end
