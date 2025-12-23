# frozen_string_literal: true

require "test_prof"

module TestProf
  # `before_all` helper configuration
  module BeforeAll
    class AdapterMissing < StandardError # :nodoc:
      MSG = "Please, provide an adapter for `before_all` " \
            "through `TestProf::BeforeAll.adapter = MyAdapter`"

      def initialize
        super(MSG)
      end
    end

    class << self
      attr_accessor :adapter

      def begin_transaction(scope = nil, metadata = [])
        raise AdapterMissing if adapter.nil?

        config.run_hooks(:begin, scope, metadata) do
          adapter.begin_transaction
        end
        yield
      end

      def rollback_transaction(scope = nil, metadata = [])
        raise AdapterMissing if adapter.nil?

        config.run_hooks(:rollback, scope, metadata) do
          adapter.rollback_transaction
        end
      end

      def setup_fixtures(test_object)
        raise ArgumentError, "Current adapter doesn't support #setup_fixtures" unless adapter.respond_to?(:setup_fixtures)

        adapter.setup_fixtures(test_object)
      end

      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end
    end

    class HookEntry # :nodoc:
      attr_reader :filters, :block

      def initialize(block:, filters: [])
        @block = block
        @filters = TestProf.rspec? ? ::RSpec::Core::Metadata.build_hash_from(filters) : filters
      end

      def run(scope, metadata)
        return unless filters_apply?(metadata)

        block.call(scope)
      end

      private

      def filters_apply?(metadata)
        return true unless filters.present? && TestProf.rspec?

        ::RSpec::Core::MetadataFilter.apply?(
          :all?,
          filters,
          metadata
        )
      end
    end

    class HooksChain # :nodoc:
      attr_reader :type, :after, :before

      def initialize(type)
        @type = type
        @before = []
        @after = []
      end

      def run(scope = nil, metadata = [])
        before.each { |hook| hook.run(scope, metadata) }
        yield
        after.each { |hook| hook.run(scope, metadata) }
      end
    end

    class Configuration
      HOOKS = %i[begin rollback].freeze

      attr_accessor :setup_fixtures

      def initialize
        @hooks = Hash.new { |h, k| h[k] = HooksChain.new(k) }
        @setup_fixtures = false
      end

      # Add `before` hook for `begin` or
      # `rollback` operation with optional filters:
      #
      #   config.before(:rollback, foo: :bar) { ... }
      def before(type, *filters, &block)
        validate_hook_type!(type)
        hooks[type].before << HookEntry.new(block: block, filters: filters) if block
      end

      # Add `after` hook for `begin` or
      # `rollback` operation with optional filters:
      #
      #   config.after(:begin, foo: :bar) { ... }
      def after(type, *filters, &block)
        validate_hook_type!(type)
        hooks[type].after << HookEntry.new(block: block, filters: filters) if block
      end

      def run_hooks(type, scope = nil, metadata = []) # :nodoc:
        validate_hook_type!(type)
        hooks[type].run(scope, metadata) { yield }
      end

      private

      def validate_hook_type!(type)
        return if HOOKS.include?(type)

        raise ArgumentError, "Unknown hook type: #{type}. Valid types: #{HOOKS.join(", ")}"
      end

      attr_reader :hooks
    end
  end
end

if defined?(::ActiveRecord::Base)
  require "test_prof/before_all/adapters/active_record"

  TestProf::BeforeAll.adapter = TestProf::BeforeAll::Adapters::ActiveRecord
end

if defined?(::Isolator)
  require "test_prof/before_all/isolator"
end
