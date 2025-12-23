# frozen_string_literal: true

module Dry
  module Core
    # Define equality, equivalence and inspection methods
    class Equalizer < ::Module
      # Initialize an Equalizer with the given keys
      #
      # Will use the keys with which it is initialized to define #cmp?,
      # #hash, and #inspect
      #
      # @param [Array<Symbol>] keys
      # @param [Hash] options
      # @option options [Boolean] :inspect whether to define #inspect method
      # @option options [Boolean] :immutable whether to memoize #hash method
      #
      # @return [undefined]
      #
      # @api private
      def initialize(*keys, **options)
        super()
        @keys = keys.uniq
        define_methods(**options)
        freeze
      end

      private

      # Hook called when module is included
      #
      # @param [Module] descendant
      #   the module or class including Equalizer
      #
      # @return [self]
      #
      # @api private
      def included(descendant)
        super
        descendant.include Methods
      end

      # Define the equalizer methods based on #keys
      #
      # @param [Boolean] inspect whether to define #inspect method
      # @param [Boolean] immutable whether to memoize #hash method
      #
      # @return [undefined]
      #
      # @api private
      def define_methods(inspect: true, immutable: false)
        define_cmp_method
        define_hash_method(immutable: immutable)
        define_inspect_method if inspect
      end

      # Define an #cmp? method based on the instance's values identified by #keys
      #
      # @return [undefined]
      #
      # @api private
      def define_cmp_method
        keys = @keys
        define_method(:cmp?) do |comparator, other|
          keys.all? do |key|
            __send__(key).public_send(comparator, other.__send__(key))
          end
        end
        private :cmp?
      end

      # Define a #hash method based on the instance's values identified by #keys
      #
      # @return [undefined]
      #
      # @api private
      def define_hash_method(immutable:)
        calculate_hash = ->(obj) { @keys.map { |key| obj.__send__(key) }.push(obj.class).hash }
        if immutable
          define_method(:hash) do
            @__hash__ ||= calculate_hash.call(self)
          end
          define_method(:freeze) do
            hash
            super()
          end
        else
          define_method(:hash) do
            calculate_hash.call(self)
          end
        end
      end

      # Define an inspect method that reports the values of the instance's keys
      #
      # @return [undefined]
      #
      # @api private
      def define_inspect_method
        keys = @keys
        define_method(:inspect) do
          klass = self.class
          name  = klass.name || klass.inspect
          "#<#{name}#{keys.map { |key| " #{key}=#{__send__(key).inspect}" }.join}>"
        end
      end

      # The comparison methods
      module Methods
        # Compare the object with other object for equality
        #
        # @example
        #   object.eql?(other)  # => true or false
        #
        # @param [Object] other
        #   the other object to compare with
        #
        # @return [Boolean]
        #
        # @api public
        def eql?(other)
          instance_of?(other.class) && cmp?(__method__, other)
        end

        # Compare the object with other object for equivalency
        #
        # @example
        #   object == other  # => true or false
        #
        # @param [Object] other
        #   the other object to compare with
        #
        # @return [Boolean]
        #
        # @api public
        def ==(other)
          other.is_a?(self.class) && cmp?(__method__, other)
        end
      end
    end
  end

  # Old modules that depend on dry/core/equalizer may miss
  # this method if dry/core is not required explicitly
  unless singleton_class.method_defined?(:Equalizer)
    # Build an equalizer module for the inclusion in other class
    #
    # ## Credits
    #
    # Equalizer has been originally imported from the equalizer gem created by Dan Kubb
    #
    # @api public
    def self.Equalizer(*keys, **options)
      ::Dry::Core::Equalizer.new(*keys, **options)
    end
  end
end
