require_relative "base"

module Administrate
  module Field
    class Url < Field::Base
      def self.searchable?
        true
      end

      def truncate
        data.to_s[0...truncation_length]
      end

      def html_options
        @options[:html_options] || {}
      end

      private

      def truncation_length
        options.fetch(:truncate, 50)
      end
    end
  end
end
