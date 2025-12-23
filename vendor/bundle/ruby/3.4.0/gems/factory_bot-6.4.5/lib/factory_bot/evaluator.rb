require "active_support/core_ext/hash/except"
require "active_support/core_ext/class/attribute"

module FactoryBot
  # @api private
  class Evaluator
    class_attribute :attribute_lists

    private_instance_methods.each do |method|
      undef_method(method) unless method.match?(/^__|initialize/)
    end

    def initialize(build_strategy, overrides = {})
      @build_strategy = build_strategy
      @overrides = overrides
      @cached_attributes = overrides
      @instance = nil

      @overrides.each do |name, value|
        singleton_class.define_attribute(name) { value }
      end
    end

    def association(factory_name, *traits_and_overrides)
      overrides = traits_and_overrides.extract_options!
      strategy_override = overrides.fetch(:strategy) {
        FactoryBot.use_parent_strategy ? @build_strategy.to_sym : :create
      }

      traits_and_overrides += [overrides.except(:strategy)]

      runner = FactoryRunner.new(factory_name, strategy_override, traits_and_overrides)
      @build_strategy.association(runner)
    end

    attr_accessor :instance

    def method_missing(method_name, ...)
      if @instance.respond_to?(method_name)
        @instance.send(method_name, ...)
      else
        SyntaxRunner.new.send(method_name, ...)
      end
    end

    def respond_to_missing?(method_name, _include_private = false)
      @instance.respond_to?(method_name) || SyntaxRunner.new.respond_to?(method_name)
    end

    def __override_names__
      @overrides.keys
    end

    def increment_sequence(sequence)
      sequence.next(self)
    end

    def self.attribute_list
      AttributeList.new.tap do |list|
        attribute_lists.each do |attribute_list|
          list.apply_attributes attribute_list.to_a
        end
      end
    end

    def self.define_attribute(name, &block)
      if instance_methods(false).include?(name) || private_instance_methods(false).include?(name)
        undef_method(name)
      end

      define_method(name) do
        if @cached_attributes.key?(name)
          @cached_attributes[name]
        else
          @cached_attributes[name] = instance_exec(&block)
        end
      end
    end
  end
end
