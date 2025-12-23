# -*- ruby -*-
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# This module includes utilities for manipulating URIs, particularly from the
# context of Net::HTTP requests. We don't always have direct access to the full
# URI from our instrumentation points in Net::HTTP, and we want to filter out
# some URI parts before saving URIs from instrumented calls - logic for that
# lives here.

module NewRelic
  module Agent
    module HTTPClients
      module URIUtil
        def self.obfuscated_uri(url)
          parse_and_normalize_url(url).tap do |obfuscated|
            obfuscated.user = nil
            obfuscated.password = nil
            obfuscated.query = nil
            obfuscated.fragment = nil
          end
        end

        # There are valid URI strings that some HTTP client libraries will
        # accept that the stdlib URI module doesn't handle. If we find that
        # Addressable is around, use that to normalize out our URL's.
        def self.parse_and_normalize_url(url)
          uri = url.dup
          unless ::URI === uri
            if defined?(::Addressable::URI)
              address = ::Addressable::URI.parse(url)
              address.normalize!
              uri = ::URI.parse(address.to_s)
            else
              uri = ::URI.parse(url)
            end
          end
          uri.host&.downcase!
          uri
        end

        QUESTION_MARK = '?'

        def self.strip_query_string(fragment)
          if fragment.include?(QUESTION_MARK)
            fragment.split(QUESTION_MARK).first
          else
            fragment
          end
        end
      end
    end
  end
end
