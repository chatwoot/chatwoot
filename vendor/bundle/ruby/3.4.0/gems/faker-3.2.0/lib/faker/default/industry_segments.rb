# frozen_string_literal: true

module Faker
  class IndustrySegments < Base
    flexible :industry_segments

    class << self
      ##
      # Produces the name of an industry.
      #
      # @return [String]
      #
      # @example
      #   Faker::IndustrySegments.industry #=> "Basic Materials"
      #
      # @faker.version 1.9.2
      def industry
        fetch('industry_segments.industry')
      end

      ##
      # Produces the name of a super-sector of an industry.
      #
      # @return [String]
      #
      # @example
      #   Faker::IndustrySegments.super_sector #=> "Basic Resources"
      #
      # @faker.version 1.9.2
      def super_sector
        fetch('industry_segments.super_sector')
      end

      ##
      # Produces the name of a sector of an industry.
      #
      # @return [String]
      #
      # @example
      #   Faker::IndustrySegments.sector #=> "Industrial Metals & Mining"
      #
      # @faker.version 1.9.2
      def sector
        fetch('industry_segments.sector')
      end

      ##
      # Produces the name of a subsector of an industry.
      #
      # @return [String]
      #
      # @example
      #   Faker::IndustrySegments.industry #=> "Basic Materials"
      #
      # @faker.version 1.9.2
      def sub_sector
        fetch('industry_segments.sub_sector')
      end
    end
  end
end
