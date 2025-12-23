# frozen_string_literal: true

class UniformNotifier
  class Slack < Base
    POSSIBLE_OPTIONS = %i[username channel].freeze

    class << self
      @slack = nil

      def active?
        @slack
      end

      def setup_connection(config = {})
        webhook_url, options = parse_config(config)
        fail_connection('webhook_url required for Slack notification') unless webhook_url

        require 'slack-notifier'
        @slack = ::Slack::Notifier.new webhook_url, options
      rescue LoadError
        fail_connection 'You must install the slack-notifier gem to use Slack notification: `gem install slack-notifier`'
      end

      protected

      def _out_of_channel_notify(data)
        message = data.values.compact.join("\n")
        notify(message)
      end

      private

      def fail_connection(message)
        @slack = nil
        raise NotificationError, message
      end

      def notify(message)
        @slack.ping message
      end

      def parse_config(config)
        options = config.select { |name, value| POSSIBLE_OPTIONS.include?(name) && !value.nil? }

        [config[:webhook_url], options]
      end
    end
  end
end
