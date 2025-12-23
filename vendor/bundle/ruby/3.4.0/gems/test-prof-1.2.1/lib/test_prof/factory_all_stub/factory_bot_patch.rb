# frozen_string_literal: true

module TestProf
  module FactoryAllStub
    # Wrap #run method to override strategy
    module FactoryBotPatch
      def run(_strategy = @strategy)
        return super unless FactoryAllStub.enabled?
        super(:build_stubbed)
      end
    end
  end
end
