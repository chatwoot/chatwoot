# frozen_string_literal: true
module Slack
  module Web
    class Client
      include Faraday::Connection
      include Faraday::Request
      include Api::Endpoints
      include Api::Helpers
      include Api::Options

      attr_accessor(*Config::ATTRIBUTES)

      def initialize(options = {})
        Slack::Web::Config::ATTRIBUTES.each do |key|
          send("#{key}=", options.fetch(key, Slack::Web.config.send(key)))
        end
        @logger ||= Slack::Config.logger || Slack::Logger.default
        @token ||= Slack.config.token
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
end
