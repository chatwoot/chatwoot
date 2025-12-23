# frozen_string_literal: true
module Slack
  module Events
    module Config
      extend self

      ATTRIBUTES = %i[
        signing_secret
        signature_expires_in
      ].freeze

      attr_accessor(*Config::ATTRIBUTES)

      def reset
        self.signing_secret = ENV['SLACK_SIGNING_SECRET']
        self.signature_expires_in = 5 * 60
      end
    end

    class << self
      def configure
        block_given? ? yield(Config) : Config
      end

      def config
        Config
      end
    end
  end
end

Slack::Events::Config.reset
