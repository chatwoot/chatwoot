# frozen_string_literal: true

module RubyLLM
  module Model
    # A collection that manages and provides access to different categories of pricing information
    class Pricing
      def initialize(data)
        @data = {}

        %i[text_tokens images audio_tokens embeddings].each do |category|
          @data[category] = PricingCategory.new(data[category]) if data[category] && !empty_pricing?(data[category])
        end
      end

      def method_missing(method, *args)
        if respond_to_missing?(method)
          @data[method.to_sym] || PricingCategory.new
        else
          super
        end
      end

      def respond_to_missing?(method, include_private = false)
        %i[text_tokens images audio_tokens embeddings].include?(method.to_sym) || super
      end

      def to_h
        @data.transform_values(&:to_h)
      end

      private

      def empty_pricing?(data)
        return true unless data

        %i[standard batch].each do |tier|
          next unless data[tier]

          data[tier].each_value do |value|
            return false if value && value != 0.0
          end
        end

        true
      end
    end
  end
end
