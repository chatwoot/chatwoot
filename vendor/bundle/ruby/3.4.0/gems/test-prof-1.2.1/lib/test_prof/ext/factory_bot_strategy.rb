# frozen_string_literal: true

module TestProf
  # FactoryBot 5.0 uses strategy classes for associations,
  # older versions and top-level invocations use Symbols.
  #
  # This Refinement should be used FactoryRunner patches to check
  # that strategy is :create.
  module FactoryBotStrategy
    refine Symbol do
      def create?
        self == :create
      end
    end

    if defined?(::FactoryBot::Strategy::Create)
      refine Class do
        def create?
          self <= ::FactoryBot::Strategy::Create
        end
      end
    end
  end
end
