# frozen_string_literal: true

module Crm
  # Base service for syncing agents with CRM users
  # Each CRM provider should implement its own subclass
  class BaseAgentSyncService
    attr_reader :account, :hook

    def initialize(account)
      @account = account
      @hook = find_crm_hook
      @synced_count = 0
      @failed_count = 0
      @errors = []
    end

    # Main sync method - to be called by job or controller
    #
    # @return [Hash] Sync results with stats
    def sync
      return error_result('No active CRM integration found') unless @hook

      Rails.logger.info "Starting agent sync for account #{@account.id} with CRM #{@hook.app_id}"

      sync_agents

      success_result
    rescue StandardError => e
      Rails.logger.error "Agent sync failed for account #{@account.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      error_result(e.message)
    end

    # Sync a single agent with CRM
    # Must be implemented by subclasses
    # This method is public to allow direct calls from SyncAgentJob
    #
    # @param account_user [AccountUser] The account user to sync
    def sync_agent(account_user)
      raise NotImplementedError, 'Subclass must implement sync_agent method'
    end

    private

    # Find active CRM hook for the account
    def find_crm_hook
      @account.hooks.crm_hooks.enabled.first
    end

    # Sync all agents with CRM users
    # This method should be overridden by subclasses if needed
    def sync_agents
      agents = @account.account_users.includes(:user)

      agents.find_each do |account_user|
        sync_agent(account_user)
      end
    end

    # Update account_user with CRM data
    #
    # @param account_user [AccountUser] The account user to update
    # @param crm_user [Hash] CRM user data
    def update_account_user_from_crm(account_user, crm_user)
      return unless crm_user

      user = account_user.user

      # Update CRM external ID and role
      crm_id = extract_crm_user_id(crm_user)
      crm_role = extract_crm_role(crm_user)

      if crm_id.present?
        account_user.update_columns(
          crm_external_id: crm_id,
          crm_role: crm_role,
          crm_synced_at: Time.current
        )
      end

      # Update phone number if not present in Nauto Console
      crm_phone = extract_crm_phone(crm_user)
      if crm_phone.present? && user.phone_number.blank?
        user.update_column(:phone_number, crm_phone)
        Rails.logger.info "Updated phone for user #{user.email}: #{crm_phone}"
      end

      @synced_count += 1
      Rails.logger.info "Synced agent #{user.email} with CRM user #{crm_id} (role: #{crm_role})"
    rescue StandardError => e
      @failed_count += 1
      @errors << "Failed to sync #{user.email}: #{e.message}"
      Rails.logger.error "Failed to sync agent #{user.email}: #{e.message}"
    end

    # Extract CRM user ID from CRM response
    # Must be implemented by subclasses
    #
    # @param crm_user [Hash] CRM user data
    # @return [String] CRM user ID
    def extract_crm_user_id(crm_user)
      raise NotImplementedError, 'Subclass must implement extract_crm_user_id method'
    end

    # Extract phone number from CRM user data
    # Must be implemented by subclasses
    #
    # @param crm_user [Hash] CRM user data
    # @return [String, nil] Phone number
    def extract_crm_phone(crm_user)
      raise NotImplementedError, 'Subclass must implement extract_crm_phone method'
    end

    # Extract role from CRM user data
    # Must be implemented by subclasses
    #
    # @param crm_user [Hash] CRM user data
    # @return [String, nil] Role name
    def extract_crm_role(crm_user)
      raise NotImplementedError, 'Subclass must implement extract_crm_role method'
    end

    def success_result
      {
        success: true,
        synced_count: @synced_count,
        failed_count: @failed_count,
        errors: @errors
      }
    end

    def error_result(message)
      {
        success: false,
        error: message,
        synced_count: @synced_count,
        failed_count: @failed_count,
        errors: @errors
      }
    end
  end
end
