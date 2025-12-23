# frozen_string_literal: true

class Pry
  class Method
    # A Disowned Method is one that's been removed from the class on which it was defined.
    #
    # e.g.
    # class C
    #   def foo
    #     C.send(:undefine_method, :foo)
    #     Pry::Method.from_binding(binding)
    #   end
    # end
    #
    # In this case we assume that the "owner" is the singleton class of the receiver.
    #
    # This occurs mainly in Sinatra applications.
    class Disowned < Method
      attr_reader :receiver, :name

      # Create a new Disowned method.
      #
      # @param [Object] receiver
      # @param [String] method_name
      def initialize(receiver, method_name)
        @receiver = receiver
        @name = method_name
        @method = nil
      end

      # Is the method undefined? (aka `Disowned`)
      # @return [Boolean] true
      def undefined?
        true
      end

      # Can we get the source for this method?
      # @return [Boolean] false
      def source?
        false
      end

      # Get the hypothesized owner of the method.
      #
      # @return [Object]
      def owner
        class << receiver; self; end
      end

      # Raise a more useful error message instead of trying to forward to nil.
      # rubocop:disable Style/MethodMissingSuper
      def method_missing(method_name, *args, &block)
        if method(:name).respond_to?(method_name)
          raise "Cannot call '#{method_name}' on an undef'd method."
        end

        method = Object.instance_method(:method_missing).bind(self)
        method.call(method_name, *args, &block)
      end
      # rubocop:enable Style/MethodMissingSuper

      def respond_to_missing?(method_name, include_private = false)
        !method(:name).respond_to?(method_name) || super
      end
    end
  end
end
