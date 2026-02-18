# frozen_string_literal: true

module Crm
  module Zoho
    module Api
      # Client for Zoho CRM User operations
      # Used to sync internal agents with Zoho CRM users
      class UserClient < Crm::Zoho::BaseClient
        API_PATH = '/crm/v8'

        # Get all users from Zoho CRM
        #
        # @param type [String] User type filter: 'AllUsers', 'ActiveUsers', 'DeactivatedUsers', 'ConfirmedUsers'
        # @return [Hash] API response with users array
        def get_users(type: 'ActiveUsers')
          request(:get, "#{API_PATH}/users", query: { type: type })
        end

        # Search for a user by email
        # Zoho doesn't have a direct user search by email endpoint,
        # so we fetch all users and filter by email
        #
        # @param email [String] Email to search
        # @return [Hash, nil] User data or nil if not found
        def find_user_by_email(email)
          return nil if email.blank?

          response = get_users
          users = response.dig('users') || []

          users.find { |user| user['email']&.downcase == email.downcase }
        end

        # Get user by ID
        #
        # @param user_id [String] Zoho user ID
        # @return [Hash] User data
        def get_user(user_id)
          request(:get, "#{API_PATH}/users/#{user_id}")
        end
      end
    end
  end
end
