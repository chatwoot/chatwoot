module Enterprise
  module Accounts
    class LimitsService
      include BillingHelper

      class << self
        def build(account)
          custom_class = custom_provider_class
          return custom_class.new(account) if custom_class.present?

          new(account)
        end

        private

        def custom_provider_class
          provider_name = ENV['SELF_HOSTED_LIMITS_PROVIDER']
          provider_name = Chatwoot.config[:self_hosted_limits_provider] if provider_name.blank?
          return if provider_name.blank?

          provider_name.safe_constantize
        rescue StandardError => e
          Rails.logger.error("Failed to load SELF_HOSTED_LIMITS_PROVIDER=#{provider_name}: #{e.message}")
          nil
        end
      end

      def initialize(account)
        @account = account
      end

      def limits
        return cloud_limits if ChatwootApp.chatwoot_cloud?

        self_hosted_limits
      end

      private

      attr_reader :account

      def cloud_limits
        if default_plan?(account)
          {
            'conversation' => {
              'allowed' => 500,
              'consumed' => conversations_this_month(account)
            },
            'non_web_inboxes' => {
              'allowed' => 0,
              'consumed' => non_web_inboxes(account)
            },
            'agents' => {
              'allowed' => 2,
              'consumed' => agents(account)
            }
          }
        else
          default_limits
        end
      end

      def self_hosted_limits
        usage_limits = account.usage_limits

        {
          'conversation' => {
            'allowed' => ChatwootApp.max_limit,
            'consumed' => conversations_this_month(account)
          },
          'non_web_inboxes' => {
            'allowed' => usage_limits[:inboxes],
            'consumed' => non_web_inboxes(account)
          },
          'agents' => {
            'allowed' => usage_limits[:agents],
            'consumed' => agents(account)
          },
          'captain' => usage_limits[:captain]
        }
      end

      def default_limits
        {
          'conversation' => {},
          'non_web_inboxes' => {},
          'agents' => {
            'allowed' => account.usage_limits[:agents],
            'consumed' => agents(account)
          },
          'captain' => account.usage_limits[:captain]
        }
      end
    end
  end
end

