# frozen_string_literal: true

module Faker
  class Camera < Base
    class << self
      ##
      # Produces a brand of a camera
      #
      # @return [String]
      #
      # @example
      #   Faker::Camera.brand #=> "Canon"
      #
      # @faker.version next
      def brand
        fetch('camera.brand')
      end

      ##
      # Produces a model of camera
      #
      # @return [String]
      #
      # @example
      #   Faker::Camera.model #=> "450D"
      #
      # @faker.version next
      def model
        fetch('camera.model')
      end

      ##
      # Produces a brand with model
      #
      # @return [String]
      #
      # @example
      #   Faker::Camera.brand_with_model #=> "Canon 450D"
      #
      # @faker.version next
      def brand_with_model
        fetch('camera.brand_with_model')
      end
    end
  end
end
