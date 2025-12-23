# frozen_string_literal: true

module Dry
  module Initializer
    #
    # Gem-related configuration of some class
    #
    class Config
      # @!attribute [r] null
      # @return [Dry::Initializer::UNDEFINED, nil] value of unassigned variable

      # @!attribute [r] extended_class
      # @return [Class] the class whose config collected by current object

      # @!attribute [r] parent
      # @return [Dry::Initializer::Config] parent configuration

      # @!attribute [r] definitions
      # @return [Hash<Symbol, Dry::Initializer::Definition>]
      #   hash of attribute definitions with their source names

      attr_reader :null, :extended_class, :parent, :definitions

      # @!attribute [r] mixin
      # @return [Module] reference to the module to be included into class
      def mixin
        @mixin ||= Module.new.tap do |mod|
          initializer = self
          mod.extend(Mixin::Local)
          mod.define_method(:__dry_initializer_config__) do
            initializer
          end
          mod.send :private, :__dry_initializer_config__
        end
      end

      # List of configs of all subclasses of the [#extended_class]
      # @return [Array<Dry::Initializer::Config>]
      def children
        @children ||= Set.new
      end

      # List of definitions for initializer params
      # @return [Array<Dry::Initializer::Definition>]
      def params
        definitions.values.reject(&:option)
      end

      # List of definitions for initializer options
      # @return [Array<Dry::Initializer::Definition>]
      def options
        definitions.values.select(&:option)
      end

      # Adds or redefines a parameter
      # @param  [Symbol]       name
      # @param  [#call, nil]   type (nil)
      # @option opts [Proc]    :default
      # @option opts [Boolean] :optional
      # @option opts [Symbol]  :as
      # @option opts [true, false, :protected, :public, :private] :reader
      # @return [self] itself
      def param(name, type = nil, **opts, &block)
        add_definition(false, name, type, block, **opts)
      end

      # Adds or redefines an option of [#dry_initializer]
      #
      # @param  (see #param)
      # @option (see #param)
      # @return (see #param)
      #
      def option(name, type = nil, **opts, &block)
        add_definition(true, name, type, block, **opts)
      end

      # The hash of public attributes for an instance of the [#extended_class]
      # @param  [Dry::Initializer::Instance] instance
      # @return [Hash<Symbol, Object>]
      def public_attributes(instance)
        definitions.values.each_with_object({}) do |item, obj|
          key = item.target
          next unless instance.respond_to? key

          val = instance.send(key)
          obj[key] = val unless null == val
        end
      end

      # The hash of assigned attributes for an instance of the [#extended_class]
      # @param  [Dry::Initializer::Instance] instance
      # @return [Hash<Symbol, Object>]
      def attributes(instance)
        definitions.values.each_with_object({}) do |item, obj|
          key = item.target
          val = instance.send(:instance_variable_get, item.ivar)
          obj[key] = val unless null == val
        end
      end

      # Code of the `#__initialize__` method
      # @return [String]
      def code
        Builders::Initializer[self]
      end

      # Finalizes config
      # @return [self]
      def finalize
        @definitions = final_definitions
        check_order_of_params
        mixin.class_eval(code, "#{__FILE__}:#{__LINE__} class_eval")
        children.each(&:finalize)
        self
      end

      # Human-readable representation of configured params and options
      # @return [String]
      def inch
        line  =  Builders::Signature[self]
        line  =  line.gsub("__dry_initializer_options__", "options")
        lines =  ["@!method initialize(#{line})"]
        lines += ["Initializes an instance of #{extended_class}"]
        lines += definitions.values.map(&:inch)
        lines += ["@return [#{extended_class}]"]
        lines.join("\n")
      end

      private

      def initialize(extended_class = nil, null: UNDEFINED)
        @extended_class = extended_class.tap { |klass| klass&.include mixin }
        sklass          = extended_class&.superclass
        @parent         = sklass.dry_initializer if sklass.is_a? Dry::Initializer
        @null           = null || parent&.null
        @definitions    = {}
        finalize
      end

      def add_definition(option, name, type, block, **opts)
        opts = {
          parent: extended_class,
          option:,
          null:,
          source: name,
          type:,
          block:,
          **opts
        }

        options = Dispatchers.call(**opts)
        definition = Definition.new(**options)
        definitions[definition.source] = definition
        finalize
        mixin.class_eval definition.code
      end

      def final_definitions
        parent_definitions = Hash(parent&.definitions&.dup)
        definitions.each_with_object(parent_definitions) do |(key, val), obj|
          obj[key] = check_type(obj[key], val)
        end
      end

      def check_type(previous, current)
        return current unless previous
        return current if previous.option == current.option

        raise SyntaxError,
              "cannot reload #{previous} of #{extended_class.superclass}" \
              " by #{current} of its subclass #{extended_class}"
      end

      def check_order_of_params
        params.inject(nil) do |optional, current|
          if current.optional
            current
          elsif optional
            raise SyntaxError, "#{extended_class}: required #{current}" \
                               " goes after optional #{optional}"
          else
            optional
          end
        end
      end
    end
  end
end
