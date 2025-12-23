# frozen_string_literal: true

require "test_prof/before_all"

module TestProf
  module BeforeAll
    # Helper to wrap the whole example group into a transaction
    module RSpec
      def before_all(setup_fixtures: BeforeAll.config.setup_fixtures, &block)
        raise ArgumentError, "Block is required!" unless block

        if within_before_all?
          before(:all) do
            @__inspect_output = "before_all hook"
            ::RSpec.current_scope = :before_all if ::RSpec.respond_to?(:current_scope=)
            instance_eval(&block)
          end
          return
        end

        @__before_all_activation__ = context = self
        current_metadata = metadata

        before(:all) do
          @__inspect_output = "before_all hook"
          ::RSpec.current_scope = :before_all if ::RSpec.respond_to?(:current_scope=)
          BeforeAll.setup_fixtures(self) if setup_fixtures
          BeforeAll.begin_transaction(context, current_metadata) do
            instance_eval(&block)
          end
        end

        after(:all) do
          BeforeAll.rollback_transaction(context, current_metadata)
        end
      end

      def within_before_all?
        instance_variable_defined?(:@__before_all_activation__)
      end
    end
  end
end

RSpec::Core::ExampleGroup.extend TestProf::BeforeAll::RSpec
