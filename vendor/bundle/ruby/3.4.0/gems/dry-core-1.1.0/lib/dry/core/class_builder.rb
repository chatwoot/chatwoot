# frozen_string_literal: true

module Dry
  module Core
    # Class for generating more classes
    class ClassBuilder
      ParentClassMismatch = ::Class.new(::TypeError)

      attr_reader :name, :parent, :namespace

      def initialize(name:, parent: nil, namespace: nil)
        @name = name
        @namespace = namespace
        @parent = parent || ::Object
      end

      # Generate a class based on options
      #
      # @example Create anonymous class
      #   builder = Dry::Core::ClassBuilder.new(name: 'MyClass')
      #
      #   klass = builder.call
      #   klass.name # => "MyClass"
      #
      # @example Create named class
      #   builder = Dry::Core::ClassBuilder.new(name: 'User', namespace: Entities)
      #
      #   klass = builder.call
      #   klass.name # => "Entities::User"
      #   klass.superclass.name # => "Entities::User"
      #   Entities::User # => "Entities::User"
      #   klass.superclass == Entities::User # => true
      #
      # @return [Class]
      def call
        klass = if namespace
                  create_named
                else
                  create_anonymous
                end

        yield(klass) if block_given?

        klass
      end

      private

      # @api private
      def create_anonymous
        klass = ::Class.new(parent)
        name = self.name

        klass.singleton_class.class_eval do
          define_method(:name) { name }
          alias_method :inspect, :name
          alias_method :to_s, :name
        end

        klass
      end

      # @api private
      def create_named
        name = self.name
        base = create_base(namespace, name, parent)
        klass = ::Class.new(base)

        namespace.module_eval do
          remove_const(name)
          const_set(name, klass)

          remove_const(name)
          const_set(name, base)
        end

        klass
      end

      # @api private
      def create_base(namespace, name, parent)
        begin
          namespace.const_get(name)
        rescue NameError # rubocop:disable Lint/SuppressedException
        end

        if namespace.const_defined?(name, false)
          existing = namespace.const_get(name)

          unless existing <= parent
            raise ParentClassMismatch, "#{existing.name} must be a subclass of #{parent.name}"
          end

          existing
        else
          klass = ::Class.new(parent || ::Object)
          namespace.const_set(name, klass)
          klass
        end
      end
    end
  end
end
