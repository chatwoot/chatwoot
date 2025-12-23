# frozen_string_literal: true

require "dry/initializer"

module Dry
  module Schema
    # Processes input data using objects configured within the DSL
    # Processing is split into steps represented by `ProcessorSteps`.
    #
    # @see ProcessorSteps
    # @see Params
    # @see JSON
    #
    # @api public
    class Processor
      extend ::Dry::Initializer
      extend ::Dry::Configurable

      include ::Dry::Logic::Operators

      setting :key_map_type
      setting :type_registry_namespace, default: :strict
      setting :filter_empty_string, default: false

      option :steps, default: -> { ProcessorSteps.new }

      option :schema_dsl

      class << self
        # Return DSL configured via #define
        #
        # @return [DSL]
        # @api private
        attr_reader :definition

        # Define a schema for your processor class
        #
        # @see Schema#define
        # @see Schema#Params
        # @see Schema#JSON
        #
        # @return [Class]
        #
        # @api public
        def define(&)
          @definition ||= DSL.new(
            processor_type: self, parent: superclass.definition, **config.to_h, &
          )
          self
        end

        # Build a new processor object
        #
        # @return [Processor]
        #
        # @api public
        def new(options = nil)
          if options || block_given?
            processor = super(**(options || EMPTY_HASH))
            yield(processor) if block_given?
            processor
          elsif definition
            definition.call
          else
            raise ::ArgumentError, "Cannot create a schema without a definition"
          end
        end
      end

      # Apply processing steps to the provided input
      #
      # @param [Hash] input
      #
      # @return [Result]
      #
      # @api public
      def call(input)
        Result.new(input.dup, message_compiler: message_compiler) do |result|
          steps.call(result)
        end
      end
      alias_method :[], :call

      # @api public
      def xor(_other)
        raise ::NotImplementedError, "composing schemas using `xor` operator is not supported yet"
      end
      alias_method :^, :xor

      # Merge with another schema
      #
      # @param [Processor] other
      #
      # @return [Processor, Params, JSON]
      #
      # @api public
      def merge(other)
        schema_dsl.merge(other.schema_dsl).()
      end

      # Return a proc that acts like a schema object
      #
      # @return [Proc]
      #
      # @api public
      def to_proc
        ->(input) { call(input) }
      end

      # Return string representation
      #
      # @return [String]
      #
      # @api public
      def inspect
        <<~STR.strip
          #<#{self.class.name} keys=#{key_map.map(&:dump)} rules=#{rules.transform_values(&:to_s)}>
        STR
      end

      # Return the key map
      #
      # @return [KeyMap]
      #
      # @api public
      def key_map
        steps.key_map
      end

      # Return the type schema
      #
      # @return [Dry::Types::Lax]
      #
      # @api private
      def type_schema
        steps.type_schema
      end

      # Return type schema used when composing subschemas
      #
      # @return [Dry::Types::Schema]
      #
      # @api private
      def strict_type_schema
        schema_dsl.strict_type_schema
      end

      # Return the rule applier
      #
      # @api private
      def rule_applier
        steps.rule_applier
      end
      alias_method :to_rule, :rule_applier

      # Return the rules config
      #
      # @return [Dry::Types::Config]
      #
      # @api private
      def config
        @config ||= rule_applier.config
      end

      # Return AST representation of the rules
      #
      # @api private
      def to_ast(*)
        rule_applier.to_ast
      end
      alias_method :ast, :to_ast

      # Return the message compiler
      #
      # @return [MessageCompiler]
      #
      # @api private
      def message_compiler
        rule_applier.message_compiler
      end

      # Return the rules from rule applier
      #
      # @return [MessageCompiler]
      #
      # @api private
      def rules
        rule_applier.rules
      end

      # Return the types from the schema DSL
      #
      # @api private
      def types
        schema_dsl.types
      end

      # Check if there are filter rules
      #
      # @api private
      def filter_rules?
        @filter_rules_predicate ||= schema_dsl.filter_rules?
      end

      # Return filter schema
      #
      # @api private
      def filter_schema
        @filter_schema ||= schema_dsl.filter_schema
      end
    end
  end
end
