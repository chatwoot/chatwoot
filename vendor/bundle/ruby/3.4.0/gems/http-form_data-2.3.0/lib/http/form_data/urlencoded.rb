# frozen_string_literal: true

require "http/form_data/readable"

require "uri"
require "stringio"

module HTTP
  module FormData
    # `application/x-www-form-urlencoded` form data.
    class Urlencoded
      include Readable

      class << self
        # Set custom form data encoder implementation.
        #
        # @example
        #
        #     module CustomFormDataEncoder
        #       UNESCAPED_CHARS = /[^a-z0-9\-\.\_\~]/i
        #
        #       def self.escape(s)
        #         ::URI::DEFAULT_PARSER.escape(s.to_s, UNESCAPED_CHARS)
        #       end
        #
        #       def self.call(data)
        #         parts = []
        #
        #         data.each do |k, v|
        #           k = escape(k)
        #
        #           if v.nil?
        #             parts << k
        #           elsif v.respond_to?(:to_ary)
        #             v.to_ary.each { |vv| parts << "#{k}=#{escape vv}" }
        #           else
        #             parts << "#{k}=#{escape v}"
        #           end
        #         end
        #
        #         parts.join("&")
        #       end
        #     end
        #
        #     HTTP::FormData::Urlencoded.encoder = CustomFormDataEncoder
        #
        # @raise [ArgumentError] if implementation deos not responds to `#call`.
        # @param implementation [#call]
        # @return [void]
        def encoder=(implementation)
          raise ArgumentError unless implementation.respond_to? :call
          @encoder = implementation
        end

        # Returns form data encoder implementation.
        # Default: `URI.encode_www_form`.
        #
        # @see .encoder=
        # @return [#call]
        def encoder
          @encoder ||= ::URI.method(:encode_www_form)
        end
      end

      # @param [#to_h, Hash] data form data key-value Hash
      def initialize(data, encoder: nil)
        encoder ||= self.class.encoder
        @io = StringIO.new(encoder.call(FormData.ensure_hash(data)))
      end

      # Returns MIME type to be used for HTTP request `Content-Type` header.
      #
      # @return [String]
      def content_type
        "application/x-www-form-urlencoded"
      end

      # Returns form data content size to be used for HTTP request
      # `Content-Length` header.
      #
      # @return [Integer]
      alias content_length size
    end
  end
end
