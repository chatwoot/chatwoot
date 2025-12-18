# frozen_string_literal: true

module Zerodb
  # Background job for provisioning AINative/ZeroDB projects for accounts
  # Enqueued when accounts are created or when AINative integration is enabled
  class ProjectProvisionJob < ApplicationJob
    queue_as :default
    retry_on Zerodb::ProjectProvisionService::ProvisionError, wait: :exponentially_longer, attempts: 5
    retry_on StandardError, wait: :exponentially_longer, attempts: 3

    # Provision an AINative project for an account
    # @param account_id [Integer] ID of the account to provision
    def perform(account_id)
      account = Account.find_by(id: account_id)

      unless account
        Rails.logger.warn("[Zerodb::ProjectProvision] Account #{account_id} not found")
        return
      end

      if account.ainative_configured?
        Rails.logger.info("[Zerodb::ProjectProvision] Account #{account_id} already has AINative project configured")
        return
      end

      provision_service = Zerodb::ProjectProvisionService.new(account)
      result = provision_service.provision!

      Rails.logger.info("[Zerodb::ProjectProvision] Successfully provisioned project #{result[:project_id]} for account #{account_id}")

      # Broadcast success to account users via ActionCable
      broadcast_provision_success(account, result)
    rescue Zerodb::ProjectProvisionService::ProjectLimitError => e
      Rails.logger.error("[Zerodb::ProjectProvision] Project limit reached for account #{account_id}: #{e.message}")
      # Don't retry if it's a limit error
      broadcast_provision_error(account, e.message)
    rescue Zerodb::ProjectProvisionService::AuthenticationError => e
      Rails.logger.error("[Zerodb::ProjectProvision] Authentication error for account #{account_id}: #{e.message}")
      # Don't retry if it's an auth error - needs configuration fix
      broadcast_provision_error(account, e.message)
    rescue Zerodb::ProjectProvisionService::ProvisionError => e
      Rails.logger.error("[Zerodb::ProjectProvision] Failed to provision project for account #{account_id}: #{e.message}")
      # Will retry based on retry_on configuration
      raise
    rescue StandardError => e
      Rails.logger.error("[Zerodb::ProjectProvision] Unexpected error provisioning project for account #{account_id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise
    end

    private

    def broadcast_provision_success(account, result)
      # Broadcast to account admins that project was provisioned
      account.administrators.each do |admin|
        Rails.configuration.dispatcher.dispatch(
          'ainative.project.provisioned',
          Time.zone.now,
          account: account,
          user: admin,
          project_id: result[:project_id]
        )
      end
    end

    def broadcast_provision_error(account, error_message)
      # Broadcast error to account admins
      account.administrators.each do |admin|
        Rails.configuration.dispatcher.dispatch(
          'ainative.project.provision_failed',
          Time.zone.now,
          account: account,
          user: admin,
          error: error_message
        )
      end
    end
  end
end
