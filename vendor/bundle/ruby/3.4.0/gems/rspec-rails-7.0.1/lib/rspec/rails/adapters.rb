require 'delegate'
require 'active_support'
require 'active_support/concern'
require 'active_support/core_ext/string'

module RSpec
  module Rails
    # @private
    def self.disable_testunit_autorun
      # `Test::Unit::AutoRunner.need_auto_run=` was introduced to the test-unit
      # gem in version 2.4.9. Previous to this version `Test::Unit.run=` was
      # used. The implementation of test-unit included with Ruby has neither
      # method.
      if defined?(Test::Unit::AutoRunner.need_auto_run = ())
        Test::Unit::AutoRunner.need_auto_run = false
      elsif defined?(Test::Unit.run = ())
        Test::Unit.run = false
      end
    end
    private_class_method :disable_testunit_autorun

    if defined?(Kernel.gem)
      gem 'minitest'
    else
      require 'minitest'
    end
    require 'minitest/assertions'
    # Constant aliased to either Minitest or TestUnit, depending on what is
    # loaded.
    Assertions = Minitest::Assertions

    # @private
    class AssertionDelegator < Module
      def initialize(*assertion_modules)
        assertion_class = Class.new(SimpleDelegator) do
          include ::RSpec::Rails::Assertions
          include ::RSpec::Rails::MinitestCounters
          assertion_modules.each { |mod| include mod }
        end

        super() do
          define_method :build_assertion_instance do
            assertion_class.new(self)
          end

          def assertion_instance
            @assertion_instance ||= build_assertion_instance
          end

          assertion_modules.each do |mod|
            mod.public_instance_methods.each do |method|
              next if method == :method_missing || method == "method_missing"

              define_method(method.to_sym) do |*args, &block|
                assertion_instance.send(method.to_sym, *args, &block)
              end
            end
          end
        end
      end
    end

    # Adapts example groups for `Minitest::Test::LifecycleHooks`
    #
    # @private
    module MinitestLifecycleAdapter
      extend ActiveSupport::Concern

      included do |group|
        group.before { after_setup }
        group.after  { before_teardown }

        group.around do |example|
          before_setup
          example.run
          after_teardown
        end
      end

      def before_setup
      end

      def after_setup
      end

      def before_teardown
      end

      def after_teardown
      end
    end

    # @private
    module MinitestCounters
      attr_writer :assertions
      def assertions
        @assertions ||= 0
      end
    end

    # @private
    module SetupAndTeardownAdapter
      extend ActiveSupport::Concern

      module ClassMethods
        # Wraps `setup` calls from within Rails' testing framework in `before`
        # hooks.
        def setup(*methods, &block)
          methods.each do |method|
            if method.to_s =~ /^setup_(with_controller|fixtures|controller_request_and_response)$/
              prepend_before { __send__ method }
            else
              before         { __send__ method }
            end
          end
          before(&block) if block
        end

        # @api private
        #
        # Wraps `teardown` calls from within Rails' testing framework in
        # `after` hooks.
        def teardown(*methods, &block)
          methods.each { |method| after { __send__ method } }
          after(&block) if block
        end
      end

      def initialize(*args)
        super
        @example = nil
      end

      def method_name
        @example
      end
    end

    # @private
    module MinitestAssertionAdapter
      extend ActiveSupport::Concern

      # @private
      module ClassMethods
        # Returns the names of assertion methods that we want to expose to
        # examples without exposing non-assertion methods in Test::Unit or
        # Minitest.
        def assertion_method_names
          ::RSpec::Rails::Assertions
            .public_instance_methods
            .select do |m|
              m.to_s =~ /^(assert|flunk|refute)/
            end
        end

        def define_assertion_delegators
          assertion_method_names.each do |m|
            define_method(m.to_sym) do |*args, &block|
              assertion_delegator.send(m.to_sym, *args, &block)
            end
          end
        end
      end

      class AssertionDelegator
        include ::RSpec::Rails::Assertions
        include ::RSpec::Rails::MinitestCounters
      end

      def assertion_delegator
        @assertion_delegator ||= AssertionDelegator.new
      end

      included do
        define_assertion_delegators
      end
    end

    # Backwards compatibility. It's unlikely that anyone is using this
    # constant, but we had forgotten to mark it as `@private` earlier
    #
    # @private
    TestUnitAssertionAdapter = MinitestAssertionAdapter

    # @private
    module TaggedLoggingAdapter
      private
      # Vendored from activesupport/lib/active_support/testing/tagged_logging.rb
      # This implements the tagged_logger method where it is expected, but
      # doesn't call `name` or set it up like Rails does.
      def tagged_logger
        @tagged_logger ||= (defined?(Rails.logger) && Rails.logger)
      end
    end
  end
end
