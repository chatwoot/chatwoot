ENV["RAILS_ENV"] = "test"

$LOAD_PATH.unshift File.dirname(__FILE__)

require File.expand_path("../../spec/rails_app/config/environment", __FILE__)
require "rails/test_help"

require "audited"

class ActiveSupport::TestCase
  setup do
    ActiveRecord::Migration.verbose = false
  end

  def load_schema(version)
    load File.dirname(__FILE__) + "/db/version_#{version}.rb"
  end
end
