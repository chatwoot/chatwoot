# frozen_string_literal: true

module Crm
  module Zoho
    # Setup service for Zoho CRM integration
    #
    # Executes after hook creation to:
    # 1. Obtain initial access token using client_credentials grant
    # 2. Store token and api_domain in hook settings
    class SetupService
      def initialize(hook)
        @hook = hook
      end

      def setup
        Rails.logger.info "Starting Zoho CRM setup for hook ##{@hook.id}"

        # Obtain initial token
        refresher = TokenRefresher.new(@hook)
        new_credentials = refresher.refresh!

        # Update hook with credentials including token
        update_hook_credentials!(new_credentials)

        Rails.logger.info "Zoho CRM setup completed successfully for hook ##{@hook.id}"
        { success: true, message: 'Zoho CRM configured successfully' }
      rescue StandardError => e
        Rails.logger.error "Zoho CRM setup failed for hook ##{@hook.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        { success: false, error: e.message }
      end

      private

      def update_hook_credentials!(new_credentials)
        # Merge new credentials (access_token, api_domain, etc.) into existing settings
        @hook.settings ||= {}
        @hook.settings.merge!(new_credentials)

        # Calculate token expiration timestamp
        if new_credentials['expires_in'].present?
          expires_at = Time.current + new_credentials['expires_in'].to_i.seconds
          @hook.settings['token_expires_at'] = expires_at.iso8601
        end

        @hook.save(validate: false)

        Rails.logger.info "Token obtained and stored for Zoho hook ##{@hook.id}"
        Rails.logger.info "API Domain: #{@hook.settings['api_domain']}"
        Rails.logger.info "Token expires at: #{@hook.settings['token_expires_at']}"
      end
    end
  end
end
