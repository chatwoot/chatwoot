# frozen_string_literal: true

require "dry/initializer"
require "dry/schema/constants"

module Dry
  module Schema
    # Steps for the Dry::Schema::Processor
    #
    # There are 4 main steps:
    #
    #   1. `key_coercer` - Prepare input hash using a key map
    #   2. `filter_schema` - Apply pre-coercion filtering rules
    #      (optional step, used only when `filter` was used)
    #   3. `value_coercer` - Apply value coercions based on type specifications
    #   4. `rule_applier` - Apply rules
    #
    # @see Processor
    #
    # @api public
    class ProcessorSteps
      extend ::Dry::Initializer

      option :steps, default: -> { EMPTY_HASH.dup }
      option :before_steps, default: -> { EMPTY_HASH.dup }
      option :after_steps, default: -> { EMPTY_HASH.dup }

      # Executes steps and callbacks in order
      #
      # @param [Result] result
      #
      # @return [Result]
      #
      # @api public
      def call(result)
        STEPS_IN_ORDER.each do |name|
          before_steps[name]&.each { |step| step&.(result) }
          steps[name]&.(result)
          after_steps[name]&.each { |step| step&.(result) }
        end

        result
      end

      # @api private
      def rule_applier
        @rule_applier ||= steps[:rule_applier].executor
      end

      # @api private
      def key_map
        @key_map ||= self[:key_coercer].executor.key_map
      end

      # @api private
      def type_schema
        @type_schema ||= steps[:value_coercer].executor.type_schema
      end

      # Returns step by name
      #
      # @param [Symbol] name The step name
      #
      # @api public
      def [](name)
        steps[name]
      end

      # Sets step by name
      #
      # @param [Symbol] name The step name
      #
      # @api public
      def []=(name, value)
        steps[name] = Step.new(type: :core, name: name, executor: value)
      end

      # Add passed block before mentioned step
      #
      # @param [Symbol] name The step name
      #
      # @return [ProcessorSteps]
      #
      # @api public
      def after(name, &block)
        after_steps[name] ||= EMPTY_ARRAY.dup
        after_steps[name] << Step.new(type: :after, name: name, executor: block)
        after_steps[name].sort_by!(&:path)
        self
      end

      # Add passed block before mentioned step
      #
      # @param [Symbol] name The step name
      #
      # @return [ProcessorSteps]
      #
      # @api public
      def before(name, &block)
        before_steps[name] ||= EMPTY_ARRAY.dup
        before_steps[name] << Step.new(type: :before, name: name, executor: block)
        before_steps[name].sort_by!(&:path)
        self
      end

      # Stacks callback steps and returns new ProcessorSteps instance
      #
      # @param [ProcessorSteps] other
      #
      # @return [ProcessorSteps]
      #
      # @api public
      def merge(other)
        ProcessorSteps.new(
          before_steps: merge_callbacks(before_steps, other.before_steps),
          after_steps: merge_callbacks(after_steps, other.after_steps)
        )
      end

      # @api private
      def merge_callbacks(left, right)
        left.merge(right) do |_key, oldval, newval|
          (oldval + newval).sort_by(&:path)
        end
      end

      # @api private
      def import_callbacks(path, other)
        other.before_steps.each do |name, steps|
          before_steps[name] ||= []
          before_steps[name].concat(steps.map { |step| step.scoped(path) }).sort_by!(&:path)
        end

        other.after_steps.each do |name, steps|
          after_steps[name] ||= []
          after_steps[name].concat(steps.map { |step| step.scoped(path) }).sort_by!(&:path)
        end
      end
    end
  end
end
