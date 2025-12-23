# frozen_string_literal: true

module WebMock

  module Util

    class URI
      module CharacterClasses
        USERINFO = Addressable::URI::CharacterClasses::UNRESERVED + Addressable::URI::CharacterClasses::SUB_DELIMS + "\\:"
      end

      ADDRESSABLE_URIS = Hash.new do |hash, key|
        hash[key] = Addressable::URI.heuristic_parse(key)
      end

      NORMALIZED_URIS = Hash.new do |hash, uri|
        normalized_uri = WebMock::Util::URI.heuristic_parse(uri)
        if normalized_uri.query_values
          sorted_query_values = sort_query_values(WebMock::Util::QueryMapper.query_to_values(normalized_uri.query, notation: Config.instance.query_values_notation) || {})
          normalized_uri.query = WebMock::Util::QueryMapper.values_to_query(sorted_query_values, notation: WebMock::Config.instance.query_values_notation)
        end
        normalized_uri = normalized_uri.normalize #normalize! is slower
        normalized_uri.query = normalized_uri.query.gsub("+", "%2B") if normalized_uri.query
        normalized_uri.port = normalized_uri.inferred_port unless normalized_uri.port
        hash[uri] = normalized_uri
      end

      def self.heuristic_parse(uri)
        ADDRESSABLE_URIS[uri].dup
      end

      def self.normalize_uri(uri)
        return uri if uri.is_a?(Regexp)
        uri = 'http://' + uri unless uri.match('^https?://') if uri.is_a?(String)
        NORMALIZED_URIS[uri].dup
      end

      def self.variations_of_uri_as_strings(uri_object, only_with_scheme: false)
        normalized_uri = normalize_uri(uri_object.dup).freeze
        uris = [ normalized_uri ]

        if normalized_uri.path == '/'
          uris = uris_with_trailing_slash_and_without(uris)
        end

        if normalized_uri.port == Addressable::URI.port_mapping[normalized_uri.scheme]
          uris = uris_with_inferred_port_and_without(uris)
        end

        uris = uris_encoded_and_unencoded(uris)

        if normalized_uri.scheme == "http" && !only_with_scheme
          uris = uris_with_scheme_and_without(uris)
        end

        uris.map {|uri| uri.to_s.gsub(/^\/\//,'') }.uniq
      end

      def self.strip_default_port_from_uri_string(uri_string)
        case uri_string
        when %r{^http://}  then uri_string.sub(%r{:80(/|$)}, '\1')
        when %r{^https://} then uri_string.sub(%r{:443(/|$)}, '\1')
        else uri_string
        end
      end

      def self.encode_unsafe_chars_in_userinfo(userinfo)
        Addressable::URI.encode_component(userinfo, WebMock::Util::URI::CharacterClasses::USERINFO)
      end

      def self.is_uri_localhost?(uri)
        uri.is_a?(Addressable::URI) &&
        %w(localhost 127.0.0.1 0.0.0.0 [::1]).include?(uri.host)
      end

      private

      def self.sort_query_values(query_values)
        sorted_query_values = query_values.sort
        query_values.is_a?(Hash) ? Hash[*sorted_query_values.inject([]) { |values, pair| values + pair}] : sorted_query_values
      end

      def self.uris_with_inferred_port_and_without(uris)
        uris.map { |uri|
          [ uri, uri.omit(:port)]
        }.flatten
      end

      def self.uris_encoded_and_unencoded(uris)
        uris.map do |uri|
          [
            uri.to_s.force_encoding(Encoding::ASCII_8BIT),
            Addressable::URI.unencode(uri, String).force_encoding(Encoding::ASCII_8BIT).freeze
          ]
        end.flatten
      end

      def self.uris_with_scheme_and_without(uris)
        uris.map { |uri|
          [ uri, uri.gsub(%r{^https?://},"").freeze ]
        }.flatten
      end

      def self.uris_with_trailing_slash_and_without(uris)
        uris.map { |uri|
          [ uri, uri.omit(:path).freeze ]
        }.flatten
      end

    end
  end

end
