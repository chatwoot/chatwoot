# frozen_string_literal: true

require "oauth/signature/base"

module OAuth
  module Signature
    class PLAINTEXT < Base
      implements "plaintext"

      def signature
        signature_base_string
      end

      def ==(other)
        signature.to_s == other.to_s
      end

      def signature_base_string
        secret
      end

      def body_hash
        nil
      end
    end
  end
end
