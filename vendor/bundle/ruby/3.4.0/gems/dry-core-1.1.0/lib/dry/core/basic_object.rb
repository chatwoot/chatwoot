# frozen_string_literal: true

# This implementation was imported from `hanami-utils` gem.
module Dry
  module Core
    # BasicObject
    #
    # @since 0.8.0
    class BasicObject < ::BasicObject
      # Lookups constants at the top-level namespace, if they are missing in the
      # current context.
      #
      # @param name [Symbol] the constant name
      #
      # @return [Object, Module] the constant
      #
      # @raise [NameError] if the constant cannot be found
      #
      # @since 0.8.0
      # @api private
      #
      # @see https://ruby-doc.org/core/Module.html#method-i-const_missing
      def self.const_missing(name)
        ::Object.const_get(name)
      end

      # Returns the class for debugging purposes.
      #
      # @since 0.8.0
      #
      # @see http://ruby-doc.org/core/Object.html#method-i-class
      def class
        (class << self; self; end).superclass
      end

      # Bare minimum inspect for debugging purposes.
      #
      # @return [String] the inspect string
      #
      # @since 0.8.0
      #
      # @see http://ruby-doc.org/core/Object.html#method-i-inspect
      inspect_method = ::Kernel.instance_method(:inspect)
      define_method(:inspect) do
        original = inspect_method.bind_call(self)
        "#{original[0...-1]}#{__inspect}>"
      end

      # @!macro [attach] instance_of?(class)
      #
      # Determines if self is an instance of given class or module
      #
      # @param class [Class,Module] the class of module to verify
      #
      # @return [TrueClass,FalseClass] the result of the check
      #
      # @raise [TypeError] if the given argument is not of the expected types
      #
      # @since 0.8.0
      #
      # @see http://ruby-doc.org/core/Object.html#method-i-instance_of-3F
      define_method :instance_of?, ::Object.instance_method(:instance_of?)

      # @!macro [attach] is_a?(class)
      #
      # Determines if self is of the type of the object class or module
      #
      # @param class [Class,Module] the class of module to verify
      #
      # @return [TrueClass,FalseClass] the result of the check
      #
      # @raise [TypeError] if the given argument is not of the expected types
      #
      # @since 0.8.0
      #
      # @see http://ruby-doc.org/core/Object.html#method-i-is_a-3F
      define_method :is_a?, ::Object.instance_method(:is_a?)

      # @!macro [attach] kind_of?(class)
      #
      # Determines if self is of the kind of the object class or module
      #
      # @param class [Class,Module] the class of module to verify
      #
      # @return [TrueClass,FalseClass] the result of the check
      #
      # @raise [TypeError] if the given argument is not of the expected types
      #
      # @since 0.8.0
      #
      # @see http://ruby-doc.org/core/Object.html#method-i-kind_of-3F
      define_method :kind_of?, ::Object.instance_method(:kind_of?)

      # Alias for __id__
      #
      # @return [Fixnum] the object id
      #
      # @since 0.8.0
      #
      # @see http://ruby-doc.org/core/Object.html#method-i-object_id
      def object_id
        __id__
      end

      # Interface for pp
      #
      # @param printer [PP] the Pretty Printable printer
      # @return [String] the pretty-printable inspection of the object
      #
      # @since 0.8.0
      #
      # @see https://ruby-doc.org/stdlib/libdoc/pp/rdoc/PP.html
      def pretty_print(printer)
        printer.text(inspect)
      end

      # Returns true if responds to the given method.
      #
      # @return [TrueClass,FalseClass] the result of the check
      #
      # @since 0.8.0
      #
      # @see http://ruby-doc.org/core/Object.html#method-i-respond_to-3F
      def respond_to?(method_name, include_all = false) # rubocop:disable Style/OptionalBooleanParameter
        respond_to_missing?(method_name, include_all)
      end

      private

      # Must be overridden by descendants
      #
      # @since 0.8.0
      # @api private
      def respond_to_missing?(_method_name, _include_all)
        ::Kernel.raise ::NotImplementedError
      end

      # @since 0.8.0
      # @api private
      def __inspect; end
    end
  end
end
