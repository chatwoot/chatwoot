# frozen_string_literal: true

module Crm
  module Salesforce
    # Setup service for Salesforce CRM integration
    #
    # Executes after hook creation to:
    # 1. Obtain initial access token using password grant
    # 2. Store token and instance_url in hook settings
    class SetupService
      def initialize(hook)
        @hook = hook
      end

      def setup
        Rails.logger.info "Starting Salesforce CRM setup for hook ##{@hook.id}"

        # Obtain initial token
        refresher = TokenRefresher.new(@hook)
        new_credentials = refresher.refresh!

        # Update hook with credentials including token
        update_hook_credentials!(new_credentials)

        Rails.logger.info "Salesforce CRM setup completed successfully for hook ##{@hook.id}"
        { success: true, message: 'Salesforce CRM configured successfully' }
      rescue StandardError => e
        Rails.logger.error "Salesforce CRM setup failed for hook ##{@hook.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        { success: false, error: e.message }
      end

      private

      def update_hook_credentials!(new_credentials)
        # Merge new credentials (access_token, instance_url, etc.) into existing settings
        @hook.settings ||= {}
        @hook.settings.merge!(new_credentials)

        # Calculate token expiration timestamp
        if new_credentials['expires_in'].present?
          expires_at = Time.current + new_credentials['expires_in'].to_i.seconds
          @hook.settings['token_expires_at'] = expires_at.iso8601
        end

        @hook.save(validate: false)

        Rails.logger.info "Token obtained and stored for Salesforce hook ##{@hook.id}"
        Rails.logger.info "Instance URL: #{@hook.settings['instance_url']}"
        Rails.logger.info "Token expires at: #{@hook.settings['token_expires_at']}"
      end
    end
  end
end
