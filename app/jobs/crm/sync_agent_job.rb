# frozen_string_literal: true

module Crm
  # Job to sync a single agent with CRM
  # Triggered when an agent is created or their email is updated
  class SyncAgentJob < ApplicationJob
    queue_as :default

    # Sync a specific agent with CRM
    #
    # @param account_user_id [Integer] AccountUser ID to sync
    def perform(account_user_id)
      account_user = AccountUser.find_by(id: account_user_id)
      return unless account_user

      account = account_user.account
      hook = account.hooks.crm_hooks.enabled.first
      return unless hook

      Rails.logger.info "Syncing agent #{account_user.user.email} with CRM #{hook.app_id}"

      service = sync_service_for(hook.app_id, account)
      service.sync_agent(account_user)

      Rails.logger.info "Agent sync completed for #{account_user.user.email}"
    rescue StandardError => e
      Rails.logger.error "Failed to sync agent #{account_user_id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end

    private

    # Get appropriate sync service based on CRM provider
    #
    # @param app_id [String] CRM provider app_id
    # @param account [Account] Account to sync
    # @return [Crm::BaseAgentSyncService] Sync service instance
    def sync_service_for(app_id, account)
      case app_id
      when 'zoho'
        Crm::Zoho::AgentSyncService.new(account)
      # when 'hubspot'
      #   Crm::Hubspot::AgentSyncService.new(account)
      # when 'salesforce'
      #   Crm::Salesforce::AgentSyncService.new(account)
      else
        raise ArgumentError, "Unsupported CRM provider: #{app_id}"
      end
    end
  end
end
