# frozen_string_literal: true

module Aws
  module EventStream

    class HeaderValue

      def initialize(options)
        @type = options.fetch(:type)
        @value = options[:format] ?
          format_value(options.fetch(:value)) :
          options.fetch(:value)
      end

      attr_reader :value

      # @return [String] type of the header value
      #   complete type list see Aws::EventStream::Types
      attr_reader :type

      private

      def format_value(value)
        case @type
        when 'timestamp' then format_timestamp(value)
        when 'uuid' then format_uuid(value)
        else
          value
        end
      end

      def format_uuid(value)
        bytes = value.bytes
        # For user-friendly uuid representation,
        # format binary bytes into uuid string format
        uuid_pattern = [ [ 3, 2, 1, 0 ], [ 5, 4 ], [ 7, 6 ], [ 8, 9 ], 10..15 ]
        uuid_pattern.map {|p| p.map {|n| "%02x" % bytes.to_a[n] }.join }.join('-')
      end

      def format_timestamp(value)
        # millis_since_epoch to sec_since_epoch
        Time.at(value / 1000.0)
      end

    end

  end
end
