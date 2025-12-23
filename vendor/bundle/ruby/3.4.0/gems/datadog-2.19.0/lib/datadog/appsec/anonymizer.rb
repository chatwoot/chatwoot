# frozen_string_literal: true

require 'digest/sha2'

module Datadog
  module AppSec
    # Manual anonymization of the potential PII data
    module Anonymizer
      def self.anonymize(payload)
        raise ArgumentError, "expected String, received #{payload.class}" unless payload.is_a?(String)

        "anon_#{Digest::SHA256.hexdigest(payload)[0, 32]}"
      end
    end
  end
end
