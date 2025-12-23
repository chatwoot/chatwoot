# frozen_string_literal: true

require "dry/initializer"
require "dry/schema/constants"

module Dry
  module Schema
    # The schema definition DSL class
    #
    # The DSL is exposed by:
    #   - `Schema.define`
    #   - `Schema.Params`
    #   - `Schema.JSON`
    #   - `Schema::Params.define` - use with sub-classes
    #   - `Schema::JSON.define` - use with sub-classes
    #
    # @example class-based definition
    #   class UserSchema < Dry::Schema::Params
    #     define do
    #       required(:name).filled
    #       required(:age).filled(:integer, gt: 18)
    #     end
    #   end
    #
    #   user_schema = UserSchema.new
    #   user_schema.(name: 'Jame', age: 21)
    #
    # @example instance-based definition shortcut
    #   UserSchema = Dry::Schema.Params do
    #     required(:name).filled
    #     required(:age).filled(:integer, gt: 18)
    #   end
    #
    #   UserSchema.(name: 'Jame', age: 21)
    #
    # @api public
    class DSL
      Types = Schema::Types

      extend ::Dry::Initializer

      # @return [Compiler] The type of the processor (Params, JSON, or a custom sub-class)
      option :processor_type, default: -> { Processor }

      # @return [Array] An array with macros defined within the DSL
      option :macros, default: -> { EMPTY_ARRAY.dup }

      # @return [Compiler] A key=>type map defined within the DSL
      option :types, default: -> { EMPTY_HASH.dup }

      # @return [Array] Optional parent DSL objects, that will be used to merge keys and rules
      option :parent, Types::Coercible::Array, default: -> { EMPTY_ARRAY.dup }, as: :parents

      # @return [Config] Configuration object exposed via `#configure` method
      option :config, optional: true, default: proc { default_config }

      # @return [ProcessorSteps] Steps for the processor
      option :steps, default: proc { ProcessorSteps.new }

      # @return [Path, Array] Path under which the schema is defined
      option :path, -> *args { Path[*args] if args.any? }, default: proc { EMPTY_ARRAY }

      # Build a new DSL object and evaluate provided block
      #
      # @param [Hash] options
      # @option options [Class] :processor The processor type
      #                                    (`Params`, `JSON` or a custom sub-class)
      # @option options [Compiler] :compiler An instance of a rule compiler
      #                                      (must be compatible with `Schema::Compiler`) (optional)
      # @option options [Array[DSL]] :parent One or more instances of the parent DSL (optional)
      # @option options [Config] :config A configuration object (optional)
      #
      # @see Schema.define
      # @see Schema.Params
      # @see Schema.JSON
      # @see Processor.define
      #
      # @return [DSL]
      #
      # @api public
      def self.new(**options, &)
        dsl = super
        dsl.instance_eval(&) if block_given?
        dsl.instance_variable_set("@compiler", options[:compiler]) if options[:compiler]
        dsl
      end

      # Provide customized configuration for your schema
      #
      # @example
      #   Dry::Schema.define do
      #     configure do |config|
      #       config.messages.backend = :i18n
      #     end
      #   end
      #
      # @see Config
      #
      # @return [DSL]
      #
      # @api public
      def configure(&)
        config.configure(&)
        self
      end

      # @api private
      def compiler
        @compiler ||= Compiler.new(predicates)
      end

      # @api private
      def predicates
        @predicates ||= config.predicates
      end

      # Return a macro with the provided name
      #
      # @param [Symbol] name
      #
      # @return [Macros::Core]
      #
      # @api public
      def [](name)
        macros.detect { |macro| macro.name.equal?(name) }
      end

      # Define a required key
      #
      # @example
      #   required(:name).filled
      #
      #   required(:age).value(:integer)
      #
      #   required(:user_limit).value(:integer, gt?: 0)
      #
      #   required(:tags).filled { array? | str? }
      #
      # @param [Symbol] name The key name
      #
      # @return [Macros::Required]
      #
      # @api public
      def required(name, &)
        key(name, macro: Macros::Required, &)
      end

      # Define an optional key
      #
      # This works exactly the same as `required` except that if a key is not present
      # rules will not be applied
      #
      # @see DSL#required
      #
      # @param [Symbol] name The key name
      #
      # @return [Macros::Optional]
      #
      # @api public
      def optional(name, &)
        key(name, macro: Macros::Optional, &)
      end

      # A generic method for defining keys
      #
      # @param [Symbol] name The key name
      # @param [Class] macro The macro sub-class (ie `Macros::Required` or
      #                      any other `Macros::Key` subclass)
      #
      # @return [Macros::Key]
      #
      # @api public
      def key(name, macro:, &)
        raise ArgumentError, "Key +#{name}+ is not a symbol" unless name.is_a?(::Symbol)

        set_type(name, Types::Any.meta(default: true))

        macro = macro.new(
          name: name,
          compiler: compiler,
          schema_dsl: self,
          filter_schema_dsl: filter_schema_dsl
        )

        macro.value(&) if block_given?
        macros << macro
        macro
      end

      # Build a processor based on DSL's definitions
      #
      # @return [Processor, Params, JSON]
      #
      # @api private
      def call
        all_steps = parents.map(&:steps) + [steps]

        result_steps = all_steps.inject { |result, steps| result.merge(steps) }

        result_steps[:key_validator] = key_validator if config.validate_keys
        result_steps[:key_coercer] = key_coercer
        result_steps[:value_coercer] = value_coercer
        result_steps[:rule_applier] = rule_applier
        result_steps[:filter_schema] = filter_schema.rule_applier if filter_rules?

        processor_type.new(schema_dsl: self, steps: result_steps)
      end

      # Merge with another dsl
      #
      # @return [DSL]
      #
      # @api private
      def merge(other)
        new(
          parent: parents + other.parents,
          macros: macros + other.macros,
          types: types.merge(other.types),
          steps: steps.merge(other.steps)
        )
      end

      # Cast this DSL into a rule object
      #
      # @return [RuleApplier]
      def to_rule
        call.to_rule
      end

      # A shortcut for defining an array type with a member
      #
      # @example
      #   required(:tags).filled(array[:string])
      #
      # @return [Dry::Types::Array::Member]
      #
      # @api public
      def array
        -> member_type { type_registry["array"].of(resolve_type(member_type)) }
      end

      # Method allows steps injection to the processor
      #
      # @example
      #   before(:rule_applier) do |input|
      #     input.compact
      #   end
      #
      # @return [DSL]
      #
      # @api public
      def before(key, &)
        steps.before(key, &)
        self
      end

      # Method allows steps injection to the processor
      #
      # @example
      #   after(:rule_applier) do |input|
      #     input.compact
      #   end
      #
      # @return [DSL]
      #
      # @api public
      def after(key, &)
        steps.after(key, &)
        self
      end

      # The parent (last from parents) which is used for copying non mergeable configuration
      #
      # @return DSL
      #
      # @api public
      def parent
        @parent ||= parents.last
      end

      # Return type schema used by the value coercer
      #
      # @return [Dry::Types::Lax]
      #
      # @api private
      def type_schema
        strict_type_schema.lax
      end

      # Return type schema used when composing subschemas
      #
      # @return [Dry::Types::Schema]
      #
      # @api private
      def strict_type_schema
        type_registry["hash"].schema(types)
      end

      # Return a new DSL instance using the same processor type
      #
      # @return [Dry::Types::Safe]
      #
      # @api private
      def new(klass: self.class, **options, &)
        klass.new(**options, processor_type: processor_type, config: config, &)
      end

      # Set a type for the given key name
      #
      # @param [Symbol] name The key name
      # @param [Symbol, Array<Symbol>, Dry::Types::Type] spec The type spec or a type object
      #
      # @return [Dry::Types::Safe]
      #
      # @api private
      def set_type(name, spec)
        type = resolve_type(spec)
        meta = {required: false, maybe: type.optional?}

        @types[name] = type.meta(meta)
      end

      # Check if a custom type was set under provided key name
      #
      # @return [Bool]
      #
      # @api private
      def custom_type?(name)
        !types[name].meta[:default].equal?(true)
      end

      # Resolve type object from the provided spec
      #
      # @param [Symbol, Array<Symbol>, Dry::Types::Type] spec
      #
      # @return [Dry::Types::Type]
      #
      # @api private
      def resolve_type(spec)
        case spec
        when ::Dry::Types::Type then spec
        when ::Array then spec.map { |s| resolve_type(s) }.reduce(:|)
        else
          type_registry[spec]
        end
      end

      # @api private
      def filter_schema
        filter_schema_dsl.call
      end

      # Build an input schema DSL used by `filter` API
      #
      # @see Macros::Value#filter
      #
      # @api private
      def filter_schema_dsl
        @filter_schema_dsl ||= new(parent: parent_filter_schemas)
      end

      # Check if any filter rules were defined
      #
      # @api private
      def filter_rules?
        if instance_variable_defined?("@filter_schema_dsl") && !filter_schema_dsl.macros.empty?
          return true
        end

        parents.any?(&:filter_rules?)
      end

      # This DSL's type map merged with any parent type maps
      #
      # @api private
      def types
        [*parents.map(&:types), @types].reduce(:merge)
      end

      # @api private
      def merge_types(op_class, lhs, rhs)
        types_merger.(op_class, lhs, rhs)
      end

      protected

      # Build a rule applier
      #
      # @return [RuleApplier]
      #
      # @api protected
      def rule_applier
        RuleApplier.new(rules, config: config.finalize!)
      end

      # Build rules from defined macros
      #
      # @see #rule_applier
      #
      # @api protected
      def rules
        parent_rules.merge(macros.to_h { [_1.name, _1.to_rule] }.compact)
      end

      # Build a key map from defined types
      #
      # @api protected
      def key_map(types = self.types)
        keys = types.map { |key, type| key_spec(key, type) }
        km = KeyMap.new(keys)

        if key_map_type
          km.public_send(key_map_type)
        else
          km
        end
      end

      private

      # @api private
      def parent_filter_schemas
        parents.select(&:filter_rules?).map(&:filter_schema)
      end

      # Build a key validator
      #
      # @return [KeyValidator]
      #
      # @api private
      def key_validator
        KeyValidator.new(key_map: key_map)
      end

      # Build a key coercer
      #
      # @return [KeyCoercer]
      #
      # @api private
      def key_coercer
        KeyCoercer.symbolized(key_map)
      end

      # Build a value coercer
      #
      # @return [ValueCoercer]
      #
      # @api private
      def value_coercer
        ValueCoercer.new(type_schema)
      end

      # Return type registry configured by the processor type
      #
      # @api private
      def type_registry
        @type_registry ||= TypeRegistry.new(
          config.types,
          processor_type.config.type_registry_namespace
        )
      end

      # Return key map type configured by the processor type
      #
      # @api private
      def key_map_type
        processor_type.config.key_map_type
      end

      # Build a key spec needed by the key map
      #
      # TODO: we need a key-map compiler using Types AST
      #
      # @api private
      def key_spec(name, type)
        if type.respond_to?(:keys)
          {name => key_map(type.name_key_map)}
        elsif type.respond_to?(:member)
          kv = key_spec(name, type.member)
          kv.equal?(name) ? name : kv.flatten(1)
        elsif type.meta[:maybe] && type.respond_to?(:right)
          key_spec(name, type.right)
        elsif type.respond_to?(:type)
          key_spec(name, type.type)
        else
          name
        end
      end

      # @api private
      def parent_rules
        parents.reduce({}) { |rules, parent| rules.merge(parent.rules) }
      end

      # @api private
      def parent_key_map
        parents.reduce([]) { |key_map, parent| parent.key_map + key_map }
      end

      # @api private
      def default_config
        parents.each_cons(2) do |left, right|
          unless left.config == right.config
            raise ::ArgumentError,
                  "Parent configs differ, left=#{left.inspect}, right=#{right.inspect}"
          end
        end

        (parent || Schema).config.dup
      end

      def types_merger
        @types_merger ||= TypesMerger.new(type_registry)
      end
    end
  end
end
