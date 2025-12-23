ENV['RAILS_ENV'] ||= 'test'
require_relative "../config/environment"
require "rails/test_help"
require "active_storage/fixture_set"
ActiveStorage::FixtureSet.file_fixture_path = File.expand_path("fixtures/files", __dir__)

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def after_teardown
    super
    FileUtils.rm_rf(Rails.root.join('tmp', 'storage'))
  end

  # Add more helper methods to be used by all tests here...
end
