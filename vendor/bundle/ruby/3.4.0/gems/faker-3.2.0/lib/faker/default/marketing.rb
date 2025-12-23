# frozen_string_literal: true

module Faker
  class Marketing < Base
    flexible :marketing

    class << self
      ##
      # Produces a few marketing buzzwords.
      #
      # @return [String]
      #
      # @example
      #   Faker::Marketing.buzzwords #=> "rubber meets the road"
      #
      # @faker.version 1.9.4
      def buzzwords
        fetch('marketing.buzzwords')
      end
    end
  end
end
