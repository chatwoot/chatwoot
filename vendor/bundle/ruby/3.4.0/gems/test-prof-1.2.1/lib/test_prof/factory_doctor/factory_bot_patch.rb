# frozen_string_literal: true

require "test_prof/ext/factory_bot_strategy"

module TestProf
  module FactoryDoctor
    # Wrap #run method with FactoryDoctor tracking
    module FactoryBotPatch
      using TestProf::FactoryBotStrategy

      def run(strategy = @strategy)
        FactoryDoctor.within_factory(strategy.create? ? :create : :other) { super }
      end
    end
  end
end
