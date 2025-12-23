# frozen_string_literal: true

require "http/uri"

module HTTP
  module Features
    class NormalizeUri < Feature
      attr_reader :normalizer

      def initialize(normalizer: HTTP::URI::NORMALIZER)
        @normalizer = normalizer
      end

      HTTP::Options.register_feature(:normalize_uri, self)
    end
  end
end
