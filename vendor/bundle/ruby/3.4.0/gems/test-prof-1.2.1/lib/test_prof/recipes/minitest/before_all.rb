# frozen_string_literal: true

require "test_prof/before_all"

Minitest.singleton_class.prepend(Module.new do
  attr_reader :previous_klass
  @previous_klass = nil

  def run_one_method(klass, method_name)
    return super unless klass.respond_to?(:parallelized) && klass.parallelized

    if @previous_klass && @previous_klass != klass
      @previous_klass.before_all_executor&.deactivate!
    end
    @previous_klass = klass

    super
  end
end)

module TestProf
  module BeforeAll
    # Add before_all hook to Minitest: wrap all examples into a transaction and
    # store instance variables
    module Minitest # :nodoc: all
      class Executor
        attr_reader :active, :block, :captured_ivars, :teardown_block, :current_test_object,
          :setup_fixtures, :parent

        alias_method :active?, :active
        alias_method :setup_fixtures?, :setup_fixtures

        def initialize(setup_fixtures: false, parent: nil, &block)
          @parent = parent
          # Fixtures must be instantiated if any of the executors needs them
          @setup_fixtures = setup_fixtures || parent&.setup_fixtures
          @block = block
          @captured_ivars = []
        end

        def teardown(&block)
          @teardown_block = block
        end

        def activate!(test_object)
          @current_test_object = test_object

          return restore_ivars(test_object) if active?

          @active = true

          BeforeAll.setup_fixtures(test_object) if setup_fixtures?
          BeforeAll.begin_transaction do
            capture!(test_object)
          end
        end

        def deactivate!
          return unless active

          @active = false

          perform_teardown(current_test_object)

          @current_test_object = nil
          BeforeAll.rollback_transaction
        end

        def capture!(test_object)
          before_ivars = test_object.instance_variables

          perform_setup(test_object)

          (test_object.instance_variables - before_ivars).each do |ivar|
            captured_ivars << [ivar, test_object.instance_variable_get(ivar)]
          end
        end

        def restore_ivars(test_object)
          captured_ivars.each do |(ivar, val)|
            test_object.instance_variable_set(
              ivar,
              val
            )
          end
        end

        def perform_setup(test_object)
          parent&.perform_setup(test_object)
          test_object.instance_eval(&block) if block
        end

        def perform_teardown(test_object)
          current_test_object&.instance_eval(&teardown_block) if teardown_block
          parent&.perform_teardown(test_object)
        end
      end

      class << self
        def included(base)
          base.extend ClassMethods

          base.cattr_accessor :parallelized
          if base.respond_to?(:parallelize_teardown)
            base.parallelize_teardown do
              last_klass = ::Minitest.previous_klass
              if last_klass&.respond_to?(:parallelized) && last_klass&.parallelized
                last_klass.before_all_executor&.deactivate!
              end
            end
          end

          if base.respond_to?(:parallelize)
            base.singleton_class.prepend(Module.new do
              def parallelize(workers: :number_of_processors, with: :processes)
                # super.parallelize returns nil when no parallelization is set up
                if super(workers: workers, with: with).nil?
                  return
                end

                case with
                when :processes
                  self.parallelized = true
                when :threads
                  warn "!!! before_all is not implemented for parallalization with threads and " \
                    "could work incorrectly"
                else
                  warn "!!! tests are using an unknown parallelization strategy and before_all " \
                    "could work incorrectly"
                end
              end
            end)
          end
        end
      end

      module ClassMethods
        attr_writer :before_all_executor

        def before_all_executor
          return @before_all_executor if instance_variable_defined?(:@before_all_executor)

          @before_all_executor = if superclass.respond_to?(:before_all_executor)
            superclass.before_all_executor
          end
        end

        def before_all(setup_fixtures: BeforeAll.config.setup_fixtures, &block)
          self.before_all_executor = Executor.new(
            setup_fixtures: setup_fixtures,
            parent: before_all_executor,
            &block
          )

          # Do not add patches multiple times
          return if before_all_executor.parent

          prepend(Module.new do
            def before_setup
              self.class.before_all_executor.activate!(self)
              super
            end
          end)

          singleton_class.prepend(Module.new do
            def run(*)
              super
            ensure
              before_all_executor&.deactivate! unless parallelized
            end
          end)
        end

        def after_all(&block)
          self.before_all_executor = Executor.new(parent: before_all_executor)
          before_all_executor.teardown(&block)
        end
      end
    end
  end
end
