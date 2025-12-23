# frozen_string_literal: true

module Dry
  module Core
    # Helper module providing thin interface around an inflection backend.
    module Inflector
      # List of supported backends
      BACKENDS = {
        activesupport: [
          "active_support/inflector",
          proc { ::ActiveSupport::Inflector }
        ],
        dry_inflector: [
          "dry/inflector",
          proc { ::Dry::Inflector.new }
        ],
        inflecto: [
          "inflecto",
          proc { ::Inflecto }
        ]
      }.freeze

      # Try to activate a backend
      #
      # @api private
      def self.realize_backend(path, backend_factory)
        require path
      rescue ::LoadError
        nil
      else
        backend_factory.call
      end

      # Set up first available backend
      #
      # @api private
      def self.detect_backend
        BACKENDS.inject(nil) do |backend, (_, (path, factory))|
          backend || realize_backend(path, factory)
        end || raise(
          LoadError,
          "No inflector library could be found: " \
          "please install either the `inflecto` or `activesupport` gem."
        )
      end

      # Set preferred backend
      #
      # @param [Symbol] name backend name (:activesupport or :inflecto)
      def self.select_backend(name = nil)
        if name && !BACKENDS.key?(name)
          raise ::NameError, "Invalid inflector library selection: '#{name}'"
        end

        @inflector = name ? realize_backend(*BACKENDS[name]) : detect_backend
      end

      # Inflector accessor. Lazily initializes a backend
      #
      # @api private
      def self.inflector
        defined?(@inflector) ? @inflector : select_backend
      end

      # Transform string to camel case
      #
      # @example
      #   Dry::Core::Inflector.camelize('foo_bar') # => 'FooBar'
      #
      # @param [String] input input string
      # @return Transformed string
      def self.camelize(input)
        inflector.camelize(input)
      end

      # Transform string to snake case
      #
      # @example
      #   Dry::Core::Inflector.underscore('FooBar') # => 'foo_bar'
      #
      # @param [String] input input string
      # @return Transformed string
      def self.underscore(input)
        inflector.underscore(input)
      end

      # Get a singlular form of a word
      #
      # @example
      #   Dry::Core::Inflector.singularize('chars') # => 'char'
      #
      # @param [String] input input string
      # @return Transformed string
      def self.singularize(input)
        inflector.singularize(input)
      end

      # Get a plural form of a word
      #
      # @example
      #   Dry::Core::Inflector.pluralize('string') # => 'strings'
      #
      # @param [String] input input string
      # @return Transformed string
      def self.pluralize(input)
        inflector.pluralize(input)
      end

      # Remove namespaces from a constant name
      #
      # @example
      #   Dry::Core::Inflector.demodulize('Deeply::Nested::Name') # => 'Name'
      #
      # @param [String] input input string
      # @return Unnested constant name
      def self.demodulize(input)
        inflector.demodulize(input)
      end

      # Get a constant value by its name
      #
      # @example
      #   Dry::Core::Inflector.constantize('Foo::Bar') # => Foo::Bar
      #
      # @param [String] input input constant name
      # @return Constant value
      def self.constantize(input)
        inflector.constantize(input)
      end

      # Transform a file path to a constant name
      #
      # @example
      #   Dry::Core::Inflector.classify('foo/bar') # => 'Foo::Bar'
      #
      # @param [String] input input string
      # @return Constant name
      def self.classify(input)
        inflector.classify(input)
      end
    end
  end
end
