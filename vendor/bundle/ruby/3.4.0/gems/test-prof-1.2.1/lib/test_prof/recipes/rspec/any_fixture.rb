# frozen_string_literal: true

require "test_prof/any_fixture"
require "test_prof/recipes/rspec/before_all"

RSpec.shared_context "any_fixture:clean" do
  extend TestProf::BeforeAll::RSpec

  before_all do
    TestProf::AnyFixture.clean
  end
end

RSpec.configure do |config|
  config.include_context "any_fixture:clean", with_clean_fixture: true

  config.after(:suite) do
    TestProf::AnyFixture.report_stats if TestProf::AnyFixture.config.reporting_enabled?
    TestProf::AnyFixture.reset
  end
end
