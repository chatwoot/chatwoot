# frozen_string_literal: true

module TestProf
  module BeforeAll
    # Disable Isolator within before_all blocks
    module Isolator
      def begin_transaction(*)
        ::Isolator.transactions_threshold += 1
        super
      end

      def rollback_transaction(*)
        super
        ::Isolator.transactions_threshold -= 1
      end
    end
  end
end

TestProf::BeforeAll.singleton_class.prepend(TestProf::BeforeAll::Isolator)
