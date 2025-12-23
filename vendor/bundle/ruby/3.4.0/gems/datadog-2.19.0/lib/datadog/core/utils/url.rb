# frozen_string_literal: true

require 'uri'

module Datadog
  module Core
    module Utils
      # Helpers class that provides methods to process URLs
      # such as filtering sensitive information.
      module Url
        def self.filter_basic_auth(url)
          return nil if url.nil?

          URI(url).tap do |u|
            u.user = nil
            u.password = nil
          end.to_s
        # Git scheme: git@github.com:DataDog/dd-trace-rb.git
        rescue URI::InvalidURIError
          url
        end
      end
    end
  end
end
