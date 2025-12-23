# frozen_string_literal: true

module RubyLLM
  module Model
    # A dynamic class for storing non-zero pricing values with flexible attribute access
    class PricingTier
      def initialize(data = {})
        @values = {}

        data.each do |key, value|
          @values[key.to_sym] = value if value && value != 0.0
        end
      end

      def method_missing(method, *args)
        if method.to_s.end_with?('=')
          key = method.to_s.chomp('=').to_sym
          @values[key] = args.first if args.first && args.first != 0.0
        elsif @values.key?(method)
          @values[method]
        end
      end

      def respond_to_missing?(method, include_private = false)
        method.to_s.end_with?('=') || @values.key?(method.to_sym) || super
      end

      def to_h
        @values
      end
    end
  end
end
