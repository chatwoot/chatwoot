# frozen_string_literal: true

module Crm
  # Job to sync agents with CRM users
  # Runs periodically for all accounts with active CRM integrations
  class AgentSyncJob < ApplicationJob
    queue_as :low

    # Sync agents for all accounts with active CRM integrations
    def perform
      Rails.logger.info 'Starting CRM agent sync job for all accounts'

      accounts_with_crm.find_each do |account|
        sync_account(account)
      end

      Rails.logger.info 'Completed CRM agent sync job'
    end

    private

    # Get all accounts with active CRM hooks
    def accounts_with_crm
      Account.joins(:hooks)
             .where(hooks: { app_id: crm_providers, status: 'enabled' })
             .distinct
    end

    # CRM providers that support agent sync
    def crm_providers
      %w[zoho] # Will add more: hubspot salesforce leadsquared kommo
    end

    # Sync agents for a specific account
    #
    # @param account [Account] Account to sync
    def sync_account(account)
      hook = account.hooks.crm_hooks.enabled.first
      return unless hook

      Rails.logger.info "Syncing agents for account #{account.id} with CRM #{hook.app_id}"

      service = sync_service_for(hook.app_id, account)
      result = service.sync

      log_sync_result(account, result)
    rescue StandardError => e
      Rails.logger.error "Failed to sync agents for account #{account.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end

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

    # Log sync results
    #
    # @param account [Account] Account that was synced
    # @param result [Hash] Sync result
    def log_sync_result(account, result)
      if result[:success]
        Rails.logger.info "Account #{account.id} sync completed: #{result[:synced_count]} synced, #{result[:failed_count]} failed"
      else
        Rails.logger.error "Account #{account.id} sync failed: #{result[:error]}"
      end

      # Log any errors
      result[:errors]&.each do |error|
        Rails.logger.warn "Account #{account.id} sync error: #{error}"
      end
    end
  end
end
