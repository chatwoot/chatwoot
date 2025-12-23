# frozen_string_literal: true

require "bigdecimal"
require "date"
require "set"
require "zeitwerk"

require "concurrent/map"

require "dry/core"
require "dry/logic"

require "dry/types/constraints"
require "dry/types/errors"
require "dry/types/version"

# This must be required explicitly as it may conflict with dry-inflector
require "dry/types/inflector"
require "dry/types/module"

module Dry
  # Main library namespace
  #
  # @api public
  module Types
    extend ::Dry::Core::Extensions
    extend ::Dry::Core::ClassAttributes
    extend ::Dry::Core::Deprecations[:"dry-types"]
    include ::Dry::Core::Constants

    TYPE_SPEC_REGEX = /(.+)<(.+)>/

    def self.loader
      @loader ||= ::Zeitwerk::Loader.new.tap do |loader|
        root = ::File.expand_path("..", __dir__)
        loader.tag = "dry-types"
        loader.inflector = ::Zeitwerk::GemInflector.new("#{root}/dry-types.rb")
        loader.inflector.inflect("json" => "JSON")
        loader.push_dir(root)
        loader.ignore(
          "#{root}/dry-types.rb",
          "#{root}/dry/types/extensions",
          "#{root}/dry/types/printer",
          "#{root}/dry/types/spec/types.rb",
          "#{root}/dry/types/{#{%w[
            compat
            constraints
            core
            errors
            extensions
            inflector
            module
            json
            params
            printer
            version
          ].join(",")}}.rb"
        )
      end
    end

    loader.setup

    # @see Dry.Types
    def self.module(*namespaces, default: :nominal, **aliases)
      ::Module.new(container, *namespaces, default: default, **aliases)
    end
    deprecate_class_method :module, message: <<~DEPRECATION
      Use Dry.Types() instead. Beware, it exports strict types by default, for old behavior use Dry.Types(default: :nominal). See more options in the changelog
    DEPRECATION

    # @api private
    def self.included(*)
      raise "Import Dry.Types, not Dry::Types"
    end

    # Return container with registered built-in type objects
    #
    # @return [Container{String => Nominal}]
    #
    # @api private
    def self.container
      @container ||= Container.new
    end

    # Check if a give type is registered
    #
    # @return [Boolean]
    #
    # @api private
    def self.registered?(class_or_identifier)
      container.key?(identifier(class_or_identifier))
    end

    # Register a new built-in type
    #
    # @param [String] name
    # @param [Type] type
    # @param [#call,nil] block
    #
    # @return [Container{String => Nominal}]
    #
    # @api private
    def self.register(name, type = nil, &block)
      container.register(name, type || block.call)
    end

    # Get a built-in type by its name
    #
    # @param [String,Class] name
    #
    # @return [Type,Class]
    #
    # @api public
    def self.[](name)
      type_map.fetch_or_store(name) do
        case name
        when ::String
          result = name.match(TYPE_SPEC_REGEX)

          if result
            type_id, member_id = result[1..2]
            container[type_id].of(self[member_id])
          else
            container[name]
          end
        when ::Class
          warn(<<~DEPRECATION)
            Using Dry::Types.[] with a class is deprecated, please use string identifiers: Dry::Types[Integer] -> Dry::Types['integer'].
            If you're using dry-struct this means changing `attribute :counter, Integer` to `attribute :counter, Dry::Types['integer']` or to `attribute :counter, 'integer'`.
          DEPRECATION

          type_name = identifier(name)

          if container.key?(type_name)
            self[type_name]
          else
            name
          end
        end
      end
    end

    # Infer a type identifier from the provided class
    #
    # @param [#to_s] klass
    #
    # @return [String]
    def self.identifier(klass)
      Types::Inflector.underscore(klass).tr("/", ".")
    end

    # Cached type map
    #
    # @return [Concurrent::Map]
    #
    # @api private
    def self.type_map
      @type_map ||= ::Concurrent::Map.new
    end

    # @api private
    def self.const_missing(const)
      underscored = Types::Inflector.underscore(const)

      if container.keys.any? { |key| key.split(".")[0] == underscored }
        raise ::NameError,
              "dry-types does not define constants for default types. " \
              "You can access the predefined types with [], e.g. Dry::Types['integer'] " \
              "or generate a module with types using Dry.Types()"
      else
        super
      end
    end

    # Add a new type builder method. This is a public API for defining custom
    # type constructors
    #
    # @example simple custom type constructor
    #   Dry::Types.define_builder(:or_nil) do |type|
    #     type.optional.fallback(nil)
    #   end
    #
    #   Dry::Types["integer"].or_nil.("foo") # => nil
    #
    # @example fallback alias
    #   Dry::Types.define_builder(:or) do |type, fallback|
    #     type.fallback(fallback)
    #   end
    #
    #   Dry::Types["integer"].or(100).("foo") # => 100
    #
    # @param [Symbol] method
    # @param [#call] block
    #
    # @api public
    def self.define_builder(method, &block)
      Builder.define_method(method) do |*args|
        block.(self, *args)
      end
    end
  end

  # Export registered types as a module with constants
  #
  # @example no options
  #
  #   module Types
  #     # imports all types as constants, uses modules for namespaces
  #     include Dry.Types()
  #   end
  #   # strict types are exported by default
  #   Types::Integer
  #   # => #<Dry::Types[Constrained<Nominal<Integer> rule=[type?(Integer)]>]>
  #   Types::Nominal::Integer
  #   # => #<Dry::Types[Nominal<Integer>]>
  #
  # @example changing default types
  #
  #   module Types
  #     include Dry.Types(default: :nominal)
  #   end
  #   Types::Integer
  #   # => #<Dry::Types[Nominal<Integer>]>
  #
  # @example cherry-picking namespaces
  #
  #   module Types
  #     include Dry.Types(:strict, :coercible)
  #   end
  #   # cherry-picking discards default types,
  #   # provide the :default option along with the list of
  #   # namespaces if you want the to be exported
  #   Types.constants # => [:Coercible, :Strict]
  #
  # @example custom names
  #   module Types
  #     include Dry.Types(coercible: :Kernel)
  #   end
  #   Types::Kernel::Integer
  #   # => #<Dry::Types[Constructor<Nominal<Integer> fn=Kernel.Integer>]>
  #
  # @param [Array<Symbol>] namespaces List of type namespaces to export
  # @param [Symbol] default Default namespace to export
  # @param [Hash{Symbol => Symbol}] aliases Optional renamings, like strict: :Draconian
  #
  # @return [Dry::Types::Module]
  #
  # @see Dry::Types::Module
  #
  # @api public
  #
  def self.Types(*namespaces, default: Types::Undefined, **aliases)
    Types::Module.new(Types.container, *namespaces, default: default, **aliases)
  end
end

require "dry/types/core" # load built-in types
require "dry/types/extensions"
require "dry/types/printer"
