# frozen_string_literal: true

module RubyLLM
  module Model
    # Represents pricing tiers for different usage categories (standard and batch)
    class PricingCategory
      attr_reader :standard, :batch

      def initialize(data = {})
        @standard = PricingTier.new(data[:standard] || {}) unless empty_tier?(data[:standard])
        @batch = PricingTier.new(data[:batch] || {}) unless empty_tier?(data[:batch])
      end

      def input
        standard&.input_per_million
      end

      def output
        standard&.output_per_million
      end

      def cached_input
        standard&.cached_input_per_million
      end

      def [](key)
        key == :batch ? batch : standard
      end

      def to_h
        result = {}
        result[:standard] = standard.to_h if standard
        result[:batch] = batch.to_h if batch
        result
      end

      private

      def empty_tier?(tier_data)
        return true unless tier_data

        tier_data.values.all? { |v| v.nil? || v == 0.0 }
      end
    end
  end
end
