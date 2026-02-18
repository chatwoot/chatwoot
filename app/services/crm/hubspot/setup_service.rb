# frozen_string_literal: true

module Crm
  module Hubspot
    # Setup service for HubSpot CRM integration
    #
    # HubSpot Private App tokens are long-lived (no OAuth refresh).
    # Setup simply ensures token_type is set to Bearer.
    class SetupService
      def initialize(hook)
        @hook = hook
      end

      def setup
        Rails.logger.info "Starting HubSpot CRM setup for hook ##{@hook.id}"

        @hook.settings ||= {}
        @hook.settings['token_type'] = 'Bearer'
        @hook.save(validate: false)

        Rails.logger.info "HubSpot CRM setup completed for hook ##{@hook.id}"
        { success: true, message: 'HubSpot CRM configured successfully' }
      rescue StandardError => e
        Rails.logger.error "HubSpot CRM setup failed for hook ##{@hook.id}: #{e.message}"
        { success: false, error: e.message }
      end
    end
  end
end
