# frozen_string_literal: true

module WebMock

  module Util

    class Headers

      STANDARD_HEADER_DELIMITER = '-'
      NONSTANDARD_HEADER_DELIMITER = '_'
      JOIN = ', '

      def self.normalize_headers(headers)
        return nil unless headers

        headers.each_with_object({}) do |(name, value), new_headers|
          new_headers[normalize_name(name)] =
            case value
            when Regexp then value
            when Array then (value.size == 1) ? value.first.to_s : value.map(&:to_s).sort
            else value.to_s
            end
        end
      end

      def self.sorted_headers_string(headers)
        headers = WebMock::Util::Headers.normalize_headers(headers)
        str = '{'.dup
        str << headers.map do |k,v|
          v = case v
            when Regexp then v.inspect
            when Array then "["+v.map{|w| "'#{w.to_s}'"}.join(", ")+"]"
            else "'#{v.to_s}'"
          end
          "'#{k}'=>#{v}"
        end.sort.join(", ")
        str << '}'
      end

      def self.pp_headers_string(headers)
        headers = WebMock::Util::Headers.normalize_headers(headers)
        seperator = "\n\t "
        str = "{#{seperator} ".dup
        str << headers.map do |k,v|
          v = case v
            when Regexp then v.inspect
            when Array then "["+v.map{|w| "'#{w.to_s}'"}.join(", ")+"]"
            else "'#{v.to_s}'"
          end
          "'#{k}'=>#{v}"
        end.sort.join(",#{seperator} ")
        str << "\n    }"
      end

      def self.decode_userinfo_from_header(header)
        header.sub(/^Basic /, "").unpack("m").first
      end

      def self.basic_auth_header(*credentials)
        strict_base64_encoded = [credentials.join(':')].pack("m0")
        "Basic #{strict_base64_encoded.chomp}"
      end

      def self.normalize_name(name)
        name
          .to_s
          .tr(NONSTANDARD_HEADER_DELIMITER, STANDARD_HEADER_DELIMITER)
          .split(STANDARD_HEADER_DELIMITER)
          .map!(&:capitalize)
          .join(STANDARD_HEADER_DELIMITER)
      end

    end

  end

end
