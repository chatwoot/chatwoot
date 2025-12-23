# frozen_string_literal: true

require "test_prof/factory_prof/factory_bot_patch"
require "test_prof/factory_bot"
require "test_prof/ext/factory_bot_strategy"

module TestProf
  module FactoryProf
    module FactoryBuilders
      # implementation of #patch and #track methods
      # to provide unified interface for all factory-building gems
      class FactoryBot
        using TestProf::FactoryBotStrategy

        # Monkey-patch FactoryBot / FactoryGirl
        def self.patch
          TestProf::FactoryBot::FactoryRunner.prepend(FactoryBotPatch) if
            defined? TestProf::FactoryBot
        end

        def self.track(strategy, factory, &block)
          return yield unless strategy.create?
          FactoryProf.track(factory, &block)
        end
      end
    end
  end
end
