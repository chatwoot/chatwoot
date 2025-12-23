# frozen_string_literal: true

require "dry/types/builder_methods"

module Dry
  module Types
    # Export types registered in a container as module constants.
    # @example
    #   module Types
    #     include Dry.Types(:strict, :coercible, :nominal, default: :strict)
    #   end
    #
    #   Types.constants
    #   # => [:Class, :Strict, :Symbol, :Integer, :Float, :String, :Array, :Hash,
    #   #     :Decimal, :Nil, :True, :False, :Bool, :Date, :Nominal, :DateTime, :Range,
    #   #     :Coercible, :Time]
    #
    # @api public
    class Module < ::Module
      def initialize(registry, *args, **kwargs)
        @registry = registry
        check_parameters(*args, **kwargs)
        constants = type_constants(*args, **kwargs)
        define_constants(constants)
        extend(BuilderMethods)

        if constants.key?(:Nominal)
          singleton_class.define_method(:included) do |base|
            super(base)
            base.instance_exec(const_get(:Nominal, false)) do |nominal|
              extend Dry::Core::Deprecations[:"dry-types"]
              const_set(:Definition, nominal)
              deprecate_constant(:Definition, message: "Nominal")
            end
          end
        end
      end

      # @api private
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/PerceivedComplexity
      def type_constants(*namespaces, default: Undefined, **aliases)
        if namespaces.empty? && aliases.empty? && Undefined.equal?(default)
          default_ns = :Strict
        elsif Undefined.equal?(default)
          default_ns = Undefined
        else
          default_ns = Types::Inflector.camelize(default).to_sym
        end

        tree = registry_tree

        if namespaces.empty? && aliases.empty?
          modules = tree.select { _2.is_a?(::Hash) }.map(&:first)
        else
          modules = (namespaces + aliases.keys).map { |n|
            Types::Inflector.camelize(n).to_sym
          }
        end

        tree.each_with_object({}) do |(key, value), constants|
          if modules.include?(key)
            name = aliases.fetch(Inflector.underscore(key).to_sym, key)
            constants[name] = value
          end

          constants.update(value) if key == default_ns
        end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/PerceivedComplexity

      # @api private
      def registry_tree
        @registry_tree ||= @registry.keys.each_with_object({}) { |key, tree|
          type = @registry[key]
          *modules, const_name = key.split(".").map { |part|
            Types::Inflector.camelize(part).to_sym
          }
          next if modules.empty?

          modules.reduce(tree) { |br, name| br[name] ||= {} }[const_name] = type
        }.freeze
      end

      private

      # @api private
      def check_parameters(*namespaces, default: Undefined, **aliases)
        referenced = namespaces.dup
        referenced << default unless false.equal?(default) || Undefined.equal?(default)
        referenced.concat(aliases.keys)

        known = @registry.keys.map { |k|
          ns, *path = k.split(".")
          ns.to_sym unless path.empty?
        }.compact.uniq

        unknown = (referenced.uniq - known).first

        if unknown
          raise ::ArgumentError,
                "#{unknown.inspect} is not a known type namespace. " \
                "Supported options are #{known.map(&:inspect).join(", ")}"
        end
      end

      # @api private
      def define_constants(constants, mod = self)
        constants.each do |name, value|
          case value
          when ::Hash
            if mod.const_defined?(name, false)
              define_constants(value, mod.const_get(name, false))
            else
              m = ::Module.new
              mod.const_set(name, m)
              define_constants(value, m)
            end
          else
            mod.const_set(name, value)
          end
        end
      end
    end
  end
end
