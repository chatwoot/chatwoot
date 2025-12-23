# frozen_string_literal: true

require "test_prof/factory_default"

TestProf::FactoryDefault.init

if defined?(TestProf::BeforeAll)
  TestProf::BeforeAll.configure do |config|
    config.before(:begin) do |context|
      TestProf::FactoryDefault.current_context = context
    end

    config.after(:rollback) do |context|
      TestProf::FactoryDefault.reset(context: context)
    end
  end
end

RSpec.configure do |config|
  if defined?(TestProf::BeforeAll)
    config.before(:each) { TestProf::FactoryDefault.current_context = :example }
    config.after(:each) { TestProf::FactoryDefault.reset(context: :example) }
  else
    config.after(:each) { TestProf::FactoryDefault.reset }
  end

  config.after(:suite) { TestProf::FactoryDefault.print_report }
end
