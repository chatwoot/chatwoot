# frozen_string_literal: true

module Crm
  module Zoho
    # Service to sync agents with Zoho CRM users
    class AgentSyncService < Crm::BaseAgentSyncService
      # Sync a single agent with Zoho CRM user
      #
      # @param account_user [AccountUser] The account user to sync
      def sync_agent(account_user)
        user = account_user.user
        return unless user.email.present?

        # Skip if already synced recently (within last hour)
        if account_user.crm_synced_at.present? && account_user.crm_synced_at > 1.hour.ago
          Rails.logger.info "Skipping recently synced agent: #{user.email}"
          return
        end

        # Search for user in Zoho by email
        crm_user = find_zoho_user(user.email)

        if crm_user
          update_account_user_from_crm(account_user, crm_user)
        else
          Rails.logger.info "No Zoho user found for agent: #{user.email}"
          # Still update synced_at to avoid repeated failed lookups
          account_user.update_column(:crm_synced_at, Time.current)
        end
      end

      private

      # Find Zoho user by email
      #
      # @param email [String] Email to search
      # @return [Hash, nil] Zoho user data or nil
      def find_zoho_user(email)
        client = Crm::Zoho::Api::UserClient.new(@hook)
        client.find_user_by_email(email)
      rescue StandardError => e
        Rails.logger.error "Error searching Zoho user #{email}: #{e.message}"
        nil
      end

      # Extract Zoho user ID from response
      #
      # @param crm_user [Hash] Zoho user data
      # @return [String] Zoho user ID
      def extract_crm_user_id(crm_user)
        crm_user['id']
      end

      # Extract phone number from Zoho user data
      # Zoho users can have 'phone' or 'mobile' fields
      #
      # @param crm_user [Hash] Zoho user data
      # @return [String, nil] Phone number in E.164 format if valid
      def extract_crm_phone(crm_user)
        phone = crm_user['phone'] || crm_user['mobile']
        return nil if phone.blank?

        # Normalize phone to E.164 format if it's not already
        normalize_phone(phone)
      end

      # Extract role from Zoho user data
      # Zoho users have a 'role' object with 'name' field
      #
      # @param crm_user [Hash] Zoho user data
      # @return [String, nil] Role name
      def extract_crm_role(crm_user)
        # Zoho role can be in different formats:
        # - crm_user['role']['name'] (role object)
        # - crm_user['role'] (string)
        role = crm_user['role']
        return nil if role.blank?

        role.is_a?(Hash) ? role['name'] : role.to_s
      end

      # Normalize phone number to E.164 format
      #
      # @param phone [String] Phone number
      # @return [String, nil] Normalized phone or nil if invalid
      def normalize_phone(phone)
        # Remove all non-digit characters
        digits = phone.gsub(/\D/, '')

        # If it doesn't start with +, assume it needs country code
        # This is a simple implementation - you might want to make this more sophisticated
        return "+#{digits}" if digits.length >= 10 && !phone.start_with?('+')

        # If it already has +, return as is
        return phone if phone.start_with?('+') && digits.length >= 10

        # Invalid phone
        nil
      end
    end
  end
end
