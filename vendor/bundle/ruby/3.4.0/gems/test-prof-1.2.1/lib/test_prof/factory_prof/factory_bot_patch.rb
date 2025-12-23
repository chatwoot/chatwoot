# frozen_string_literal: true

module TestProf
  module FactoryProf
    # Wrap #run method with FactoryProf tracking
    module FactoryBotPatch
      def run(strategy = @strategy)
        FactoryBuilders::FactoryBot.track(strategy, @name) { super }
      end
    end
  end
end
