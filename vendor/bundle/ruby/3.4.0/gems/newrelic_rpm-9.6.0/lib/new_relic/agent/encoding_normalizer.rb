# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# This module was extracted from NewRelic::JSONWrapper

module NewRelic
  module Agent
    module EncodingNormalizer
      def self.normalize_string(raw_string)
        EncodingNormalizer.normalize(raw_string)
      end

      def self.normalize_object(object)
        case object
        when String
          normalize_string(object)
        when Symbol
          normalize_string(object.to_s)
        when Array
          return object if object.empty?

          object.map { |x| normalize_object(x) }
        when Hash
          return object if object.empty?

          hash = {}
          object.each_pair do |k, v|
            k = normalize_string(k) if k.is_a?(String)
            k = normalize_string(k.to_s) if k.is_a?(Symbol)
            hash[k] = normalize_object(v)
          end
          hash
        when Rational
          object.to_f
        else
          object
        end
      end

      module EncodingNormalizer
        def self.normalize(raw_string)
          encoding = raw_string.encoding
          if (encoding == Encoding::UTF_8 || encoding == Encoding::ISO_8859_1) && raw_string.valid_encoding?
            return raw_string
          end

          # If the encoding is not valid, or it's ASCII-8BIT, we know conversion to
          # UTF-8 is likely to fail, so treat it as ISO-8859-1 (byte-preserving).
          normalized = raw_string.dup
          if encoding == Encoding::ASCII_8BIT || !raw_string.valid_encoding?
            normalized.force_encoding(Encoding::ISO_8859_1)
          else
            # Encoding is valid and non-binary, so it might be cleanly convertible
            # to UTF-8. Give it a try and fall back to ISO-8859-1 if it fails.
            begin
              normalized.encode!(Encoding::UTF_8)
            rescue
              normalized.force_encoding(Encoding::ISO_8859_1)
            end
          end
          normalized
        end
      end
    end
  end
end
