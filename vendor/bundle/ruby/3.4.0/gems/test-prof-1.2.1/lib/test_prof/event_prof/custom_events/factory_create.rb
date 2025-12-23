# frozen_string_literal: true

require "test_prof/factory_bot"
require "test_prof/ext/factory_bot_strategy"

using TestProf::FactoryBotStrategy

TestProf::EventProf::CustomEvents.register("factory.create") do
  if defined?(TestProf::FactoryBot) || defined?(Fabricate)
    if defined?(TestProf::FactoryBot)
      TestProf::EventProf.monitor(
        TestProf::FactoryBot::FactoryRunner,
        "factory.create",
        :run,
        top_level: true,
        guard: ->(strategy = @strategy) { strategy.create? }
      )
    end

    if defined?(Fabricate)
      TestProf::EventProf.monitor(
        Fabricate.singleton_class,
        "factory.create",
        :create,
        top_level: true
      )
    end
  else
    TestProf.log(
      :error,
      <<~MSG
        Failed to load factory_bot / factory_girl / fabrication.

        Make sure that any of them is in your Gemfile.
      MSG
    )
  end
end
