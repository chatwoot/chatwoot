# frozen_string_literal: true

require 'json'
require 'zlib'
require 'stringio'

require_relative '../core/utils/base64'

module Datadog
  module AppSec
    # Converts derivative schema payloads into JSON and compresses them into a
    # base64 encoded string if the payload is worth compressing.
    #
    # See: https://github.com/DataDog/dd-trace-rb/pull/3177#issuecomment-1747221082
    module CompressedJson
      MIN_SIZE_FOR_COMPRESSION = 260

      def self.dump(payload)
        value = JSON.dump(payload)
        return value if value.bytesize < MIN_SIZE_FOR_COMPRESSION

        compress_and_encode(value)
      rescue ArgumentError, Encoding::UndefinedConversionError, JSON::JSONError => e
        AppSec.telemetry.report(e, description: 'AppSec: Failed to convert value into JSON')

        nil
      end

      private_class_method def self.compress_and_encode(payload)
        Core::Utils::Base64.strict_encode64(
          Zlib.gzip(payload, level: Zlib::BEST_SPEED, strategy: Zlib::DEFAULT_STRATEGY)
        )
      rescue Zlib::Error, TypeError => e
        AppSec.telemetry.report(e, description: 'AppSec: Failed to compress and encode value')

        nil
      end
    end
  end
end
