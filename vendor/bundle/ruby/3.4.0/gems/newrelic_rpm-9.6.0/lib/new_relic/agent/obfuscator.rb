# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# require 'base64'

module NewRelic
  module Agent
    class Obfuscator
      attr_reader :key_bytes

      EMPTY_KEY_BYTES = [0]
      PACK_FORMAT = 'm'

      # RUM uses a shortened key, so just trim it up front
      def initialize(key, length = nil)
        if key.nil? || key.empty?
          @key_bytes = EMPTY_KEY_BYTES
        else
          @key_bytes = key.bytes.to_a
          @key_bytes = @key_bytes.first(length) if length
        end
      end

      def obfuscate(text)
        [encode(text)].pack(PACK_FORMAT).delete("\n")
      end

      def deobfuscate(text)
        encode(text.unpack(PACK_FORMAT).first)
      end

      def encode(text)
        return text unless key_bytes

        encoded = +''
        encoded.force_encoding('binary') if encoded.respond_to?(:force_encoding)
        index = 0
        text.each_byte do |byte|
          encoded.concat((byte ^ key_bytes[index % key_bytes.length]))
          index += 1
        end
        encoded
      end
    end
  end
end
