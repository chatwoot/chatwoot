# frozen_string_literal: true
module Slack
  module Web
    module Config
      extend self

      ATTRIBUTES = %i[
        proxy
        user_agent
        ca_path
        ca_file
        logger
        endpoint
        token
        timeout
        open_timeout
        default_page_size
        conversations_id_page_size
        users_id_page_size
        default_max_retries
        adapter
      ].freeze

      attr_accessor(*Config::ATTRIBUTES)

      def reset
        self.endpoint = 'https://slack.com/api/'
        self.user_agent = "Slack Ruby Client/#{Slack::VERSION}"
        self.ca_path = nil
        self.ca_file = nil
        self.token = nil
        self.proxy = nil
        self.logger = nil
        self.timeout = nil
        self.open_timeout = nil
        self.default_page_size = 100
        self.conversations_id_page_size = nil
        self.users_id_page_size = nil
        self.default_max_retries = 100
        self.adapter = ::Faraday.default_adapter
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

Slack::Web::Config.reset
