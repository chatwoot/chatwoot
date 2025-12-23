# frozen_string_literal: true

module HTTP
  class ContentType
    MIME_TYPE_RE = %r{^([^/]+/[^;]+)(?:$|;)}.freeze
    CHARSET_RE   = /;\s*charset=([^;]+)/i.freeze

    attr_accessor :mime_type, :charset

    class << self
      # Parse string and return ContentType struct
      def parse(str)
        new mime_type(str), charset(str)
      end

      private

      # :nodoc:
      def mime_type(str)
        str.to_s[MIME_TYPE_RE, 1]&.strip&.downcase
      end

      # :nodoc:
      def charset(str)
        str.to_s[CHARSET_RE, 1]&.strip&.delete('"')
      end
    end

    def initialize(mime_type = nil, charset = nil)
      @mime_type = mime_type
      @charset   = charset
    end
  end
end
