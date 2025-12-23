# frozen_string_literal: true

require "test_prof/factory_all_stub"

TestProf::FactoryAllStub.init

RSpec.shared_context "factory:stub" do
  prepend_before(:all) { TestProf::FactoryAllStub.enable! }
  append_after(:all) { TestProf::FactoryAllStub.disable! }
end

RSpec.configure do |config|
  config.include_context "factory:stub", factory: :stub
end
