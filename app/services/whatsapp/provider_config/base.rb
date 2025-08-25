# frozen_string_literal: true

module Whatsapp
  module ProviderConfig
    class Base
      attr_reader :channel

      def initialize(channel)
        @channel = channel
      end

      # Abstract methods that must be implemented by subclasses
      def validate_config?
        raise NotImplementedError, "#{self.class} must implement #validate_config?"
      end

      def webhook_verify_token
        raise NotImplementedError, "#{self.class} must implement #webhook_verify_token"
      end

      def cleanup_on_destroy
        # Default no-op implementation
      end
    end
  end
end