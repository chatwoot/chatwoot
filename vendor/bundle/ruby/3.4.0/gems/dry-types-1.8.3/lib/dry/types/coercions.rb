# frozen_string_literal: true

module Dry
  module Types
    # Common coercion functions used by the built-in `Params` and `JSON` types
    #
    # @api public
    module Coercions
      include Dry::Core::Constants

      # @param [#to_str, Object] input
      #
      # @return [Date, Object]
      #
      # @see Date.parse
      #
      # @api public
      def to_date(input, &)
        if input.respond_to?(:to_str)
          begin
            ::Date.parse(input)
          rescue ::ArgumentError, ::RangeError => e
            CoercionError.handle(e, &)
          end
        elsif input.is_a?(::Date)
          input
        elsif block_given?
          yield
        else
          raise CoercionError, "#{input.inspect} is not a string"
        end
      end

      # @param [#to_str, Object] input
      #
      # @return [DateTime, Object]
      #
      # @see DateTime.parse
      #
      # @api public
      def to_date_time(input, &)
        if input.respond_to?(:to_str)
          begin
            ::DateTime.parse(input)
          rescue ::ArgumentError => e
            CoercionError.handle(e, &)
          end
        elsif input.is_a?(::DateTime)
          input
        elsif block_given?
          yield
        else
          raise CoercionError, "#{input.inspect} is not a string"
        end
      end

      # @param [#to_str, Object] input
      #
      # @return [Time, Object]
      #
      # @see Time.parse
      #
      # @api public
      def to_time(input, &)
        if input.respond_to?(:to_str)
          begin
            ::Time.parse(input)
          rescue ::ArgumentError => e
            CoercionError.handle(e, &)
          end
        elsif input.is_a?(::Time)
          input
        elsif block_given?
          yield
        else
          raise CoercionError, "#{input.inspect} is not a string"
        end
      end

      # @param [#to_sym, Object] input
      #
      # @return [Symbol, Object]
      #
      # @raise CoercionError
      #
      # @api public
      def to_symbol(input, &)
        input.to_sym
      rescue ::NoMethodError => e
        CoercionError.handle(e, &)
      end

      private

      # Checks whether String is empty
      #
      # @param [String, Object] value
      #
      # @return [Boolean]
      #
      # @api private
      def empty_str?(value) = EMPTY_STRING.eql?(value)
    end
  end
end
