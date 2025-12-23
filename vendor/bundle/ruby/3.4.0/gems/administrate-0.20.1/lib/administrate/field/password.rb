require_relative "base"

module Administrate
  module Field
    class Password < Field::Base
      def self.searchable?
        false
      end

      def truncate
        data.to_s.gsub(/./, character)[0...truncation_length]
      end

      private

      def truncation_length
        options.fetch(:truncate, 50)
      end

      def character
        options.fetch(:character, "•")
      end
    end
  end
end
