# frozen_string_literal: true

module Datadog
  module Core
    module Utils
      # Helper methods for encoding and decoding base64
      module Base64
        def self.encode64(bin)
          [bin].pack('m')
        end

        def self.strict_encode64(bin)
          [bin].pack('m0')
        end

        def self.strict_decode64(str)
          str.unpack1('m0')
        end
      end
    end
  end
end
