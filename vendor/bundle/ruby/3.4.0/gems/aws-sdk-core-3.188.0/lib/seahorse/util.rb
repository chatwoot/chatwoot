# frozen_string_literal: true

require 'cgi'

module Seahorse
  # @api private
  module Util
    class << self
      def uri_escape(string)
        CGI.escape(string.to_s.encode('UTF-8')).gsub('+', '%20').gsub('%7E', '~')
      end

      def uri_path_escape(path)
        path.gsub(/[^\/]+/) { |part| uri_escape(part) }
      end

      def escape_header_list_string(s)
        s.include?('"') || s.include?(',') ? "\"#{s.gsub('"', '\"')}\"" : s
      end

      # Checks for a valid host label
      # @see https://tools.ietf.org/html/rfc3986#section-3.2.2
      # @see https://tools.ietf.org/html/rfc1123#page-13
      def host_label?(str)
        str =~ /^(?!-)[a-zA-Z0-9-]{1,63}(?<!-)$/
      end
    end
  end
end
