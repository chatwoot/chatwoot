# frozen_string_literal: true

module Faker
  class BossaNova < Base
    class << self
      ##
      # Produces the name of a bossa nova artist.
      #
      # @return [String]
      #
      # @example
      #   Faker::BossaNova.artist #=> "Tom Jobin"
      #
      # @faker.version 1.8.3
      def artist
        fetch('bossa_nova.artists')
      end

      ##
      # Produces a bossa nova song.
      #
      # @return [String]
      #
      # @example
      #   Faker::BossaNova.song #=> "Chega de Saudade"
      #
      # @faker.version 1.8.3
      def song
        fetch('bossa_nova.songs')
      end
    end
  end
end
