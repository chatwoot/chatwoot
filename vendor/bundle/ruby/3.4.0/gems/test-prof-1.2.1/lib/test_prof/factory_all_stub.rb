# frozen_string_literal: true

require "test_prof"
require "test_prof/factory_bot"
require "test_prof/factory_all_stub/factory_bot_patch"

module TestProf
  # FactoryAllStub inject into FactoryBot to make
  # all strategies be `build_stubbed` strategy.
  module FactoryAllStub
    LOCAL_NAME = :__factory_bot_stub_all__

    class << self
      def init
        # Monkey-patch FactoryBot / FactoryGirl
        TestProf::FactoryBot::FactoryRunner.prepend(FactoryBotPatch) if
          defined?(TestProf::FactoryBot)
      end

      def enabled?
        Thread.current[LOCAL_NAME] == true
      end

      def enable!
        Thread.current[LOCAL_NAME] = true
      end

      def disable!
        Thread.current[LOCAL_NAME] = false
      end
    end
  end
end
