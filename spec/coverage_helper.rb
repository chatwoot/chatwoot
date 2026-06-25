require 'simplecov'
require 'simplecov_json_formatter'

# Configure SimpleCov to emit JSON for Qlty and HTML locally if needed
SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
SimpleCov.start 'rails' do
  SimpleCov.coverage_dir 'coverage'
end
